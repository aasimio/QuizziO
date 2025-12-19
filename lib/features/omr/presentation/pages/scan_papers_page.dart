import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/camera_service.dart';
import '../../../../injection.dart';
import '../../../quiz/domain/entities/quiz.dart';
import '../../domain/entities/scan_result.dart';
import '../bloc/scanner_bloc.dart';
import '../bloc/scanner_event.dart';
import '../bloc/scanner_state.dart';
import '../widgets/alignment_overlay.dart';
import '../widgets/processing_overlay.dart';
import '../widgets/scan_bottom_bar.dart';
import '../widgets/scan_result_popup.dart';
import 'scan_result_detail_page.dart';

/// Arguments for ScanPapersPage navigation.
class ScanPapersArgs {
  final Quiz quiz;

  const ScanPapersArgs({required this.quiz});

  String get quizId => quiz.id;
  String get quizName => quiz.name;
}

/// Screen 5: Scan Papers Page
///
/// Camera-based OMR scanning interface that displays live camera preview
/// with alignment guides, processes answer sheets through the OMR pipeline,
/// and shows scan results.
class ScanPapersPage extends StatelessWidget {
  final ScanPapersArgs? args;

  const ScanPapersPage({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    if (args == null) {
      return _ErrorScaffold(message: 'Missing quiz arguments');
    }

    return BlocProvider<ScannerBloc>(
      create: (_) =>
          getIt<ScannerBloc>()..add(ScannerInitCamera(quiz: args!.quiz)),
      child: _ScanPapersContent(quiz: args!.quiz),
    );
  }
}

class _ScanPapersContent extends StatefulWidget {
  final Quiz quiz;

  const _ScanPapersContent({required this.quiz});

