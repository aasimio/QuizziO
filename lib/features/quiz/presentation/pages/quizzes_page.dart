import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../injection.dart';
import '../../domain/entities/quiz.dart';
import '../bloc/quiz_bloc.dart';
import '../bloc/quiz_event.dart';
import '../bloc/quiz_state.dart';
import '../widgets/quiz_card.dart';
import '../widgets/quiz_dialog.dart';
import 'quiz_menu_page.dart';

/// The main quizzes list page (Screen 1).
///
/// Displays all quizzes with options to create, edit, and delete.
class QuizzesPage extends StatelessWidget {
  const QuizzesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizBloc>(
      create: (_) => getIt<QuizBloc>()..add(const LoadQuizzes()),
      child: const _QuizzesPageContent(),
    );
  }
}

class _QuizzesPageContent extends StatelessWidget {
  const _QuizzesPageContent();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quizzes',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocBuilder<QuizBloc, QuizState>(
        builder: (context, state) {
          return switch (state) {
            QuizInitial() || QuizLoading() => const _LoadingView(),
            QuizLoaded(:final quizzes) => quizzes.isEmpty
                ? const _EmptyState()
                : _QuizList(quizzes: quizzes),
            QuizError(:final message) => _ErrorView(message: message),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: Text(
          'New Quiz',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final result = await QuizDialog.show(context);

    if (result != null && result is (String, String) && context.mounted) {
      final (name, templateId) = result;
      context.read<QuizBloc>().add(CreateQuiz(
            name: name,
            templateId: templateId,
          ));
    }
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
            'Loading quizzes...',
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
  const _EmptyState();

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
                Icons.quiz_outlined,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No quizzes yet',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to create your first quiz',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizList extends StatelessWidget {
  const _QuizList({required this.quizzes});

  final List<Quiz> quizzes;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        final quiz = quizzes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: QuizCard(
            quiz: quiz,
            templateName: _getTemplateDisplayName(quiz.templateId),
            onTap: () => _navigateToQuizMenu(context, quiz),
            onEdit: () => _showEditDialog(context, quiz),
            onDelete: () => _showDeleteConfirmation(context, quiz),
          ),
        );
      },
    );
  }

  void _navigateToQuizMenu(BuildContext context, Quiz quiz) {
    Navigator.pushNamed(
      context,
      AppRoutes.quizMenu,
      arguments: QuizMenuArgs(
        quizId: quiz.id,
        quizName: quiz.name,
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, Quiz quiz) async {
    final result = await QuizDialog.show(context, quiz: quiz);

    if (result != null && result is Quiz && context.mounted) {
      context.read<QuizBloc>().add(UpdateQuiz(quiz: result));
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, Quiz quiz) async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Quiz?',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${quiz.name}"? This will also delete all scanned results for this quiz. This action cannot be undone.',
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
      context.read<QuizBloc>().add(DeleteQuiz(id: quiz.id));
    }
  }

  String _getTemplateDisplayName(String templateId) {
    return switch (templateId) {
      'std_10q' => '10 Questions',
      'std_20q' => '20 Questions',
      'std_50q' => '50 Questions',
      _ => 'Unknown',
    };
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline,
                size: 32,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.outfit(
                fontSize: 18,
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
              onPressed: () {
                context.read<QuizBloc>().add(const LoadQuizzes());
              },
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
