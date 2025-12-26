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

  /// Cached detection results to avoid duplicate detectMarkers() calls
  /// Optimization: 100-200ms savings per duplicate call
  Map<int, List<cv.Point2f>>? _lastDetectedMarkers;

  MarkerDetector();

  /// Initialize the ArUco detector with DICT_4X4_50 dictionary
  Future<void> initialize() async {
    _dictionary =
        cv.ArucoDictionary.predefined(cv.PredefinedDictionaryType.DICT_4X4_50);
    _params = cv.ArucoDetectorParameters.empty();
    _detector = cv.ArucoDetector.create(_dictionary!, _params!);
  }

  /// Legacy method for compatibility - now just calls initialize()
  Future<void> loadMarkerTemplate(dynamic bytes) async {
    await initialize();
  }

  /// Detect ArUco markers in the image
  /// Returns detection result with marker centers and confidence
  /// Caches detection results for use by getCornerPointsFromCachedDetection()
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

    // Cache detection results for getCornerPointsFromCachedDetection()
    _lastDetectedMarkers = detectedMarkers;

    // Build result with marker centers
    final markerCenters = <Point>[];
    final confidences = <double>[];

    for (final expectedId in ArucoMarkerIds.all) {
      if (detectedMarkers.containsKey(expectedId)) {
        // Calculate center from the 4 corner points
        final markerCorners = detectedMarkers[expectedId]!;
        final centerX =
            markerCorners.map((p) => p.x).reduce((a, b) => a + b) / 4;
        final centerY =
            markerCorners.map((p) => p.y).reduce((a, b) => a + b) / 4;
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

  /// Get corner points from cached detection results (no re-detection)
  /// Call detect() first, then use this method to get corner points
  /// Optimization: Saves 100-200ms by avoiding duplicate detectMarkers() call
  /// Returns null if cached detection has fewer than 4 markers
  List<Point>? getCornerPointsFromCachedDetection() {
    final detectedMarkers = _lastDetectedMarkers;
    if (detectedMarkers == null || detectedMarkers.length != 4) return null;

    return _extractCornerPoints(detectedMarkers);
  }

  /// Get the corner points for perspective transform (outer corners of markers)
  /// NOTE: This runs detection again - prefer getCornerPointsFromCachedDetection()
  /// after calling detect() to avoid duplicate detection overhead
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

    return _extractCornerPoints(detectedMarkers);
  }

  /// Extract corner points from detected markers map
  List<Point> _extractCornerPoints(Map<int, List<cv.Point2f>> detectedMarkers) {
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

  /// Clear cached detection results
  void clearCache() {
    _lastDetectedMarkers = null;
  }

  /// Clean up resources
  void dispose() {
    _detector?.dispose();
    _dictionary?.dispose();
    _params?.dispose();
    _detector = null;
    _dictionary = null;
    _params = null;
    _lastDetectedMarkers = null;
  }
}
