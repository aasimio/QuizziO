import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:uuid/uuid.dart';

import '../../../../core/services/camera_service.dart';
import '../../domain/entities/answer_status.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/scan_repository.dart';
import '../../models/detection_result.dart';
import '../../services/grading_service.dart';
import '../../services/image_preprocessor.dart';
import '../../services/marker_detector.dart';
import '../../services/omr_scanner_service.dart';
import '../../services/perspective_transformer.dart';
import '../../services/threshold_calculator.dart' as threshold_calculator;
import '../../../quiz/domain/entities/quiz.dart';
import '../../services/template_manager.dart';
import 'scanner_event.dart';
import 'scanner_state.dart';

@injectable
class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final CameraService _cameraService;
  final MarkerDetector _markerDetector;
  final ImagePreprocessor _preprocessor;
  final OmrPipeline _omrPipeline;
  final GradingService _gradingService;
  final ScanRepository _scanRepository;
  final TemplateManager _templateManager;
  final PerspectiveTransformer _perspectiveTransformer;
  final Uuid _uuid;

  // Internal state for frame processing
  StreamSubscription? _frameSubscription;
  bool _isProcessingFrame = false;
  Timer? _stabilityTimer;
  DateTime? _stabilityStartTime;
  Quiz? _currentQuiz;

  static const _stabilityDuration = Duration(milliseconds: 500);

  ScannerBloc(
    this._cameraService,
    this._markerDetector,
    this._preprocessor,
    this._omrPipeline,
    this._gradingService,
    this._scanRepository,
    this._templateManager,
    this._perspectiveTransformer,
    {Uuid? uuid}
  ) : _uuid = uuid ?? const Uuid(),
      super(const ScannerIdle()) {
    on<ScannerInitCamera>(_onInitCamera);
    on<ScannerMarkersUpdated>(_onMarkersUpdated);
    on<ScannerStabilityAchieved>(_onStabilityAchieved);
    on<ScannerStabilityLost>(_onStabilityLost);
    on<ScannerImageCaptured>(_onImageCaptured);
    on<ScannerProcessingUpdate>(_onProcessingUpdate);
    on<ScannerProcessingComplete>(_onProcessingComplete);
    on<ScannerResultDismissed>(_onResultDismissed);
    on<ScannerRetryRequested>(_onRetryRequested);
    on<ScannerErrorOccurred>(_onErrorOccurred);
  }

  /// Initialize camera and start streaming
  Future<void> _onInitCamera(
    ScannerInitCamera event,
    Emitter<ScannerState> emit,
  ) async {
    emit(const ScannerInitializing());

    try {
      // Store quiz context
      _currentQuiz = event.quiz;

      // Initialize camera
      await _cameraService.initialize();
      if (isClosed) return;

      // Initialize marker detector
      await _markerDetector.initialize();
      if (isClosed) return;

      // Load template for bubble positions
      final template = await _templateManager.getTemplate(event.quiz.templateId);
      if (isClosed) return;

      // Start camera image stream
      _cameraService.startImageStream();

      // Subscribe to frames with throttling
      _frameSubscription = _cameraService.imageStream
          .asyncMap((image) => _processFrame(image))
          .listen((_) {});

      emit(const ScannerPreviewing(
        markersDetected: 0,
        avgConfidence: 0.0,
      ));
    } catch (e) {
      if (isClosed) return;
      add(ScannerErrorOccurred(
        message: 'Failed to initialize camera: ${e.toString()}',
        type: ScannerErrorType.cameraInitialization,
      ));
    }
  }

  /// Process individual camera frames for marker detection
  Future<void> _processFrame(CameraImage image) async {
    // Skip if already processing (frame throttling)
    if (_isProcessingFrame) {
      return;
    }

    _isProcessingFrame = true;

    try {
      // Convert camera image to bytes
      final bytes = CameraService.convertCameraImageToBytes(image);

      // Determine format (BGRA on iOS, YUV420 on Android)
      final isBGRA = image.format.group == ImageFormatGroup.bgra8888;

      // Create Mat from pixels
      final mat = _preprocessor.createMatFromPixels(
        bytes,
        image.width,
        image.height,
        isBGRA,
      );

      if (mat.isEmpty) {
        return;
      }

      try {
        // Preprocess to grayscale
        final grayscale = await _preprocessor.preprocess(mat);

        try {
          // Detect markers
          final result = await _markerDetector.detect(grayscale);

          // Dispatch event (don't emit state directly)
          if (!isClosed) {
            add(ScannerMarkersUpdated(detectionResult: result));
          }
        } finally {
          grayscale.dispose();
        }
      } finally {
        mat.dispose();
      }
    } catch (e) {
      // Silent error - just continue processing next frame
      debugPrint('Frame processing error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  /// Handle marker detection updates from frame processing
  Future<void> _onMarkersUpdated(
    ScannerMarkersUpdated event,
    Emitter<ScannerState> emit,
  ) async {
    final result = event.detectionResult;

    if (state is ScannerPreviewing) {
      if (result.allMarkersFound) {
        // All markers detected - start stability timer
        _stabilityStartTime = DateTime.now();
        _stabilityTimer?.cancel();
        _stabilityTimer = Timer(_stabilityDuration, () {
          if (!isClosed) {
            add(const ScannerStabilityAchieved());
          }
        });

        emit(ScannerAligning(
          markersDetected: result.markersDetectedCount,
          avgConfidence: result.avgConfidence,
          stabilityMs: 0,
        ));
      } else {
        // Update preview with current marker count
        emit(ScannerPreviewing(
          markersDetected: result.markersDetectedCount,
          avgConfidence: result.avgConfidence,
        ));
      }
    } else if (state is ScannerAligning) {
      if (result.allMarkersFound) {
        // Update alignment state with elapsed stability time
        final elapsed = _stabilityStartTime != null
            ? DateTime.now().difference(_stabilityStartTime!).inMilliseconds
            : 0;

        emit(ScannerAligning(
          markersDetected: result.markersDetectedCount,
          avgConfidence: result.avgConfidence,
          stabilityMs: elapsed,
        ));
      } else {
        // Markers lost - dispatch stability lost event
        add(const ScannerStabilityLost());
      }
    }
  }

  /// Trigger high-res capture after markers stable for 500ms
  Future<void> _onStabilityAchieved(
    ScannerStabilityAchieved event,
    Emitter<ScannerState> emit,
  ) async {
    // Only process if in aligning state
    if (state is! ScannerAligning) {
      return;
    }

    try {
      // Stop image stream during capture
      await _cameraService.stopImageStream();
      if (isClosed) return;

      emit(const ScannerCapturing());

      // Capture high-res still image
      final imageBytes = await _cameraService.captureImage();
      if (isClosed) return;

      // Dispatch processing event
      add(ScannerImageCaptured(imageBytes: imageBytes));
    } catch (e) {
      if (isClosed) return;
      add(ScannerErrorOccurred(
        message: 'Failed to capture image: ${e.toString()}',
        type: ScannerErrorType.imageCapture,
      ));
    }
  }

  /// Return to previewing when markers become unstable
  Future<void> _onStabilityLost(
    ScannerStabilityLost event,
    Emitter<ScannerState> emit,
  ) async {
    _stabilityTimer?.cancel();
    _stabilityTimer = null;
    _stabilityStartTime = null;

    emit(const ScannerPreviewing(
      markersDetected: 0,
      avgConfidence: 0.0,
    ));
  }

  /// Process captured image through OMR pipeline
  Future<void> _onImageCaptured(
    ScannerImageCaptured event,
    Emitter<ScannerState> emit,
  ) async {
    if (_currentQuiz == null) {
      add(const ScannerErrorOccurred(
        message: 'Missing quiz context',
        type: ScannerErrorType.omrProcessing,
      ));
      return;
    }

    emit(const ScannerProcessing(status: 'Detecting markers...'));

    try {
      // Load template for bubble positions
      final template = await _templateManager.getTemplate(_currentQuiz!.templateId);
      if (isClosed) return;

      // Build bubble positions map from template
      final bubblePositions = _buildBubblePositions(template);

      // Run OMR pipeline
      final omrResult = await _omrPipeline.process(
        event.imageBytes,
        templateWidth: template.pageWidth,
        templateHeight: template.pageHeight,
        bubblePositions: bubblePositions,
      );
      if (isClosed) return;

      // Check if OMR succeeded
      if (!omrResult.success) {
        add(ScannerErrorOccurred(
          message: omrResult.errorMessage ?? 'OMR processing failed',
          type: omrResult.markerResult?.allMarkersFound == false
              ? ScannerErrorType.markerDetection
              : ScannerErrorType.omrProcessing,
        ));
        return;
      }

      emit(const ScannerProcessing(status: 'Grading answers...'));

      // Convert ExtractedAnswer to AnswerStatus
      final extractedAnswers = _convertToAnswerStatus(omrResult.answers!);

      // Grade answers
      final gradedResult = _gradingService.grade(
        extractedAnswers: extractedAnswers,
        answerKey: _currentQuiz!.answerKey,
      );
      if (isClosed) return;

      emit(const ScannerProcessing(status: 'Extracting name region...'));

      // Extract name region from captured image
      final nameRegionImage = await _extractNameRegion(
        event.imageBytes,
        template,
      );
      if (isClosed) return;

      // Build scan result
      final scanResult = ScanResult(
        id: _uuid.v4(),
        quizId: _currentQuiz!.id,
        scannedAt: DateTime.now(),
        nameRegionImage: nameRegionImage,
        detectedAnswers: extractedAnswers,
        score: gradedResult.score,
        total: gradedResult.total,
        percentage: gradedResult.percentage,
        scanConfidence: omrResult.markerResult!.avgConfidence,
        rawBubbleValues: null,
      );

      emit(const ScannerProcessing(status: 'Saving result...'));

      // Save to repository
      await _scanRepository.save(scanResult);
      if (isClosed) return;

      // Dispatch completion event
      add(ScannerProcessingComplete(
        scanResult: scanResult,
        processingTimeMs: omrResult.processingTimeMs,
      ));
    } catch (e, stackTrace) {
      debugPrint('Processing error: $e\n$stackTrace');
      if (isClosed) return;
      add(ScannerErrorOccurred(
        message: 'Failed to process scan: ${e.toString()}',
        type: ScannerErrorType.omrProcessing,
      ));
    }
  }

  /// Update processing status for UI feedback
  Future<void> _onProcessingUpdate(
    ScannerProcessingUpdate event,
    Emitter<ScannerState> emit,
  ) async {
    if (state is ScannerProcessing) {
      emit(ScannerProcessing(status: event.status));
    }
  }

  /// Display scan result
  Future<void> _onProcessingComplete(
    ScannerProcessingComplete event,
    Emitter<ScannerState> emit,
  ) async {
    emit(ScannerResult(
      scanResult: event.scanResult,
      processingTimeMs: event.processingTimeMs,
    ));
  }

  /// Return to preview after viewing result
  Future<void> _onResultDismissed(
    ScannerResultDismissed event,
    Emitter<ScannerState> emit,
  ) async {
    try {
      // Restart camera stream
      _cameraService.startImageStream();

      // Resume frame processing
      _frameSubscription = _cameraService.imageStream
          .asyncMap((image) => _processFrame(image))
          .listen((_) {});

      emit(const ScannerPreviewing(
        markersDetected: 0,
        avgConfidence: 0.0,
      ));
    } catch (e) {
      add(ScannerErrorOccurred(
        message: 'Failed to restart preview: ${e.toString()}',
        type: ScannerErrorType.cameraInitialization,
      ));
    }
  }

  /// Retry after error by re-initializing
  Future<void> _onRetryRequested(
    ScannerRetryRequested event,
    Emitter<ScannerState> emit,
  ) async {
    if (_currentQuiz == null) {
      emit(const ScannerError(
        message: 'Cannot retry: no quiz context',
        type: ScannerErrorType.cameraInitialization,
      ));
      return;
    }

    // Clean up
    await _cleanup();

    // Re-initialize
    add(ScannerInitCamera(quiz: _currentQuiz!));
  }

  /// Display error state
  Future<void> _onErrorOccurred(
    ScannerErrorOccurred event,
    Emitter<ScannerState> emit,
  ) async {
    // Clean up resources on error
    await _cleanup();

    emit(ScannerError(
      message: event.message,
      type: event.type,
    ));
  }

  /// Build bubble positions map from template field blocks
  Map<String, List<Rect>> _buildBubblePositions(
    dynamic template,
  ) {
    final positions = <String, List<Rect>>{};

    // Access template through dynamic to avoid circular imports
    final fieldBlocks = template.fieldBlocks as List;
    final bubbleWidth = template.bubbleWidth as int;
    final bubbleHeight = template.bubbleHeight as int;

    for (final blockDynamic in fieldBlocks) {
      final block = blockDynamic;
      final direction = block.direction as String;
      final originX = block.originX as int;
      final originY = block.originY as int;
      final bubblesGap = block.bubblesGap as int;
      final labelsGap = block.labelsGap as int;
      final options = block.options as List<String>;
      final questionLabels = block.questionLabels as List<String>;

      // Determine layout direction
      final isHorizontal = direction == 'horizontal';

      for (int qIdx = 0; qIdx < questionLabels.length; qIdx++) {
        final questionId = questionLabels[qIdx];
        final bubbleRects = <Rect>[];

        for (int optIdx = 0; optIdx < options.length; optIdx++) {
          final bubbleX = isHorizontal
              ? originX + (optIdx * (bubbleWidth + bubblesGap))
              : originX + (qIdx * (bubbleWidth + bubblesGap));

          final bubbleY = isHorizontal
              ? originY + (qIdx * (bubbleHeight + labelsGap))
              : originY + (optIdx * (bubbleHeight + labelsGap));

          bubbleRects.add(Rect.fromLTWH(
            bubbleX.toDouble(),
            bubbleY.toDouble(),
            bubbleWidth.toDouble(),
            bubbleHeight.toDouble(),
          ));
        }

        positions[questionId] = bubbleRects;
      }
    }

    return positions;
  }

  /// Convert ExtractedAnswer to AnswerStatus domain entity
  Map<String, AnswerStatus> _convertToAnswerStatus(
    Map<String, threshold_calculator.ExtractedAnswer> extracted,
  ) {
    return extracted.map((key, value) {
      switch (value.status) {
        case threshold_calculator.AnswerStatus.valid:
          return MapEntry(key, AnswerStatus.valid(value.value!));
        case threshold_calculator.AnswerStatus.blank:
          return MapEntry(key, const AnswerStatus.blank());
        case threshold_calculator.AnswerStatus.multipleMark:
          return MapEntry(key, const AnswerStatus.multipleMark());
      }
    });
  }

  /// Extract name region from captured image
  Future<Uint8List> _extractNameRegion(
    Uint8List imageBytes,
    dynamic template,
  ) async {
    // Decode image
    final mat = _preprocessor.decodeImage(imageBytes);

    try {
      // Preprocess to grayscale
      final processed = await _preprocessor.preprocess(mat);

      try {
        // Detect markers
        final markers = await _markerDetector.detect(processed);

        if (!markers.isValid) {
          throw Exception('Markers not found for name region extraction');
        }

        // Get corner points for transform
        final cornerPoints = await _markerDetector.getCornerPointsForTransform(processed);

        if (cornerPoints == null) {
          throw Exception('Could not extract corner points');
        }

        // Transform to aligned view
        final aligned = await _perspectiveTransformer.transform(
          processed,
          cornerPoints,
          template.pageWidth as int,
          template.pageHeight as int,
        );

        try {
          // Crop name region (coordinates are relative to aligned image)
          final nameRegion = aligned.region(cv.Rect(
            template.nameRegionX as int,
            template.nameRegionY as int,
            template.nameRegionWidth as int,
            template.nameRegionHeight as int,
          ));

          try {
            // Encode to PNG
            final (success, encoded) = cv.imencode('.png', nameRegion);
            if (!success || encoded.isEmpty) {
              throw Exception('Failed to encode name region');
            }
            return encoded;
          } finally {
            nameRegion.dispose();
          }
        } finally {
          aligned.dispose();
        }
      } finally {
        processed.dispose();
      }
    } finally {
      mat.dispose();
    }
  }

  /// Release all resources
  Future<void> _cleanup() async {
    _stabilityTimer?.cancel();
    _stabilityTimer = null;
    _stabilityStartTime = null;
    await _frameSubscription?.cancel();
    _frameSubscription = null;
    await _cameraService.stopImageStream();
  }

  /// Clean up when BLoC is disposed
  @override
  Future<void> close() async {
    await _cleanup();
    return super.close();
  }
}
