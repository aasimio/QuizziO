/// OMR (Optical Mark Recognition) configuration constants
///
/// This file contains all configuration values used by OMR services
/// for marker detection, threshold calculation, and bubble reading.
class OmrConstants {
  OmrConstants._(); // Private constructor to prevent instantiation

  // --- ArUco Marker Constants ---
  // ArUco markers use DICT_4X4_50 dictionary
  // Marker IDs: TL=0, TR=1, BR=2, BL=3

  /// Expected ArUco marker IDs for each corner
  static const int markerIdTopLeft = 0;
  static const int markerIdTopRight = 1;
  static const int markerIdBottomRight = 2;
  static const int markerIdBottomLeft = 3;

  /// Padding from the page edge to the outer edge of each marker (pixels @ 300 DPI)
  static const int markerPaddingPx = 90;

  /// Printed marker size (pixels @ 300 DPI)
  static const int markerSizePx = 180;

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
