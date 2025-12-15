import 'package:injectable/injectable.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import '../models/detection_result.dart';

/// ArUco marker IDs for each corner of the OMR sheet
class ArucoMarkerIds {
  static const int topLeft = 0;
  static const int topRight = 1;
  static const int bottomRight = 2;
  static const int bottomLeft = 3;
  
  static const List<int> all = [topLeft, topRight, bottomRight, bottomLeft];
}

@lazySingleton
class MarkerDetector {
  cv.ArucoDetector? _detector;
  cv.ArucoDictionary? _dictionary;
  cv.ArucoDetectorParameters? _params;

  MarkerDetector();

  /// Initialize the ArUco detector with DICT_4X4_50 dictionary
  Future<void> initialize() async {
    _dictionary = cv.ArucoDictionary.predefined(cv.PredefinedDictionaryType.DICT_4X4_50);
    _params = cv.ArucoDetectorParameters.empty();
    _detector = cv.ArucoDetector.create(_dictionary!, _params!);
  }

  /// Legacy method for compatibility - now just calls initialize()
  Future<void> loadMarkerTemplate(dynamic bytes) async {
    await initialize();
  }

  /// Detect ArUco markers in the image
  /// Returns detection result with marker centers and confidence
  Future<MarkerDetectionResult> detect(cv.Mat image) async {
    if (_detector == null) {
      await initialize();
    }

    // Detect markers
    final (corners, ids, _) = _detector!.detectMarkers(image);

    // Map detected markers to their positions
    final detectedMarkers = <int, List<cv.Point2f>>{};
    for (int i = 0; i < ids.length; i++) {
      final markerId = ids[i];
      if (ArucoMarkerIds.all.contains(markerId)) {
        detectedMarkers[markerId] = corners[i].toList();
      }
    }

    // Build result with marker centers
    final markerCenters = <Point>[];
    final confidences = <double>[];

    for (final expectedId in ArucoMarkerIds.all) {
      if (detectedMarkers.containsKey(expectedId)) {
        // Calculate center from the 4 corner points
        final markerCorners = detectedMarkers[expectedId]!;
        final centerX = markerCorners.map((p) => p.x).reduce((a, b) => a + b) / 4;
        final centerY = markerCorners.map((p) => p.y).reduce((a, b) => a + b) / 4;
        markerCenters.add(Point(centerX, centerY));
        confidences.add(1.0); // ArUco detection is binary - either found or not
      } else {
        // Marker not found - add placeholder
        markerCenters.add(const Point(0, 0));
        confidences.add(0.0);
      }
    }

    // Calculate average confidence (proportion of markers found)
    final avgConfidence = confidences.where((c) => c > 0).length / 4.0;

    // All markers found if we have all 4 expected IDs
    final allMarkersFound = detectedMarkers.length == 4 &&
        ArucoMarkerIds.all.every((id) => detectedMarkers.containsKey(id));

    return MarkerDetectionResult(
      markerCenters: markerCenters,
      avgConfidence: avgConfidence,
      perMarkerConfidence: confidences,
      allMarkersFound: allMarkersFound,
    );
  }

  /// Get the corner points for perspective transform (outer corners of markers)
  /// Returns null if not all markers are detected
  List<Point>? getCornerPointsForTransform(cv.Mat image) {
    if (_detector == null) return null;

    final (corners, ids, _) = _detector!.detectMarkers(image);

    // Map detected markers
    final detectedMarkers = <int, List<cv.Point2f>>{};
    for (int i = 0; i < ids.length; i++) {
      final markerId = ids[i];
      if (ArucoMarkerIds.all.contains(markerId)) {
        detectedMarkers[markerId] = corners[i].toList();
      }
    }

    // Need all 4 markers
    if (detectedMarkers.length != 4) return null;

    // Return the outer corners of each marker for perspective transform
    // TL marker: use top-left corner (index 0)
    // TR marker: use top-right corner (index 1)
    // BR marker: use bottom-right corner (index 2)
    // BL marker: use bottom-left corner (index 3)
    final tlCorner = detectedMarkers[ArucoMarkerIds.topLeft]![0];
    final trCorner = detectedMarkers[ArucoMarkerIds.topRight]![1];
    final brCorner = detectedMarkers[ArucoMarkerIds.bottomRight]![2];
    final blCorner = detectedMarkers[ArucoMarkerIds.bottomLeft]![3];

    return [
      Point(tlCorner.x, tlCorner.y),
      Point(trCorner.x, trCorner.y),
      Point(brCorner.x, brCorner.y),
      Point(blCorner.x, blCorner.y),
    ];
  }

  /// Clean up resources
  void dispose() {
    _detector?.dispose();
    _dictionary?.dispose();
    _params?.dispose();
    _detector = null;
    _dictionary = null;
    _params = null;
  }
}
