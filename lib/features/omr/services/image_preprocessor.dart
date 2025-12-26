import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

/// Service for preprocessing images before OMR analysis
/// Handles grayscale conversion, CLAHE enhancement, and normalization
@lazySingleton
class ImagePreprocessor {
  /// Cached CLAHE object - reused across calls (optimization: 30-50ms savings)
  cv.CLAHE? _clahe;

  /// Get or create cached CLAHE object
  cv.CLAHE get _cachedClahe =>
      _clahe ??= cv.createCLAHE(clipLimit: 2.0, tileGridSize: (8, 8));

  /// Converts image to grayscale, applies CLAHE, normalizes values
  /// Use for high-quality processing (captured images, bubble reading)
  Future<cv.Mat> preprocess(cv.Mat inputMat) async {
    cv.Mat? gray;
    cv.Mat? claheResult;

    try {
      // Step 1: Convert to grayscale
      gray = await _convertToGrayscale(inputMat);

      // Step 2: Apply CLAHE (Contrast Limited Adaptive Histogram Equalization)
      // Uses cached CLAHE object to avoid recreation overhead
      claheResult = await _cachedClahe.applyAsync(gray);
      gray.dispose(); // Dispose intermediate Mat
      gray = null;

      // Step 3: Normalize values to 0-255 range
      final normalized = cv.Mat.empty();
      await cv.normalizeAsync(
        claheResult,
        normalized,
        alpha: 0,
        beta: 255,
        normType: cv.NORM_MINMAX,
      );
      claheResult.dispose(); // Dispose intermediate Mat

      return normalized;
    } catch (e) {
      // Clean up any allocated Mats on error
      gray?.dispose();
      claheResult?.dispose();
      rethrow;
    }
  }

  /// Lightweight preprocessing for live camera preview frames
  /// Skips CLAHE and normalization - ArUco detection works on simple grayscale
  /// Optimization: 20-40ms savings per frame
  Future<cv.Mat> preprocessForPreview(cv.Mat inputMat) async {
    return _convertToGrayscale(inputMat);
  }

  /// Convert image to grayscale handling multiple input formats
  Future<cv.Mat> _convertToGrayscale(cv.Mat inputMat) async {
    // Handle both BGR (3 channels), BGRA (4 channels), and already grayscale (1 channel)
    final colorCode = inputMat.channels == 4
        ? cv.COLOR_BGRA2GRAY // iOS BGRA
        : inputMat.channels == 3
            ? cv.COLOR_BGR2GRAY // Encoded images
            : -1; // Already grayscale

    if (colorCode == -1) {
      // Already grayscale, clone it
      return inputMat.clone();
    } else {
      return await cv.cvtColorAsync(inputMat, colorCode);
    }
  }

  /// Dispose cached resources
  void dispose() {
    _clahe?.dispose();
    _clahe = null;
  }

  /// Decode encoded image bytes (JPEG/PNG) to Mat
  cv.Mat decodeImage(Uint8List bytes) {
    return cv.imdecode(bytes, cv.IMREAD_COLOR);
  }

  /// Create Mat from raw pixel data (for camera frames)
  ///
  /// iOS camera returns BGRA8888, Android returns grayscale Y plane
  cv.Mat createMatFromPixels(
      Uint8List bytes, int width, int height, bool isBGRA) {
    // Create empty Mat with correct dimensions and type
    final matType = isBGRA ? cv.MatType.CV_8UC4 : cv.MatType.CV_8UC1;
    final mat = cv.Mat.create(
      rows: height,
      cols: width,
      type: matType,
    );

    // Copy raw pixel data into the Mat
    final bytesPerPixel = isBGRA ? 4 : 1;
    final expectedLength = width * height * bytesPerPixel;
    if (bytes.length < expectedLength) {
      throw ArgumentError(
        'Pixel buffer too small: ${bytes.length} < $expectedLength',
      );
    }
    mat.data.setRange(0, expectedLength, bytes);

    return mat;
  }

  /// Converts Uint8List to cv.Mat (deprecated - use decodeImage or createMatFromPixels)
  @Deprecated('Use decodeImage or createMatFromPixels instead')
  cv.Mat uint8ListToMat(Uint8List bytes) {
    return cv.imdecode(bytes, cv.IMREAD_COLOR);
  }

  /// Converts cv.Mat back to Uint8List
  Uint8List matToUint8List(cv.Mat mat) {
    final (success, encoded) = cv.imencode('.png', mat);
    if (!success) {
      throw Exception('Failed to encode Mat to Uint8List');
    }
    return encoded;
  }
}
