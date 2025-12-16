import 'package:flutter_test/flutter_test.dart';
import 'package:quizzio/features/omr/domain/entities/graded_result.dart';

void main() {
  group('GradedResult', () {
    group('validation', () {
      test('creates valid GradedResult when all invariants are satisfied', () {
        final result = GradedResult(
          correctCount: 7,
          incorrectCount: 2,
          blankCount: 1,
          multipleMarkCount: 0,
          total: 10,
          questionResults: {
            'Q1': true,
            'Q2': true,
            'Q3': false,
            'Q4': true,
            'Q5': true,
            'Q6': false,
            'Q7': true,
            'Q8': true,
            'Q9': true,
            'Q10': false,
          },
        );

        expect(result.correctCount, 7);
        expect(result.incorrectCount, 2);
        expect(result.blankCount, 1);
        expect(result.multipleMarkCount, 0);
        expect(result.total, 10);
        expect(result.questionResults.length, 10);
      });

      test('throws ArgumentError when correctCount is negative', () {
        expect(
          () => GradedResult(
            correctCount: -1,
            incorrectCount: 2,
            blankCount: 1,
            multipleMarkCount: 0,
            total: 2,
            questionResults: {'Q1': false, 'Q2': false},
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'message',
              contains('correctCount'),
            ),
          ),
        );
      });

      test('throws ArgumentError when incorrectCount is negative', () {
        expect(
          () => GradedResult(
            correctCount: 1,
            incorrectCount: -1,
            blankCount: 1,
            multipleMarkCount: 0,
            total: 1,
            questionResults: {'Q1': true},
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'message',
              contains('incorrectCount'),
            ),
          ),
        );
      });

      test('throws ArgumentError when blankCount is negative', () {
        expect(
          () => GradedResult(
            correctCount: 1,
            incorrectCount: 0,
            blankCount: -1,
            multipleMarkCount: 0,
            total: 1,
            questionResults: {'Q1': true},
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'message',
              contains('blankCount'),
            ),
          ),
        );
      });

      test('throws ArgumentError when multipleMarkCount is negative', () {
        expect(
          () => GradedResult(
            correctCount: 1,
            incorrectCount: 0,
            blankCount: 0,
            multipleMarkCount: -1,
            total: 1,
            questionResults: {'Q1': true},
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'message',
              contains('multipleMarkCount'),
            ),
          ),
        );
      });

      test('throws ArgumentError when total is negative', () {
        expect(
          () => GradedResult(
            correctCount: 0,
            incorrectCount: 0,
            blankCount: 0,
            multipleMarkCount: 0,
            total: -1,
            questionResults: {},
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'message',
              contains('total'),
            ),
          ),
        );
      });

      test('throws ArgumentError when sum of counts does not equal total', () {
        expect(
          () => GradedResult(
            correctCount: 5,
            incorrectCount: 3,
            blankCount: 1,
            multipleMarkCount: 1,
            total: 20, // Should be 10
            questionResults: List.generate(
              20,
              (i) => MapEntry('Q${i + 1}', i < 5),
            ).fold<Map<String, bool>>({}, (map, entry) {
              map[entry.key] = entry.value;
              return map;
            }),
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'message',
              allOf(
                contains('Sum of counts'),
                contains('does not equal total'),
                contains('correctCount=5'),
                contains('incorrectCount=3'),
              ),
            ),
          ),
        );
      });

      test(
          'throws ArgumentError when total does not match questionResults length',
          () {
        expect(
          () => GradedResult(
            correctCount: 5,
            incorrectCount: 3,
            blankCount: 1,
            multipleMarkCount: 1,
            total: 10,
            questionResults: {
              'Q1': true,
              'Q2': true,
              'Q3': true,
              'Q4': true,
              'Q5': true,
            }, // Only 5 questions, total says 10
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'message',
              allOf(
                contains('Total (10)'),
                contains('does not match questionResults length (5)'),
              ),
            ),
          ),
        );
      });
    });

    group('getters', () {
      test('score returns correctCount', () {
        final result = GradedResult(
          correctCount: 7,
          incorrectCount: 2,
          blankCount: 1,
          multipleMarkCount: 0,
          total: 10,
          questionResults: List.generate(
            10,
            (i) => MapEntry('Q${i + 1}', i < 7),
          ).fold<Map<String, bool>>({}, (map, entry) {
            map[entry.key] = entry.value;
            return map;
          }),
        );

        expect(result.score, 7);
      });

      test('percentage calculates correctly', () {
        final result = GradedResult(
          correctCount: 7,
          incorrectCount: 2,
          blankCount: 1,
          multipleMarkCount: 0,
          total: 10,
          questionResults: List.generate(
            10,
            (i) => MapEntry('Q${i + 1}', i < 7),
          ).fold<Map<String, bool>>({}, (map, entry) {
            map[entry.key] = entry.value;
            return map;
          }),
        );

        expect(result.percentage, 70.0);
      });

      test('percentage returns 0 when total is 0', () {
        final result = GradedResult(
          correctCount: 0,
          incorrectCount: 0,
          blankCount: 0,
          multipleMarkCount: 0,
          total: 0,
          questionResults: {},
        );

        expect(result.percentage, 0.0);
      });
    });

    group('isCorrect', () {
      late GradedResult result;

      setUp(() {
        result = GradedResult(
          correctCount: 2,
          incorrectCount: 1,
          blankCount: 0,
          multipleMarkCount: 0,
          total: 3,
          questionResults: {
            'Q1': true,
            'Q2': false,
            'Q3': true,
          },
        );
      });

      test('returns true for correct answer', () {
        expect(result.isCorrect('Q1'), true);
        expect(result.isCorrect('Q3'), true);
      });

      test('returns false for incorrect answer', () {
        expect(result.isCorrect('Q2'), false);
      });

      test('returns false for non-existent question', () {
        expect(result.isCorrect('Q999'), false);
      });
    });

    group('Equatable', () {
      test('two instances with same values are equal', () {
        final questionResults = List.generate(
          10,
          (i) => MapEntry('Q${i + 1}', i < 7),
        ).fold<Map<String, bool>>({}, (map, entry) {
          map[entry.key] = entry.value;
          return map;
        });

        final result1 = GradedResult(
          correctCount: 7,
          incorrectCount: 2,
          blankCount: 1,
          multipleMarkCount: 0,
          total: 10,
          questionResults: questionResults,
        );

        final result2 = GradedResult(
          correctCount: 7,
          incorrectCount: 2,
          blankCount: 1,
          multipleMarkCount: 0,
          total: 10,
          questionResults: questionResults,
        );

        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('two instances with different values are not equal', () {
        final result1 = GradedResult(
          correctCount: 7,
          incorrectCount: 2,
          blankCount: 1,
          multipleMarkCount: 0,
          total: 10,
          questionResults: List.generate(
            10,
            (i) => MapEntry('Q${i + 1}', i < 7),
          ).fold<Map<String, bool>>({}, (map, entry) {
            map[entry.key] = entry.value;
            return map;
          }),
        );

        final result2 = GradedResult(
          correctCount: 5,
          incorrectCount: 3,
          blankCount: 2,
          multipleMarkCount: 0,
          total: 10,
          questionResults: List.generate(
            10,
            (i) => MapEntry('Q${i + 1}', i < 5),
          ).fold<Map<String, bool>>({}, (map, entry) {
            map[entry.key] = entry.value;
            return map;
          }),
        );

        expect(result1, isNot(equals(result2)));
      });
    });
  });
}
