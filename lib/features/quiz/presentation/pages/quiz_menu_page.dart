import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../injection.dart';
import '../../domain/entities/quiz.dart';
import '../bloc/quiz_bloc.dart';
import '../bloc/quiz_event.dart';
import '../bloc/quiz_state.dart';
import '../widgets/quiz_dialog.dart';
import '../../../omr/presentation/pages/scan_papers_page.dart';
import '../../../omr/presentation/pages/graded_papers_page.dart';
import 'edit_answer_key_page.dart';

/// Arguments for the Quiz Menu page.
class QuizMenuArgs {
  final Quiz quiz;

  const QuizMenuArgs({required this.quiz});
}

/// Screen 3: Quiz Menu Page
///
/// Displays menu options for a quiz: Edit Answer Key, Scan Papers, View Graded Papers.
/// Provides edit functionality via AppBar action.
class QuizMenuPage extends StatefulWidget {
  final QuizMenuArgs args;

  const QuizMenuPage({super.key, required this.args});

  @override
  State<QuizMenuPage> createState() => _QuizMenuPageState();
}

class _QuizMenuPageState extends State<QuizMenuPage> {
  late Quiz _currentQuiz;

  @override
  void initState() {
    super.initState();
    _currentQuiz = widget.args.quiz;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizBloc>(
      create: (_) => getIt<QuizBloc>(),
      child: _QuizMenuContent(
        quiz: _currentQuiz,
        onQuizUpdated: (updatedQuiz) {
          setState(() {
            _currentQuiz = updatedQuiz;
          });
        },
      ),
    );
  }
}

class _QuizMenuContent extends StatelessWidget {
  final Quiz quiz;
  final ValueChanged<Quiz> onQuizUpdated;

  const _QuizMenuContent({
    required this.quiz,
    required this.onQuizUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<QuizBloc, QuizState>(
      listener: (context, state) {
        if (state is QuizError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: GoogleFonts.dmSans(),
              ),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            quiz.name,
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
              icon: Icon(
                Icons.edit_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
              tooltip: 'Edit quiz',
              onPressed: () => _showEditDialog(context),
            ),
          ],
        ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          _MenuTile(
            icon: Icons.key_outlined,
            title: 'Edit Answer Key',
            subtitle: 'Set the correct answers for grading',
            iconColor: colorScheme.primary,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.editAnswerKey,
                arguments: EditAnswerKeyArgs(
                  quizId: quiz.id,
                  quizName: quiz.name,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.camera_alt_outlined,
            title: 'Scan Papers',
            subtitle: 'Scan and grade answer sheets instantly',
            iconColor: colorScheme.tertiary,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.scanPapers,
                arguments: ScanPapersArgs(
                  quizId: quiz.id,
                  quizName: quiz.name,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.assignment_outlined,
            title: 'View Graded Papers',
            subtitle: 'See all scanned results and scores',
            iconColor: colorScheme.secondary,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.gradedPapers,
                arguments: GradedPapersArgs(
                  quizId: quiz.id,
                  quizName: quiz.name,
                ),
              );
            },
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final result = await QuizDialog.show(context, quiz: quiz);

    if (result != null && result is Quiz && context.mounted) {
      final bloc = context.read<QuizBloc>();

      // Listen for bloc state changes to confirm success
      StreamSubscription<QuizState>? subscription;
      subscription = bloc.stream.listen((state) {
        if (!context.mounted) {
          subscription?.cancel();
          return;
        }

        if (state is QuizLoaded) {
          // Find the updated quiz in the list
          final updatedQuiz = state.quizzes.firstWhere(
            (q) => q.id == result.id,
            orElse: () => result,
          );

          // Update local state
          onQuizUpdated(updatedQuiz);

          // Show success confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Quiz updated',
                style: GoogleFonts.dmSans(),
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 2),
            ),
          );

          // Cancel subscription after handling
          subscription?.cancel();
        }
      });

      // Dispatch update event
      bloc.add(UpdateQuiz(quiz: result));
    }
  }
}

/// A polished menu tile widget for quiz actions.
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Trailing chevron
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
