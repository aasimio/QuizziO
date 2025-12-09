import 'dart:typed_data';
import 'dart:ui';
import 'package:injectable/injectable.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
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

  const OmrResult({
    required this.success,
    this.errorMessage,
    this.markerResult,
    this.answers,
    this.thresholdResult,
    required this.processingTimeMs,
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

  OmrPipeline(
    this._preprocessor,
    this._markerDetector,
    this._transformer,
    this._bubbleReader,
    this._thresholdCalculator,
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

    cv.Mat? mat;
    cv.Mat? processed;
    cv.Mat? aligned;

    try {
      // Step 1: Convert bytes to Mat
      mat = _preprocessor.uint8ListToMat(imageBytes);

      // Step 2: Preprocess image
      processed = await _preprocessor.preprocess(mat);
      mat.dispose(); // Dispose original, we only need processed version
      mat = null;

      // Step 3: Detect markers
      final markers = await _markerDetector.detect(processed);
      if (!markers.isValid) {
        processed.dispose();
        stopwatch.stop();
        return OmrResult(
          success: false,
          errorMessage:
              'Markers not detected. Found ${markers.markerCenters.length}/4 markers with avg confidence ${markers.avgConfidence.toStringAsFixed(2)}',
          markerResult: markers,
          processingTimeMs: stopwatch.elapsedMilliseconds,
        );
      }

      // Step 4: Transform perspective
      aligned = await _transformer.transform(
        processed,
        markers.markerCenters,
        templateWidth,
        templateHeight,
      );
      processed.dispose(); // Dispose processed, we only need aligned version
      processed = null;

      // Step 5: Read bubbles
      final bubbleResult = _bubbleReader.readAllBubbles(
        aligned,
        bubblePositions,
      );
      aligned.dispose(); // Dispose aligned, we're done with image processing
      aligned = null;

      // Step 6: Calculate threshold
      final thresholdResult = _thresholdCalculator.calculate(
        bubbleResult.allValues,
      );

      // Step 7: Extract answers
      final answers = _thresholdCalculator.extractAnswers(
        bubbleResult.bubbleValues,
        thresholdResult.threshold,
      );

      stopwatch.stop();
      return OmrResult(
        success: true,
        markerResult: markers,
        answers: answers,
        thresholdResult: thresholdResult,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e, stackTrace) {
      // Clean up any remaining Mats on error
      mat?.dispose();
      processed?.dispose();
      aligned?.dispose();

      // Log error details for debugging (not exposed to user)
      print('Pipeline error: $e');
      print('Stack trace: $stackTrace');

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
