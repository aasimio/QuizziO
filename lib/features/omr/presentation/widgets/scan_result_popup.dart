import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/scan_result.dart';
import '../utils/score_utils.dart';

/// Modal bottom sheet popup showing scan result summary.
///
/// Displays score, percentage, and action buttons for continuing
/// or viewing details. This is a placeholder that will be expanded
/// in Task 4.4 with name region preview and more details.
class ScanResultPopup extends StatelessWidget {
  /// The completed scan result
  final ScanResult scanResult;

  /// Time in milliseconds for the entire processing pipeline
  final int processingTimeMs;

  /// Callback to dismiss popup and continue scanning
  final VoidCallback onContinue;

  /// Callback to navigate to detail page
  final VoidCallback onViewDetails;

  const ScanResultPopup({
    super.key,
    required this.scanResult,
    required this.processingTimeMs,
    required this.onContinue,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Success icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color:
                  getScoreColor(scanResult.percentage).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 36,
              color: getScoreColor(scanResult.percentage),
            ),
          ),
          const SizedBox(height: 16),

          // Name region image preview
          _NameRegionPreview(
            imageBytes: scanResult.nameRegionImage,
          ),
          const SizedBox(height: 16),

          // Score display
          Text(
            '${scanResult.score}/${scanResult.total}',
            style: GoogleFonts.outfit(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: getScoreColor(scanResult.percentage),
            ),
          ),
          Text(
            '${(scanResult.percentage * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.dmSans(
              fontSize: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          // Processing time
          Text(
            'Processed in ${(processingTimeMs / 1000).toStringAsFixed(1)}s',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          // Status summary row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (scanResult.blankCount == 0 &&
                  scanResult.multipleMarkCount == 0) ...[
                _StatusChip(
                  icon: Icons.check_circle_outline,
                  label: 'No issues detected',
                  color: Colors.green,
                ),
              ] else ...[
                if (scanResult.blankCount > 0) ...[
                  _StatusChip(
                    icon: Icons.remove_circle_outline,
                    label: '${scanResult.blankCount} blank',
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 12),
                ],
                if (scanResult.multipleMarkCount > 0) ...[
                  _StatusChip(
                    icon: Icons.warning_amber_outlined,
                    label: '${scanResult.multipleMarkCount} multiple',
                    color: Colors.red,
                  ),
                ],
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewDetails,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: colorScheme.outline),
                  ),
                  child: Text(
                    'View Details',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.scanFeature,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays the name region image from the scanned answer sheet.
/// Shows a placeholder if the image data is empty.
class _NameRegionPreview extends StatelessWidget {
  final Uint8List imageBytes;

  const _NameRegionPreview({
    required this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Show placeholder if image is empty
    if (imageBytes.isEmpty) {
      return Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Name region preview',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show actual image
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.memory(
        imageBytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
          );
        },
      ),
    );
  }
}
