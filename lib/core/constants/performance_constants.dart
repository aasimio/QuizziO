/// Performance configuration constants aligned with PRD NFR-P requirements
///
/// This file contains all target metrics and thresholds for performance
/// profiling and validation. See PRD Section 6.1 for NFR definitions.
class PerformanceConstants {
  PerformanceConstants._(); // Private constructor to prevent instantiation

  // --- NFR-P-01: Scan Pipeline Targets (milliseconds) ---
  // Full scan pipeline must complete in under 500ms
  static const int pipelineTotalTarget = 500;
  static const int pipelineDecodeTarget = 50;
  static const int pipelinePreprocessTarget = 80;
  static const int pipelineDetectMarkersTarget = 60;
  static const int pipelineGetCornersTarget = 10;
  static const int pipelineTransformTarget = 50;
  static const int pipelineReadBubblesTarget = 100;
  static const int pipelineThresholdTarget = 20;
  static const int pipelineExtractTarget = 20;

  // --- NFR-P-02: Frame Processing Targets (milliseconds) ---
  // Preview marker detection must complete in under 100ms per frame
  static const int frameProcessingTarget = 100;
  static const int frameConversionTarget = 10;
  static const int frameMatCreationTarget = 10;
  static const int framePreprocessTarget = 40;
  static const int frameMarkerDetectionTarget = 50;

  // --- NFR-P-03: Cold Start Targets (milliseconds) ---
  // App cold start must complete in under 3 seconds
  static const int coldStartTotalTarget = 3000;
  static const int coldStartBindingTarget = 50;
  static const int coldStartDITarget = 100;
  static const int coldStartHiveInitTarget = 500;
  static const int coldStartBoxOpenTarget = 200;
  static const int coldStartCameraTarget = 1500;
  static const int coldStartMarkerDetectorTarget = 100;

  // --- NFR-P-04: Memory Targets (bytes) ---
  // Peak memory during scan must stay under 200MB
  static const int memoryPeakTargetBytes = 200 * 1024 * 1024; // 200MB

  // --- Profiling Configuration ---
  // Profile every Nth frame to minimize overhead
  static const int frameSampleInterval = 10;

  // Minimum samples required for P95 calculation
  static const int minSamplesForStats = 10;
}
