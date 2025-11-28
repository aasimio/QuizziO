import 'package:opencv_dart/opencv_dart.dart' as cv;

/// Always use this to safely dispose cv.Mat objects
void disposeMats(List<cv.Mat> mats) {
  for (final mat in mats) {
    mat.dispose();
  }
}
