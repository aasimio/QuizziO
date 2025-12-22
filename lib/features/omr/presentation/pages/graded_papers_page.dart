import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../injection.dart';
import '../../../export/services/pdf_export_service.dart';
import '../../../quiz/domain/entities/quiz.dart';
import '../../domain/entities/scan_result.dart';
import '../bloc/graded_papers_bloc.dart';
import '../bloc/graded_papers_event.dart';
import '../bloc/graded_papers_state.dart';
import '../widgets/graded_paper_card.dart';
import 'scan_papers_page.dart';
import 'scan_result_detail_page.dart';

/// Arguments for GradedPapersPage navigation.
class GradedPapersArgs {
  final String quizId;
  final String quizName;
  final Quiz? quiz; // Optional full quiz for navigation back to scanning

  const GradedPapersArgs({
    required this.quizId,
    required this.quizName,
    this.quiz,
  });
}

/// Screen 6: Graded Papers Page
///
/// Displays a list of all scanned/graded papers for a quiz.
/// Provides options to view details, delete results, and export.
class GradedPapersPage extends StatelessWidget {
  final GradedPapersArgs? args;

  const GradedPapersPage({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    if (args == null) {
      return const _ErrorScaffold(
        message: 'Missing quiz arguments',
      );
    }

    return BlocProvider<GradedPapersBloc>(
      create: (_) =>
          getIt<GradedPapersBloc>()..add(LoadResults(quizId: args!.quizId)),
      child: _GradedPapersContent(
        quizId: args!.quizId,
        quizName: args!.quizName,
        quiz: args!.quiz,
      ),
    );
  }
}

class _GradedPapersContent extends StatefulWidget {
  final String quizId;
  final String quizName;
  final Quiz? quiz;

  const _GradedPapersContent({
    required this.quizId,
    required this.quizName,
    this.quiz,
  });

  @override
  State<_GradedPapersContent> createState() => _GradedPapersContentState();
}

class _GradedPapersContentState extends State<_GradedPapersContent> {
  String? _pendingDeleteId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.quizName,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          // Export results as PDF
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export results',
            onPressed: () => _handleExport(context),
          ),
        ],
      ),
      body: BlocConsumer<GradedPapersBloc, GradedPapersState>(
        listener: (context, state) {
          if (_pendingDeleteId == null) return;

          if (state is ResultsError) {
            _showDeleteFailed(context);
            setState(() {
              _pendingDeleteId = null;
            });
            return;
          }

          if (state is ResultsLoaded) {
            final deleted = !state.results.any(
              (result) => result.id == _pendingDeleteId,
            );
            if (deleted) {
              _showDeleteSuccess(context);
              setState(() {
                _pendingDeleteId = null;
              });
            }
          }
        },
        builder: (context, state) {
          return switch (state) {
            ResultsInitial() => const SizedBox.shrink(),
            ResultsLoading() => const _LoadingView(),
            ResultsLoaded(:final results) => results.isEmpty
                ? _EmptyState(quiz: widget.quiz)
                : _ResultsList(
                    results: results,
                    quizId: widget.quizId,
                    quiz: widget.quiz,
                    onDeleteConfirmed: (result) =>
                        _requestDelete(context, result),
                  ),
            ResultsError(:final message) => _ErrorView(
                message: message,
                onRetry: () {
                  context
                      .read<GradedPapersBloc>()
                      .add(LoadResults(quizId: widget.quizId));
                },
              ),
          };
        },
      ),
    );
  }

  Future<void> _handleExport(BuildContext context) async {
    // Get current state from BLoC
    final state = context.read<GradedPapersBloc>().state;

    // Validate prerequisites
    if (state is! ResultsLoaded || state.results.isEmpty) {
      _showSnackBar(context, 'No results to export');
      return;
    }

    if (widget.quiz == null) {
      _showSnackBar(context, 'Quiz data unavailable for export');
      return;
    }

    // Show loading dialog
    _showLoadingDialog(context);

    try {
      final pdfExportService = getIt<PdfExportService>();
      await pdfExportService.exportAndShare(widget.quiz!, state.results);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        // Share sheet will show automatically via share_plus
      }
    } on PdfExportException catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showSnackBar(context, 'Export failed: ${e.message}');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showSnackBar(context, 'Export failed. Please try again.');
      }
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(
              'Generating PDF...',
              style: GoogleFonts.dmSans(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.dmSans(),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _requestDelete(BuildContext context, ScanResult result) {
    setState(() {
      _pendingDeleteId = result.id;
    });
    context.read<GradedPapersBloc>().add(DeleteResult(resultId: result.id));
  }

  void _showDeleteSuccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Result deleted',
          style: GoogleFonts.dmSans(),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDeleteFailed(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to delete result',
          style: GoogleFonts.dmSans(),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading results...',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Quiz? quiz;

  const _EmptyState({this.quiz});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No graded papers yet',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scanned answer sheets will appear here',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (quiz != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _navigateToScan(context),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(
                  'Scan Papers',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D7377),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToScan(BuildContext context) {
    if (quiz == null) return;

    Navigator.pushNamed(
      context,
      AppRoutes.scanPapers,
      arguments: ScanPapersArgs(quiz: quiz!),
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<ScanResult> results;
  final String quizId;
  final Quiz? quiz;
  final void Function(ScanResult result) onDeleteConfirmed;

  const _ResultsList({
    required this.results,
    required this.quizId,
    this.quiz,
    required this.onDeleteConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return TweenAnimationBuilder<double>(
          key: ValueKey(result.id),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 300)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GradedPaperCard(
              result: result,
              onTap: () => _navigateToDetail(context, result),
              onDelete: () => _showDeleteConfirmation(context, result),
            ),
          ),
        );
      },
    );
  }

  Future<void> _navigateToDetail(BuildContext context, ScanResult result) async {
    final updatedResult = await Navigator.pushNamed(
      context,
      AppRoutes.scanResultDetail,
      arguments: ScanResultDetailArgs(
        scanResult: result,
        quiz: quiz,
      ),
    );

    // Handle returned updated result from detail page
    if (updatedResult is ScanResult && context.mounted) {
      context.read<GradedPapersBloc>().add(
            UpdateResult(
              result: updatedResult,
              correctedAnswers: updatedResult.correctedAnswers,
            ),
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Result updated',
            style: GoogleFonts.dmSans(),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    ScanResult result,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Result?',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this scan result? This action cannot be undone.',
          style: GoogleFonts.dmSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      onDeleteConfirmed(result);
    }
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load results',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: onRetry,
              child: Text(
                'Try Again',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String message;

  const _ErrorScaffold({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Error',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 40,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
