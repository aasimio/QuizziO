import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/scan_result.dart';

/// A card widget displaying a graded paper result with score and actions.
///
/// Shows the name region image, score (fraction + percentage), scan date,
/// and provides menu actions for viewing details or deleting.
class GradedPaperCard extends StatelessWidget {
  const GradedPaperCard({
    super.key,
    required this.result,
    required this.onTap,
    required this.onDelete,
  });

  final ScanResult result;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  // Score color thresholds
  static const _greenThreshold = 80.0;
  static const _amberThreshold = 50.0;

  // Semantic colors for score display
  static const _greenSuccess = AppColors.success;
  static const _amberWarning = AppColors.warning;
  static const _redError = AppColors.errorAlt;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          child: Row(
            children: [
              // Name region image thumbnail
              _buildNameImage(colorScheme),
              const SizedBox(width: 16),

              // Score and metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Score row: fraction + percentage chip
                    _buildScoreRow(colorScheme),
                    const SizedBox(height: 6),

                    // Metadata row: date + edited badge
                    _buildMetadataRow(colorScheme),
                  ],
                ),
              ),

              // Overflow menu
              _buildPopupMenu(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameImage(ColorScheme colorScheme) {
    final hasImage = result.nameRegionImage.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: hasImage
            ? Image.memory(
                result.nameRegionImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(colorScheme),
              )
            : _buildPlaceholder(colorScheme),
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.person_outlined,
        color: colorScheme.onSurfaceVariant,
        size: 24,
      ),
    );
  }

  Widget _buildScoreRow(ColorScheme colorScheme) {
    final scoreColor = _getScoreColor(result.percentage);

    return Row(
      children: [
        // Score fraction
        Text(
          '${result.score}/${result.total}',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 10),

        // Percentage chip with color coding
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: scoreColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${result.percentage.toStringAsFixed(0)}%',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scoreColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(ColorScheme colorScheme) {
    return Row(
      children: [
        // Date with calendar icon
        Icon(
          Icons.calendar_today_outlined,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          _formatDate(result.scannedAt),
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        // Edited badge (if applicable)
        if (result.wasEdited) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: 11,
                  color: colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 3),
                Text(
                  'Edited',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPopupMenu(ColorScheme colorScheme) {
    return PopupMenuButton<_MenuAction>(
      icon: Icon(
        Icons.more_vert,
        color: colorScheme.onSurfaceVariant,
      ),
      tooltip: 'More options',
      onSelected: (action) {
        switch (action) {
          case _MenuAction.viewDetails:
            onTap();
          case _MenuAction.delete:
            onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<_MenuAction>(
          value: _MenuAction.viewDetails,
          child: Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 20,
                color: colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              Text(
                'View Details',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<_MenuAction>(
          value: _MenuAction.delete,
          child: Row(
            children: [
              Icon(
                Icons.delete_outlined,
                size: 20,
                color: colorScheme.error,
              ),
              const SizedBox(width: 12),
              Text(
                'Delete',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= _greenThreshold) {
      return _greenSuccess;
    } else if (percentage >= _amberThreshold) {
      return _amberWarning;
    } else {
      return _redError;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat.MMMd().format(date);
    }
  }
}

enum _MenuAction { viewDetails, delete }
