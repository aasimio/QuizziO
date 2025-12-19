import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/scan_result.dart';
import '../utils/score_utils.dart';

/// Arguments for ScanResultDetailPage navigation.
///
/// Can be initialized with either a full ScanResult (from scanning flow)
/// or just IDs (from graded papers list) for lazy loading.
class ScanResultDetailArgs {
  final ScanResult? scanResult;
  final String? scanResultId;
  final String? quizId;

  const ScanResultDetailArgs({
    this.scanResult,
    this.scanResultId,
    this.quizId,
  }) : assert(
          scanResult != null || (scanResultId != null && quizId != null),
          'Either scanResult or both scanResultId and quizId must be provided',
        );

  String get id => scanResult?.id ?? scanResultId!;
}

/// Screen: Scan Result Detail Page
///
/// Displays detailed view of a single scan result including
/// name region, score breakdown, and question-by-question results.
/// Placeholder for Phase 5 full implementation.
class ScanResultDetailPage extends StatelessWidget {
  final ScanResultDetailArgs? args;

  const ScanResultDetailPage({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Missing scan result arguments')),
      );
    }

    final scanResult = args!.scanResult;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan Details',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share result',
            onPressed: () {
              // TODO: Implement share result in Phase 5
            },
          ),
        ],
      ),
      body: scanResult != null
          ? _ScanResultContent(scanResult: scanResult)
          : const Center(
              child: Text(
                'Loading scan result...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
    );
  }
}

class _ScanResultContent extends StatelessWidget {
  final ScanResult scanResult;

  const _ScanResultContent({required this.scanResult});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Score summary card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  '${scanResult.score}/${scanResult.total}',
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: getScoreColor(scanResult.percentage),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(scanResult.percentage * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatChip(
                      label: '${scanResult.blankCount} blank',
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      label: '${scanResult.multipleMarkCount} multiple',
                      color: Colors.red,
                    ),
                  ],
                ),
                if (scanResult.wasEdited) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Manually edited',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Placeholder for question breakdown (Phase 5)
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Question-by-question breakdown\nwill be implemented in Phase 5',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatChip({
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
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