  @override
  State<_ScanPapersContent> createState() => _ScanPapersContentState();
}

class _ScanPapersContentState extends State<_ScanPapersContent>
    with WidgetsBindingObserver {
  bool _flashOn = false;
  int _scannedCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Camera cleanup handled by ScannerBloc on pause
    // Optionally handle resume if needed
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            'Scan Papers',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            BlocBuilder<ScannerBloc, ScannerState>(
              builder: (context, state) {
                // Only show flash toggle during preview/aligning
                if (state is ScannerPreviewing || state is ScannerAligning) {
                  return _FlashToggleButton(
                    isOn: _flashOn,
                    onToggle: _toggleFlash,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        extendBodyBehindAppBar: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Main content based on state
            BlocConsumer<ScannerBloc, ScannerState>(
              listener: _onStateChange,
              builder: (context, state) => _buildStateUI(state),
            ),
            // Bottom bar (visible during preview/aligning states)
            BlocBuilder<ScannerBloc, ScannerState>(
              builder: (context, state) {
                if (state is ScannerProcessing ||
                    state is ScannerError ||
                    state is ScannerResult ||
                    state is ScannerCapturing) {
                  return const SizedBox.shrink();
                }

                final markersDetected = switch (state) {
                  ScannerPreviewing(:final markersDetected) => markersDetected,
                  ScannerAligning(:final markersDetected) => markersDetected,
                  _ => 0,
                };

                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ScanBottomBar(
                    scannedCount: _scannedCount,
                    canCapture: markersDetected == 4,
                    onManualCapture: markersDetected == 4
                        ? () => _triggerManualCapture(context)
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateUI(ScannerState state) {
    return switch (state) {
      ScannerIdle() || ScannerInitializing() => _buildInitializingView(),
      ScannerPreviewing(:final markersDetected, :final avgConfidence) =>
        _buildPreviewingView(markersDetected, avgConfidence, false, 0),
      ScannerAligning(
        :final markersDetected,
        :final avgConfidence,
        :final stabilityMs
      ) =>
        _buildPreviewingView(markersDetected, avgConfidence, true, stabilityMs),
      ScannerCapturing() => _buildCapturingView(),
      ScannerProcessing(:final status) => _buildProcessingView(status),
      ScannerResult(:final scanResult, :final processingTimeMs) =>
        _buildResultView(scanResult, processingTimeMs),
      ScannerError(:final message, :final type) =>
        _buildErrorView(message, type),
    };
  }

  Widget _buildInitializingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Initializing camera...',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewingView(
    int markersDetected,
    double avgConfidence,
    bool isAligning,
    int stabilityMs,
  ) {
    final cameraService = getIt<CameraService>();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        if (cameraService.isInitialized && cameraService.controller != null)
          CameraPreview(cameraService.controller!)
        else
          Container(color: Colors.black),

        // Alignment overlay
        AlignmentOverlay(
          markersDetected: markersDetected,
          isAligning: isAligning,
          stabilityMs: stabilityMs,
        ),
      ],
    );
  }

  Widget _buildCapturingView() {
    final cameraService = getIt<CameraService>();

    return Stack(
      fit: StackFit.expand,
      children: [
        if (cameraService.controller != null)
          CameraPreview(cameraService.controller!),
        // White flash overlay
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 100),
          builder: (context, value, child) {
            return Container(
              color: Colors.white.withValues(alpha: value * 0.8),
            );
          },
          onEnd: () {
            HapticFeedback.mediumImpact();
          },
        ),
      ],
    );
  }

  Widget _buildProcessingView(String status) {
    final cameraService = getIt<CameraService>();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Dimmed camera preview
        if (cameraService.controller != null)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.3),
              BlendMode.darken,
            ),
            child: CameraPreview(cameraService.controller!),
          ),
        // Processing overlay
        ProcessingOverlay(status: status),
      ],
    );
  }

  Widget _buildResultView(ScanResult scanResult, int processingTimeMs) {
    final cameraService = getIt<CameraService>();

    return Stack(
      fit: StackFit.expand,
      children: [
        if (cameraService.controller != null)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.5),
              BlendMode.darken,
            ),
            child: CameraPreview(cameraService.controller!),
          ),
      ],
    );
  }

  Widget _buildErrorView(String message, ScannerErrorType type) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _getErrorTitle(type),
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  context
                      .read<ScannerBloc>()
                      .add(const ScannerRetryRequested());
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D7377),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getErrorTitle(ScannerErrorType type) {
    return switch (type) {
      ScannerErrorType.cameraInitialization => 'Camera Error',
      ScannerErrorType.markerDetection => 'Markers Not Found',
      ScannerErrorType.imageCapture => 'Capture Failed',
      ScannerErrorType.omrProcessing => 'Processing Error',
      ScannerErrorType.grading => 'Grading Error',
      ScannerErrorType.persistence => 'Save Error',
    };
  }

  void _onStateChange(BuildContext context, ScannerState state) {
    if (state is ScannerResult) {
      setState(() {
        _scannedCount++;
      });
      _showResultPopup(context, state);
    }
  }

  void _showResultPopup(BuildContext context, ScannerResult state) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScanResultPopup(
        scanResult: state.scanResult,
        processingTimeMs: state.processingTimeMs,
        onContinue: () {
          Navigator.pop(context);
          context.read<ScannerBloc>().add(const ScannerResultDismissed());
        },
        onViewDetails: () {
          Navigator.pop(context);
          Navigator.pushNamed(
            context,
            AppRoutes.scanResultDetail,
            arguments: ScanResultDetailArgs(
              scanResult: state.scanResult,
            ),
          );
        },
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final state = context.read<ScannerBloc>().state;

    if (state is ScannerProcessing) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Exit Scanner?', style: GoogleFonts.outfit()),
          content: Text(
            'Processing is still in progress. Are you sure you want to exit?',
            style: GoogleFonts.dmSans(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Exit'),
            ),
          ],
        ),
      );
      return result ?? false;
    }

    return true;
  }

  void _triggerManualCapture(BuildContext context) {
    context.read<ScannerBloc>().add(const ScannerStabilityAchieved());
  }

  Future<void> _toggleFlash() async {
    final cameraService = getIt<CameraService>();
    final newMode = _flashOn ? FlashMode.off : FlashMode.torch;

    try {
      await cameraService.controller?.setFlashMode(newMode);
      setState(() => _flashOn = !_flashOn);
    } catch (e) {
      debugPrint('Flash toggle error: $e');
    }
  }
}

class _FlashToggleButton extends StatelessWidget {
  final bool isOn;
  final VoidCallback onToggle;

  const _FlashToggleButton({
    required this.isOn,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(isOn ? Icons.flash_on : Icons.flash_off),
      tooltip: isOn ? 'Turn off flash' : 'Turn on flash',
      onPressed: onToggle,
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String message;

  const _ErrorScaffold({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text(message)),
    );
  }
}
