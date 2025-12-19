import 'package:equatable/equatable.dart';
import '../../domain/entities/scan_result.dart';

sealed class ScannerState extends Equatable {
  const ScannerState();

  @override
  List<Object?> get props => [];
}

/// Initial state before camera initialization
class ScannerIdle extends ScannerState {
  const ScannerIdle();
}

/// Camera and services are being initialized
class ScannerInitializing extends ScannerState {
  const ScannerInitializing();
}

/// Camera preview active, waiting for markers
class ScannerPreviewing extends ScannerState {
  /// Number of markers currently detected (0-4)
  final int markersDetected;

  /// Average marker detection confidence (0.0-1.0)
  final double avgConfidence;

  const ScannerPreviewing({
    required this.markersDetected,
    required this.avgConfidence,
  });

  @override
  List<Object?> get props => [markersDetected, avgConfidence];
}

/// All 4 markers detected and stable, ready to capture
class ScannerAligning extends ScannerState {
  /// Number of markers detected (should always be 4)
  final int markersDetected;

  /// Average marker detection confidence (should be 1.0 for ArUco)
  final double avgConfidence;

  /// Milliseconds markers have been stable
  final int stabilityMs;

  const ScannerAligning({
    required this.markersDetected,
    required this.avgConfidence,
    required this.stabilityMs,
  });

  @override
  List<Object?> get props => [markersDetected, avgConfidence, stabilityMs];
}

/// High-res capture in progress
class ScannerCapturing extends ScannerState {
  const ScannerCapturing();
}

/// OMR pipeline processing captured image
class ScannerProcessing extends ScannerState {
  /// Status message describing current processing stage
  final String status;

  const ScannerProcessing({required this.status});

  @override
  List<Object?> get props => [status];
}

/// Scan completed successfully
class ScannerResult extends ScannerState {
  /// The completed scan result
  final ScanResult scanResult;

  /// Time in milliseconds for the entire processing pipeline
  final int processingTimeMs;

  const ScannerResult({
    required this.scanResult,
    required this.processingTimeMs,
  });

  @override
  List<Object?> get props => [scanResult, processingTimeMs];
}

/// Error occurred at any stage
class ScannerError extends ScannerState {
  /// User-friendly error message
  final String message;

  /// Type of error that occurred
  final ScannerErrorType type;

  const ScannerError({
    required this.message,
    required this.type,
  });

  @override
  List<Object?> get props => [message, type];
}

/// Error types for the scanning process
enum ScannerErrorType {
  /// Camera failed to initialize
  cameraInitialization,

  /// Could not detect all 4 markers in captured image
  markerDetection,

  /// Failed to capture high-resolution image
  imageCapture,

  /// OMR pipeline processing failed
  omrProcessing,

  /// Grading service failed
  grading,

  /// Failed to save scan result to repository
  persistence,
}
