import 'package:injectable/injectable.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import '../models/detection_result.dart';

@lazySingleton
class PerspectiveTransformer {
  /// Transforms image using 4 source points to a rectangular output.
  ///
  /// **Resource Ownership & Disposal:**
  /// - The returned [cv.Mat] is **allocated by this method**
  /// - **Caller MUST call `.dispose()` on the returned Mat** when done to prevent memory leaks
  /// - Dispose as soon as the Mat is no longer needed (e.g., after saving or further processing)
  /// - Failure to dispose will cause native memory to accumulate and may lead to out-of-memory errors
  ///
  /// **Disposal Semantics:**
  /// ```dart
  /// final warped = await transformer.transform(mat, points, 800, 1100);
  /// try {
  ///   // Use the warped Mat...
  ///   await cv.imwriteAsync('output.png', warped);
  /// } finally {
  ///   warped.dispose(); // Always dispose, even if an error occurs
  /// }
  /// ```
  ///
  /// **Lifetime Expectations:**
  /// - The input [inputMat] is NOT modified and remains owned by the caller
  /// - Intermediate Mat objects (transform matrix) are disposed internally
  /// - Only the returned warped Mat requires caller disposal
  Future<cv.Mat> transform(
    cv.Mat inputMat,
    List<Point> sourcePoints, // 4 marker centers
    int outputWidth,
    int outputHeight,
  ) async {
    // Order source points
    final orderedPoints = _orderPoints(sourcePoints);

    // Define destination points (corners of output rectangle)
    final dst = [
      Point(0, 0), // TL
      Point(outputWidth - 1, 0), // TR
      Point(outputWidth - 1, outputHeight - 1), // BR
      Point(0, outputHeight - 1), // BL
    ];

    // Convert points to VecPoint for OpenCV
    final srcVec = _pointsToVecPoint(orderedPoints);
    final dstVec = _pointsToVecPoint(dst);

    // Get transform matrix
    final matrix = cv.getPerspectiveTransform(srcVec, dstVec);

    try {
      // Apply warp
      final warped = await cv.warpPerspectiveAsync(
        inputMat,
        matrix,
        (outputWidth, outputHeight),
      );
      return warped;
    } finally {
      // Dispose matrix
      matrix.dispose();
    }
  }

  /// Orders 4 points as: Top-Left, Top-Right, Bottom-Right, Bottom-Left
  List<Point> _orderPoints(List<Point> points) {
    if (points.length != 4) {
      throw ArgumentError('Expected exactly 4 points, got ${points.length}');
    }

    // Create a copy to avoid modifying the original list
    final pts = List<Point>.from(points);

    // Sort by sum (x+y): smallest = TL, largest = BR
    pts.sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
    final tl = pts[0]; // Smallest sum
    final br = pts[3]; // Largest sum

    // The remaining two points are TR and BL
    // Sort by diff (x-y): smallest = BL (negative), largest = TR (positive)
    final remaining = [pts[1], pts[2]];
    remaining.sort((a, b) => (a.x - a.y).compareTo(b.x - b.y));
    final bl = remaining[0]; // Smallest diff
    final tr = remaining[1]; // Largest diff

    return [tl, tr, br, bl];
  }

  /// Converts list of Point objects to VecPoint for OpenCV
  cv.VecPoint _pointsToVecPoint(List<Point> points) {
    return cv.VecPoint.fromList([
      for (final p in points) cv.Point(p.x.toInt(), p.y.toInt())
    ]);
  }
}
