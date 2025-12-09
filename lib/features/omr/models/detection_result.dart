class Point {
  final double x;
  final double y;

  const Point(this.x, this.y);

  @override
  String toString() => 'Point($x, $y)';
}

class MarkerDetectionResult {
  final List<Point> markerCenters; // 4 points: TL, TR, BR, BL
  final double avgConfidence;
  final List<double> perMarkerConfidence;
  final bool allMarkersFound;

  const MarkerDetectionResult({
    required this.markerCenters,
    required this.avgConfidence,
    required this.perMarkerConfidence,
    required this.allMarkersFound,
  });

  bool get isValid => allMarkersFound && avgConfidence >= 0.3;

  @override
  String toString() {
    return 'MarkerDetectionResult(\n'
        '  allMarkersFound: $allMarkersFound,\n'
        '  avgConfidence: ${avgConfidence.toStringAsFixed(2)},\n'
        '  markerCenters: $markerCenters,\n'
        '  perMarkerConfidence: ${perMarkerConfidence.map((c) => c.toStringAsFixed(2)).toList()}\n'
        ')';
  }
}
