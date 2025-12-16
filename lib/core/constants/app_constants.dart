/// Application-wide constants for QuizziO
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'QuizziO';
  static const String appVersion = '1.0.0';
}

/// Named route constants for navigation
class AppRoutes {
  AppRoutes._();

  /// Home screen - list of quizzes
  static const String quizzes = '/';

  /// Quiz menu - options for a specific quiz
  static const String quizMenu = '/quiz-menu';

  /// Edit answer key for a quiz
  static const String editAnswerKey = '/edit-answer-key';

  /// Camera scanning page
  static const String scanPapers = '/scan-papers';

  /// List of graded papers for a quiz
  static const String gradedPapers = '/graded-papers';

  /// Detail view of a single scan result
  static const String scanResultDetail = '/scan-result-detail';
}
