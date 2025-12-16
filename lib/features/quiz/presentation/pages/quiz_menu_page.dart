import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../omr/presentation/pages/scan_papers_page.dart';
import '../../../omr/presentation/pages/graded_papers_page.dart';
import 'edit_answer_key_page.dart';

class QuizMenuArgs {
  final String quizId;
  final String quizName;

  const QuizMenuArgs({
    required this.quizId,
    required this.quizName,
  });
}

class QuizMenuPage extends StatelessWidget {
  final QuizMenuArgs? args;

  const QuizMenuPage({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    final quizName = args?.quizName ?? 'Unknown Quiz';

    return Scaffold(
      appBar: AppBar(
        title: Text(quizName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MenuTile(
            icon: Icons.edit,
            title: 'Edit Answer Key',
            subtitle: 'Set correct answers for grading',
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.editAnswerKey,
                arguments: EditAnswerKeyArgs(
                  quizId: args?.quizId ?? '',
                  quizName: quizName,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.camera_alt,
            title: 'Scan Papers',
            subtitle: 'Scan and grade answer sheets',
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.scanPapers,
                arguments: ScanPapersArgs(
                  quizId: args?.quizId ?? '',
                  quizName: quizName,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.assignment,
            title: 'View Graded Papers',
            subtitle: 'See all scanned results',
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.gradedPapers,
                arguments: GradedPapersArgs(
                  quizId: args?.quizId ?? '',
                  quizName: quizName,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
