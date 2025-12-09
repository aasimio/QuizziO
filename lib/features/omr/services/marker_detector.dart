import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import '../models/detection_result.dart';

@lazySingleton
class MarkerDetector {
  cv.Mat? _markerTemplate;
  final double minConfidence;
  final List<double> scales;

  MarkerDetector({
    this.minConfidence = 0.3,
    this.scales = const [0.85, 1.0, 1.15],
  });

  /// Load marker template from image bytes
  Future<void> loadMarkerTemplate(Uint8List bytes) async {
    // Decode bytes to cv.Mat
    final mat = cv.imdecode(bytes, cv.IMREAD_GRAYSCALE);

    // Store in _markerTemplate
    _markerTemplate = mat;
  }

  /// Returns ROI rect for each corner quadrant
  cv.Rect _getQuadrantRegion(cv.Mat image, String corner) {
    final w = image.width ~/ 2;
    final h = image.height ~/ 2;

    switch (corner) {
      case 'TL':
        return cv.Rect(0, 0, w, h);
      case 'TR':
        return cv.Rect(w, 0, w, h);
      case 'BR':
        return cv.Rect(w, h, w, h);
      case 'BL':
        return cv.Rect(0, h, w, h);
      default:
        throw ArgumentError('Invalid corner: $corner');
    }
  }

  /// Search for marker in a specific quadrant
  Future<({Point center, double confidence})> _searchInQuadrant(
    cv.Mat image,
    String corner,
  ) async {
    if (_markerTemplate == null) {
      throw StateError('Marker template not loaded. Call loadMarkerTemplate() first.');
    }

    // Get quadrant region
    final quadrantRect = _getQuadrantRegion(image, corner);

    // Extract ROI from image
    final roi = image.region(quadrantRect);

    try {
      double bestConfidence = 0.0;
      cv.Point bestLocation = cv.Point(0, 0);

      // Try different scales
      for (final scale in scales) {
        // Resize marker template
        final newWidth = (_markerTemplate!.width * scale).round();
        final newHeight = (_markerTemplate!.height * scale).round();

        final scaledTemplate = await cv.resizeAsync(
          _markerTemplate!,
          (newWidth, newHeight),
          interpolation: cv.INTER_LINEAR,
        );

        try {
          // Run template matching
          final result = await cv.matchTemplateAsync(
            roi,
            scaledTemplate,
            cv.TM_CCOEFF_NORMED,
          );

          try {
            // Get best match location and confidence
            final (minVal, maxVal, minLoc, maxLoc) = await cv.minMaxLocAsync(result);

            if (maxVal > bestConfidence) {
              bestConfidence = maxVal;
              // Center of matched region
              bestLocation = cv.Point(
                maxLoc.x + (scaledTemplate.width ~/ 2),
                maxLoc.y + (scaledTemplate.height ~/ 2),
              );
            }
          } finally {
            result.dispose();
          }
        } finally {
          scaledTemplate.dispose();
        }
      }

      // Translate local coordinates to full image coordinates (add quadrant offset)
      final globalX = quadrantRect.x + bestLocation.x;
      final globalY = quadrantRect.y + bestLocation.y;

      return (
        center: Point(globalX.toDouble(), globalY.toDouble()),
        confidence: bestConfidence,
      );
    } finally {
      roi.dispose();
    }
  }

  /// Detect all 4 corner markers
  Future<MarkerDetectionResult> detect(cv.Mat grayscaleImage) async {
    final corners = ['TL', 'TR', 'BR', 'BL'];
    final markerCenters = <Point>[];
    final confidences = <double>[];

    // Search for marker in each quadrant
    for (final corner in corners) {
      final result = await _searchInQuadrant(grayscaleImage, corner);
      markerCenters.add(result.center);
      confidences.add(result.confidence);
    }

    // Calculate average confidence
    final avgConfidence = confidences.reduce((a, b) => a + b) / confidences.length;

    // Check if all markers found (confidence above minimum)
    final allMarkersFound = confidences.every((c) => c >= minConfidence);

    return MarkerDetectionResult(
      markerCenters: markerCenters,
      avgConfidence: avgConfidence,
      perMarkerConfidence: confidences,
      allMarkersFound: allMarkersFound,
    );
  }

  /// Clean up marker template
  void dispose() {
    _markerTemplate?.dispose();
    _markerTemplate = null;
  }
}
