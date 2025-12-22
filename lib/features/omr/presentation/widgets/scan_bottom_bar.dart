import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';

/// Bottom bar for scan papers page showing scan count and capture button.
class ScanBottomBar extends StatelessWidget {
  /// Number of papers scanned in this session
  final int scannedCount;

  /// Whether the capture button should be enabled (all 4 markers detected)
  final bool canCapture;

  /// Callback when manual capture is triggered
  final VoidCallback? onManualCapture;

  const ScanBottomBar({
    super.key,
    required this.scannedCount,
    required this.canCapture,
    this.onManualCapture,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 80 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Scan count
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppColors.scanFeature,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Scanned: $scannedCount',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          // Capture button
          _CaptureButton(
            enabled: canCapture,
            onPressed: onManualCapture,
          ),
        ],
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onPressed;

  const _CaptureButton({
    required this.enabled,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.mediumImpact();
              onPressed?.call();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? AppColors.scanFeature : Colors.grey.shade400,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.scanFeature.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.camera_alt,
          color: enabled ? Colors.white : Colors.white70,
          size: 28,
        ),
      ),
    );
  }
}
