import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'models/detection_result.dart';
import 'models/template_config.dart';
import 'services/image_preprocessor.dart';
import 'services/marker_detector.dart';
import 'services/perspective_transformer.dart';
import 'services/bubble_reader.dart';
import 'services/threshold_calculator.dart';

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
class OmrPipeline {
  final ImagePreprocessor _preprocessor;
  final MarkerDetector _markerDetector;
  final PerspectiveTransformer _transformer;
  final BubbleReader _bubbleReader;
  final ThresholdCalculator _thresholdCalculator;

  OmrPipeline({
    ImagePreprocessor? preprocessor,
    MarkerDetector? markerDetector,
    PerspectiveTransformer? transformer,
    BubbleReader? bubbleReader,
    ThresholdCalculator? thresholdCalculator,
  }) : _preprocessor = preprocessor ?? ImagePreprocessor(),
       _markerDetector = markerDetector ?? MarkerDetector(),
       _transformer = transformer ?? PerspectiveTransformer(),
       _bubbleReader = bubbleReader ?? BubbleReader(),
       _thresholdCalculator = thresholdCalculator ?? ThresholdCalculator();

  /// Process an answer sheet image through the complete OMR pipeline
  ///
  /// [imageBytes] - Image data (PNG, JPEG, etc.)
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
  Future<OmrResult> process(Uint8List imageBytes) async {
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
        kTemplateWidth,
        kTemplateHeight,
      );
      processed.dispose(); // Dispose processed, we only need aligned version
      processed = null;

      // Step 5: Read bubbles
      final bubbleResult = await _bubbleReader.readAllBubbles(
        aligned,
        kBubblePositions,
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

      // Log error details securely (not exposed to user)
      print('Pipeline error: $e');
      print('Stack trace: $stackTrace');

      stopwatch.stop();
      return OmrResult(
        success: false,
        errorMessage: 'Pipeline error: $e',
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
