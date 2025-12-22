import 'package:flutter/material.dart';

/// Application-wide constants for QuizziO
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'QuizziO';
  static const String appVersion = '1.0.0';
}

/// Semantic colors for consistent theming across the app.
///
/// These colors are used for the scan/OMR feature and status indicators.
class AppColors {
  AppColors._();

  /// Primary scan feature color (teal)
  static const Color scanFeature = Color(0xFF0D7377);

  /// Status colors
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFFF6B6B);
  static const Color errorAlt = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color detection = Color(0xFF4ECDC4);
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
