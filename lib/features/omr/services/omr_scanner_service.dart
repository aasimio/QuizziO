import 'dart:developer' as developer;
import 'dart:typed_data';
import 'dart:ui';
import 'package:injectable/injectable.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import '../../../core/constants/omr_constants.dart';
import '../../../core/services/performance_profiler.dart';
import '../models/detection_result.dart';
import 'image_preprocessor.dart';
import 'marker_detector.dart';
import 'perspective_transformer.dart';
import 'bubble_reader.dart';
import 'threshold_calculator.dart';

/// Result of the complete OMR pipeline processing
class OmrResult {
  final bool success;
  final String? errorMessage;
  final MarkerDetectionResult? markerResult;
  final Map<String, ExtractedAnswer>? answers;
  final ThresholdResult? thresholdResult;
  final int processingTimeMs;
  final Map<String, dynamic>? stepTimings;

  const OmrResult({
    required this.success,
    this.errorMessage,
    this.markerResult,
    this.answers,
    this.thresholdResult,
    required this.processingTimeMs,
    this.stepTimings,
  });

  @override
  String toString() {
    if (!success) {
      return 'OmrResult(success: false, error: $errorMessage, time: ${processingTimeMs}ms)';
    }
    return 'OmrResult(success: true, answers: $answers, threshold: $thresholdResult, time: ${processingTimeMs}ms)';
  }
}

/// Orchestrates all OMR services to process an answer sheet image end-to-end
@lazySingleton
class OmrPipeline {
  final ImagePreprocessor _preprocessor;
  final MarkerDetector _markerDetector;
  final PerspectiveTransformer _transformer;
  final BubbleReader _bubbleReader;
  final ThresholdCalculator _thresholdCalculator;
  final PerformanceProfiler _profiler;

  OmrPipeline(
    this._preprocessor,
    this._markerDetector,
    this._transformer,
    this._bubbleReader,
    this._thresholdCalculator,
    this._profiler,
  );

  /// Process an answer sheet image through the complete OMR pipeline
  ///
  /// [imageBytes] - Image data (PNG, JPEG, etc.)
  /// [templateWidth] - Width of template after perspective warp (pixels)
  /// [templateHeight] - Height of template after perspective warp (pixels)
  /// [bubblePositions] - Map of question IDs to bubble rectangles
  ///
  /// Returns [OmrResult] with success status, detected answers, and processing metrics
  ///
  /// Pipeline steps:
  /// 1. Preprocess: Convert to grayscale, apply CLAHE, normalize
  /// 2. Detect markers: Find 4 corner markers
  /// 3. Transform perspective: Warp to standard template size
  /// 4. Read bubbles: Extract intensity values from all bubble regions
  /// 5. Calculate threshold: Determine filled vs unfilled threshold
  /// 6. Extract answers: Identify which bubbles are filled for each question
  Future<OmrResult> process(
    Uint8List imageBytes, {
    required int templateWidth,
    required int templateHeight,
    required Map<String, List<Rect>> bubblePositions,
  }) async {
    final stopwatch = Stopwatch()..start();
    _profiler.startSession('omr_pipeline_${DateTime.now().millisecondsSinceEpoch}');
    _profiler.startTimer(MetricType.pipelineTotal);

    cv.Mat? mat;
    cv.Mat? processed;
    cv.Mat? aligned;

    try {
      // Step 1: Decode image bytes to Mat
      mat = _profiler.measure(MetricType.pipelineDecode, () {
        return _preprocessor.decodeImage(imageBytes);
      });

      // Step 2: Preprocess image (grayscale, CLAHE, normalize)
      processed = await _profiler.measureAsync(MetricType.pipelinePreprocess, () {
        return _preprocessor.preprocess(mat!);
      });
      mat?.dispose();
      mat = null;

      // Step 3: Detect ArUco markers
      final markers = await _profiler.measureAsync(MetricType.pipelineDetectMarkers, () {
        return _markerDetector.detect(processed!);
      });

      if (!markers.isValid) {
        processed?.dispose();
        _profiler.stopTimer(MetricType.pipelineTotal);
        final session = _profiler.endSession();
        stopwatch.stop();
        return OmrResult(
          success: false,
          errorMessage:
              'Markers not detected. Found ${markers.markerCenters.length}/4 markers with avg confidence ${markers.avgConfidence.toStringAsFixed(2)}',
          markerResult: markers,
          processingTimeMs: stopwatch.elapsedMilliseconds,
          stepTimings: session?.exportStepTimings(),
        );
      }

      // Step 4: Get corner points from cached detection (optimization: avoids duplicate detectMarkers call)
      final cornerPoints = _profiler.measure(MetricType.pipelineGetCorners, () {
        return _markerDetector.getCornerPointsFromCachedDetection();
      });

      if (cornerPoints == null) {
        processed?.dispose();
        _profiler.stopTimer(MetricType.pipelineTotal);
        final session = _profiler.endSession();
        stopwatch.stop();
        return OmrResult(
          success: false,
          errorMessage: 'Could not resolve marker corners for transform',
          markerResult: markers,
          processingTimeMs: stopwatch.elapsedMilliseconds,
          stepTimings: session?.exportStepTimings(),
        );
      }

      // Step 5: Perspective transform to aligned template
      aligned = await _profiler.measureAsync(MetricType.pipelineTransform, () {
        return _transformer.transform(
          processed!,
          cornerPoints,
          templateWidth,
          templateHeight,
          edgePaddingPx: OmrConstants.markerPaddingPx,
        );
      });
      processed?.dispose();
      processed = null;

      // Step 6: Read bubble intensity values
      final bubbleResult = _profiler.measure(MetricType.pipelineReadBubbles, () {
        return _bubbleReader.readAllBubbles(aligned!, bubblePositions);
      });
      aligned?.dispose();
      aligned = null;

      // Step 7: Calculate filled/unfilled threshold
      final thresholdResult = _profiler.measure(MetricType.pipelineThreshold, () {
        return _thresholdCalculator.calculate(bubbleResult.allValues);
      });

      // Step 8: Extract answers based on threshold
      final answers = _profiler.measure(MetricType.pipelineExtractAnswers, () {
        return _thresholdCalculator.extractAnswers(
          bubbleResult.bubbleValues,
          thresholdResult.threshold,
        );
      });

      final totalMs = _profiler.stopTimer(MetricType.pipelineTotal);
      final session = _profiler.endSession();
      stopwatch.stop();

      developer.log(
        'Pipeline completed in ${totalMs}ms',
        name: 'OmrPipeline',
      );

      return OmrResult(
        success: true,
        markerResult: markers,
        answers: answers,
        thresholdResult: thresholdResult,
        processingTimeMs: stopwatch.elapsedMilliseconds,
        stepTimings: session?.exportStepTimings(),
      );
    } catch (e, stackTrace) {
      // Clean up any remaining Mats on error
      mat?.dispose();
      processed?.dispose();
      aligned?.dispose();

      // Log error details for debugging (not exposed to user)
      developer.log(
        'Pipeline error',
        name: 'OmrScannerService',
        error: e,
        stackTrace: stackTrace,
      );

      _profiler.stopTimer(MetricType.pipelineTotal);
      _profiler.endSession();
      stopwatch.stop();
      return OmrResult(
        success: false,
        errorMessage: 'An error occurred while processing the image',
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Load marker template from image bytes
  ///
  /// This must be called before processing images
  Future<void> loadMarkerTemplate(Uint8List markerBytes) async {
    await _markerDetector.loadMarkerTemplate(markerBytes);
  }

  /// Clean up resources
  void dispose() {
    _markerDetector.dispose();
  }
}
