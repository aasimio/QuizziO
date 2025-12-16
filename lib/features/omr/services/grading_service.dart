import 'package:injectable/injectable.dart';

import '../domain/entities/answer_status.dart';
import '../domain/entities/graded_result.dart';

@lazySingleton
class GradingService {
  GradedResult grade({
    required Map<String, AnswerStatus> extractedAnswers,
    required Map<String, String> answerKey,
  }) {
    int correctCount = 0;
    int incorrectCount = 0;
    int blankCount = 0;
    int multipleMarkCount = 0;
    final questionResults = <String, bool>{};

    for (final entry in answerKey.entries) {
      final questionId = entry.key;
      final correctAnswer = entry.value;
      final extracted = extractedAnswers[questionId];

      if (extracted == null) {
        // No answer extracted for this question - treat as blank
        blankCount++;
        questionResults[questionId] = false;
        continue;
      }

      switch (extracted.type) {
        case AnswerType.valid:
          if (extracted.value == correctAnswer) {
            correctCount++;
            questionResults[questionId] = true;
          } else {
            incorrectCount++;
            questionResults[questionId] = false;
          }
        case AnswerType.blank:
          blankCount++;
          questionResults[questionId] = false;
        case AnswerType.multipleMark:
          multipleMarkCount++;
          questionResults[questionId] = false;
        case AnswerType.inconsistent:
          // Data inconsistency - treat as incorrect
          incorrectCount++;
          questionResults[questionId] = false;
      }
    }

    return GradedResult(
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      blankCount: blankCount,
      multipleMarkCount: multipleMarkCount,
      total: answerKey.length,
      questionResults: questionResults,
    );
  }
}
