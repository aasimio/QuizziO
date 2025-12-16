import 'package:equatable/equatable.dart';

class GradedResult extends Equatable {
  final int correctCount;
  final int incorrectCount;
  final int blankCount;
  final int multipleMarkCount;
  final int total;
  final Map<String, bool> questionResults;

  const GradedResult._({
    required this.correctCount,
    required this.incorrectCount,
    required this.blankCount,
    required this.multipleMarkCount,
    required this.total,
    required this.questionResults,
  });

  factory GradedResult({
    required int correctCount,
    required int incorrectCount,
    required int blankCount,
    required int multipleMarkCount,
    required int total,
    required Map<String, bool> questionResults,
  }) {
    // Validate non-negative counts
    if (correctCount < 0) {
      throw ArgumentError.value(
        correctCount,
        'correctCount',
        'Must be non-negative',
      );
    }
    if (incorrectCount < 0) {
      throw ArgumentError.value(
        incorrectCount,
        'incorrectCount',
        'Must be non-negative',
      );
    }
    if (blankCount < 0) {
      throw ArgumentError.value(
        blankCount,
        'blankCount',
        'Must be non-negative',
      );
    }
    if (multipleMarkCount < 0) {
      throw ArgumentError.value(
        multipleMarkCount,
        'multipleMarkCount',
        'Must be non-negative',
      );
    }
    if (total < 0) {
      throw ArgumentError.value(
        total,
        'total',
        'Must be non-negative',
      );
    }

    // Validate sum of counts equals total
    final sum = correctCount + incorrectCount + blankCount + multipleMarkCount;
    if (sum != total) {
      throw ArgumentError(
        'Sum of counts ($sum) does not equal total ($total). '
        'correctCount=$correctCount, incorrectCount=$incorrectCount, '
        'blankCount=$blankCount, multipleMarkCount=$multipleMarkCount',
      );
    }

    // Validate total matches questionResults length
    if (total != questionResults.length) {
      throw ArgumentError(
        'Total ($total) does not match questionResults length (${questionResults.length})',
      );
    }

    return GradedResult._(
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      blankCount: blankCount,
      multipleMarkCount: multipleMarkCount,
      total: total,
      questionResults: questionResults,
    );
  }

  int get score => correctCount;

  double get percentage => total > 0 ? (correctCount / total) * 100 : 0;

  bool isCorrect(String questionId) => questionResults[questionId] ?? false;

  @override
  List<Object?> get props => [
        correctCount,
        incorrectCount,
        blankCount,
        multipleMarkCount,
        total,
        questionResults,
      ];
}
