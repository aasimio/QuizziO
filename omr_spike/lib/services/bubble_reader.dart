import 'dart:ui';
import 'package:opencv_dart/opencv_dart.dart' as cv;

/// Result of reading all bubbles from an aligned answer sheet
class BubbleReadResult {
  /// Bubble intensity values per question
  /// Format: {'q1': [45.2, 180.5, 175.3, 182.1, 179.8], ...}
  /// Lower values = darker (filled), higher values = lighter (unfilled)
  final Map<String, List<double>> bubbleValues;

  /// All bubble values flattened into a single list
  /// Used for threshold calculation
  final List<double> allValues;

  const BubbleReadResult({
    required this.bubbleValues,
    required this.allValues,
  });
}

/// Reads bubble intensity values from aligned answer sheet images
class BubbleReader {
  /// Reads all bubbles from the aligned image based on the provided positions
  ///
  /// [alignedImage] - Grayscale image after perspective transformation
  /// [bubblePositions] - Map of question IDs to list of bubble rectangles
  ///
  /// Returns [BubbleReadResult] with intensity values for each bubble
  ///
  /// Throws [ArgumentError] if inputs are invalid
  BubbleReadResult readAllBubbles(
    cv.Mat alignedImage,
    Map<String, List<Rect>> bubblePositions,
  ) {
    // Validate aligned image is not empty or disposed
    if (alignedImage.isEmpty) {
      throw ArgumentError('Aligned image cannot be empty or disposed');
    }

    // Validate bubble positions map is not empty
    if (bubblePositions.isEmpty) {
      throw ArgumentError('Bubble positions cannot be empty');
    }

    final bubbleValues = <String, List<double>>{};
    final allValues = <double>[];

    // Iterate through all questions and their bubble positions
    for (final entry in bubblePositions.entries) {
      final questionId = entry.key;
      final positions = entry.value;

      final questionValues = <double>[];

      // Read each bubble for this question
      for (final position in positions) {
        final intensity = _readSingleBubble(alignedImage, position);
        questionValues.add(intensity);
        allValues.add(intensity);
      }

      bubbleValues[questionId] = questionValues;
    }

    return BubbleReadResult(
      bubbleValues: bubbleValues,
      allValues: allValues,
    );
  }

  /// Reads the mean intensity value of a single bubble region
  ///
  /// [image] - Grayscale image to read from
  /// [position] - Rectangle defining the bubble location
  ///
  /// Returns mean intensity value (0-255)
  /// Lower values indicate darker (filled) bubbles
  /// Higher values indicate lighter (unfilled) bubbles
  ///
  /// Throws [ArgumentError] if inputs are invalid
  double _readSingleBubble(cv.Mat image, Rect position) {
    // Validate image is grayscale (single channel)
    if (image.channels != 1) {
      throw ArgumentError(
        'Image must be grayscale (single channel), got ${image.channels} channels',
      );
    }

    // Convert position values to integers
    final left = position.left.toInt();
    final top = position.top.toInt();
    final width = position.width.toInt();
    final height = position.height.toInt();

    // Validate position coordinates are non-negative
    if (left < 0 || top < 0) {
      throw ArgumentError(
        'Bubble position must have non-negative coordinates, got left=$left, top=$top',
      );
    }

    // Validate dimensions are positive
    if (width <= 0 || height <= 0) {
      throw ArgumentError(
        'Bubble dimensions must be positive, got width=$width, height=$height',
      );
    }

    // Validate rectangle lies entirely within image bounds
    if (left + width > image.cols || top + height > image.rows) {
      throw ArgumentError(
        'Bubble rectangle ($left, $top, $width, $height) exceeds image bounds (${image.cols}x${image.rows})',
      );
    }

    // Extract the region of interest (ROI) for this bubble
    // Only created after all validations pass
    cv.Mat? roi;
    try {
      roi = image.region(cv.Rect(left, top, width, height));

      // Calculate mean intensity of the bubble region
      final mean = cv.mean(roi);

      // For grayscale images, val1 contains the mean value (0-255)
      return mean.val1;
    } finally {
      // Always dispose of the ROI to prevent memory leaks
      // Guard disposal in case ROI was never created
      roi?.dispose();
    }
  }
}
