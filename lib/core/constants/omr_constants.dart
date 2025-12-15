/// OMR (Optical Mark Recognition) configuration constants
///
/// This file contains all configuration values used by OMR services
/// for marker detection, threshold calculation, and bubble reading.
class OmrConstants {
  OmrConstants._(); // Private constructor to prevent instantiation

  // --- Marker Detection Constants ---

  /// Minimum confidence threshold for marker template matching
  /// Range: 0.0 to 1.0, where 1.0 is a perfect match
  static const double markerMinConfidence = 0.3;

  /// Multi-scale factors for marker detection
  /// Allows detection of markers at different sizes/distances
  static const List<double> markerScales = [0.85, 1.0, 1.15];

  // --- Threshold Calculation Constants ---

  /// Minimum intensity jump required to identify a gap in histogram
  /// Used for automatic threshold calculation
  static const int thresholdMinJump = 20;

  /// Looseness factor for gap-finding algorithm
  /// Higher values make threshold detection more permissive
  static const int thresholdLooseness = 4;

  // --- Future OMR Constants ---
  // Add additional OMR configuration values here as needed:
  // - Bubble detection thresholds
  // - Image preprocessing parameters
  // - Perspective transform settings
}
