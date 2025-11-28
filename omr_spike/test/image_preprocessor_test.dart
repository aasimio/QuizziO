import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:omr_spike/services/image_preprocessor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImagePreprocessor', () {
    late ImagePreprocessor preprocessor;

    setUp(() {
      preprocessor = ImagePreprocessor();
    });

    test('should convert Uint8List to Mat and back', () async {
      // Load test image
      final imageData = await rootBundle.load('assets/test_sheet_filled.png');
      final bytes = imageData.buffer.asUint8List();

      // Convert to Mat
      final mat = preprocessor.uint8ListToMat(bytes);

      expect(mat.rows, greaterThan(0));
      expect(mat.cols, greaterThan(0));

      // Convert back to Uint8List
      final result = preprocessor.matToUint8List(mat);
      mat.dispose();

      expect(result.length, greaterThan(0));
    });

    test('should preprocess image successfully', () async {
      // Load test image
      final imageData = await rootBundle.load('assets/test_sheet_filled.png');
      final bytes = imageData.buffer.asUint8List();

      // Convert to Mat
      final mat = preprocessor.uint8ListToMat(bytes);

      // Preprocess
      final processed = await preprocessor.preprocess(mat);
      mat.dispose();

      // Verify output
      expect(processed.rows, greaterThan(0));
      expect(processed.cols, greaterThan(0));
      expect(processed.channels, equals(1)); // Should be grayscale

      processed.dispose();
    });

    test('should handle preprocessing with proper Mat disposal', () async {
      // Load test image
      final imageData = await rootBundle.load('assets/test_sheet_filled.png');
      final bytes = imageData.buffer.asUint8List();

      // Convert to Mat
      final mat = preprocessor.uint8ListToMat(bytes);
      final originalRows = mat.rows;
      final originalCols = mat.cols;

      // Preprocess
      final processed = await preprocessor.preprocess(mat);
      mat.dispose();

      // Verify dimensions are preserved
      expect(processed.rows, equals(originalRows));
      expect(processed.cols, equals(originalCols));

      // Convert to bytes to verify it's valid
      final processedBytes = preprocessor.matToUint8List(processed);
      expect(processedBytes.length, greaterThan(0));

      processed.dispose();
    });
  });
}
