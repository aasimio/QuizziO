import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

/// Service for preprocessing images before OMR analysis
/// Handles grayscale conversion, CLAHE enhancement, and normalization
@lazySingleton
class ImagePreprocessor {
  /// Converts image to grayscale, applies CLAHE, normalizes values
  Future<cv.Mat> preprocess(cv.Mat inputMat) async {
    cv.Mat? gray;
    cv.Mat? claheResult;

    try {
      // Step 1: Convert to grayscale
      // Handle both BGR (3 channels), BGRA (4 channels), and already grayscale (1 channel)
      final colorCode = inputMat.channels == 4
          ? cv.COLOR_BGRA2GRAY  // iOS BGRA
          : inputMat.channels == 3
              ? cv.COLOR_BGR2GRAY  // Encoded images
              : -1;  // Already grayscale

      if (colorCode == -1) {
        // Already grayscale, clone it
        gray = inputMat.clone();
      } else {
        gray = await cv.cvtColorAsync(inputMat, colorCode);
      }

      // Step 2: Apply CLAHE (Contrast Limited Adaptive Histogram Equalization)
      final clahe = cv.createCLAHE(clipLimit: 2.0, tileGridSize: (8, 8));
      claheResult = await clahe.applyAsync(gray);
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

  /// Decode encoded image bytes (JPEG/PNG) to Mat
  cv.Mat decodeImage(Uint8List bytes) {
    return cv.imdecode(bytes, cv.IMREAD_COLOR);
  }

  /// Create Mat from raw pixel data (for camera frames)
  ///
  /// iOS camera returns BGRA8888, Android returns grayscale Y plane
  cv.Mat createMatFromPixels(Uint8List bytes, int width, int height, bool isBGRA) {
    if (isBGRA) {
      // iOS BGRA8888: 4 bytes per pixel
      return cv.Mat.fromBytes(
        width: width,
        height: height,
        type: cv.MatType.CV_8UC4,  // 8-bit unsigned, 4 channels (BGRA)
        bytes: bytes,
      );
    } else {
      // Android grayscale (Y plane): 1 byte per pixel
      return cv.Mat.fromBytes(
        width: width,
        height: height,
        type: cv.MatType.CV_8UC1,  // 8-bit unsigned, 1 channel (grayscale)
        bytes: bytes,
      );
    }
  }

  /// Converts Uint8List to cv.Mat (deprecated - use decodeImage or createMatFromPixels)
  @deprecated
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
