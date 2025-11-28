import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;

/// Service for preprocessing images before OMR analysis
/// Handles grayscale conversion, CLAHE enhancement, and normalization
class ImagePreprocessor {
  /// Converts image to grayscale, applies CLAHE, normalizes values
  Future<cv.Mat> preprocess(cv.Mat inputMat) async {
    cv.Mat? gray;
    cv.Mat? claheResult;

    try {
      // Step 1: Convert to grayscale
      gray = await cv.cvtColorAsync(inputMat, cv.COLOR_BGR2GRAY);

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

  /// Converts Uint8List to cv.Mat
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
