import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'features/quiz/presentation/pages/quizzes_page.dart';
import 'features/quiz/presentation/pages/quiz_menu_page.dart';
import 'features/quiz/presentation/pages/edit_answer_key_page.dart';
import 'features/omr/presentation/pages/scan_papers_page.dart';
import 'features/omr/presentation/pages/graded_papers_page.dart';
import 'features/omr/presentation/pages/scan_result_detail_page.dart';

class QuizziOApp extends StatelessWidget {
  const QuizziOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.quizzes,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.quizzes:
        return MaterialPageRoute(
          builder: (_) => const QuizzesPage(),
          settings: settings,
        );

      case AppRoutes.quizMenu:
        final args = settings.arguments as QuizMenuArgs?;
        return MaterialPageRoute(
          builder: (_) => QuizMenuPage(args: args),
          settings: settings,
        );

      case AppRoutes.editAnswerKey:
        final args = settings.arguments as EditAnswerKeyArgs?;
        return MaterialPageRoute(
          builder: (_) => EditAnswerKeyPage(args: args),
          settings: settings,
        );

      case AppRoutes.scanPapers:
        final args = settings.arguments as ScanPapersArgs?;
        return MaterialPageRoute(
          builder: (_) => ScanPapersPage(args: args),
          settings: settings,
        );

      case AppRoutes.gradedPapers:
        final args = settings.arguments as GradedPapersArgs?;
        return MaterialPageRoute(
          builder: (_) => GradedPapersPage(args: args),
          settings: settings,
        );

      case AppRoutes.scanResultDetail:
        final args = settings.arguments as ScanResultDetailArgs?;
        return MaterialPageRoute(
          builder: (_) => ScanResultDetailPage(args: args),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const QuizzesPage(),
          settings: settings,
        );
    }
  }
}
