import 'package:equatable/equatable.dart';
import 'dart:typed_data';
import '../../../quiz/domain/entities/quiz.dart';
import '../../domain/entities/scan_result.dart';
import '../../models/detection_result.dart';
import 'scanner_state.dart';

sealed class ScannerEvent extends Equatable {
  const ScannerEvent();

  @override
  List<Object?> get props => [];
}

/// User initiated scan session
class ScannerInitCamera extends ScannerEvent {
  /// Quiz context with answer key and template ID
  final Quiz quiz;

  const ScannerInitCamera({required this.quiz});

  @override
  List<Object?> get props => [quiz];
}

/// Internal: Camera frame processed, markers detected/updated
class ScannerMarkersUpdated extends ScannerEvent {
  /// Result from ArUco marker detection
  final MarkerDetectionResult detectionResult;

  const ScannerMarkersUpdated({required this.detectionResult});

  @override
  List<Object?> get props => [detectionResult];
}

/// Internal: Stability timer elapsed, all markers stable for required duration
class ScannerStabilityAchieved extends ScannerEvent {
  const ScannerStabilityAchieved();
}

/// Internal: Marker stability lost (markers moved or disappeared)
class ScannerStabilityLost extends ScannerEvent {
  const ScannerStabilityLost();
}

/// Internal: High-res capture complete, start processing
class ScannerImageCaptured extends ScannerEvent {
  /// High-resolution image bytes captured from camera
  final Uint8List imageBytes;

  const ScannerImageCaptured({required this.imageBytes});

  @override
  List<Object?> get props => [imageBytes];
}

/// Internal: OMR processing stage update
class ScannerProcessingUpdate extends ScannerEvent {
  /// Status message describing current processing stage
  final String status;

  const ScannerProcessingUpdate({required this.status});

  @override
  List<Object?> get props => [status];
}

/// Internal: Processing complete with result
class ScannerProcessingComplete extends ScannerEvent {
  /// The completed scan result
  final ScanResult scanResult;

  /// Time in milliseconds for the entire processing pipeline
  final int processingTimeMs;

  const ScannerProcessingComplete({
    required this.scanResult,
    required this.processingTimeMs,
  });

  @override
  List<Object?> get props => [scanResult, processingTimeMs];
}

/// User dismissed result, return to preview
class ScannerResultDismissed extends ScannerEvent {
  const ScannerResultDismissed();
}

/// User requested retry after error
class ScannerRetryRequested extends ScannerEvent {
  const ScannerRetryRequested();
}

/// Internal: Error occurred
class ScannerErrorOccurred extends ScannerEvent {
  /// User-friendly error message
  final String message;

  /// Type of error that occurred
  final ScannerErrorType type;

  const ScannerErrorOccurred({
    required this.message,
    required this.type,
  });

  @override
  List<Object?> get props => [message, type];
}
