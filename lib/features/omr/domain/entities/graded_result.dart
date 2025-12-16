import 'package:equatable/equatable.dart';

class GradedResult extends Equatable {
  final int correctCount;
  final int incorrectCount;
  final int blankCount;
  final int multipleMarkCount;
  final int total;
  final Map<String, bool> questionResults;

  const GradedResult({
    required this.correctCount,
    required this.incorrectCount,
    required this.blankCount,
    required this.multipleMarkCount,
    required this.total,
    required this.questionResults,
  });

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
