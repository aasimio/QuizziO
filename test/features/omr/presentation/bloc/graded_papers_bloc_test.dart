import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizzio/features/omr/domain/entities/answer_status.dart';
import 'package:quizzio/features/omr/domain/entities/graded_result.dart';
import 'package:quizzio/features/omr/domain/entities/scan_result.dart';
import 'package:quizzio/features/omr/domain/repositories/scan_repository.dart';
import 'package:quizzio/features/omr/presentation/bloc/graded_papers_bloc.dart';
import 'package:quizzio/features/omr/presentation/bloc/graded_papers_event.dart';
import 'package:quizzio/features/omr/presentation/bloc/graded_papers_state.dart';
import 'package:quizzio/features/omr/services/grading_service.dart';
import 'package:quizzio/features/quiz/domain/entities/quiz.dart';
import 'package:quizzio/features/quiz/domain/repositories/quiz_repository.dart';

class MockScanRepository extends Mock implements ScanRepository {}

class MockQuizRepository extends Mock implements QuizRepository {}

class MockGradingService extends Mock implements GradingService {}

ScanResult _buildScanResult({
  String id = 'result-1',
  String quizId = 'quiz-1',
  DateTime? scannedAt,
}) {
  return ScanResult(
    id: id,
    quizId: quizId,
    scannedAt: scannedAt ?? DateTime(2024, 1, 1),
    nameRegionImage: Uint8List.fromList([1, 2, 3]),
    detectedAnswers: {
      'q1': AnswerStatus.valid('A'),
      'q2': const AnswerStatus.blank(),
      'q3': AnswerStatus.valid('C'),
      'q4': AnswerStatus.valid('D'),
    },
    correctedAnswers: const {},
    score: 3,
    total: 4,
    percentage: 75.0,
    wasEdited: false,
    scanConfidence: 1.0,
    rawBubbleValues: null,
  );
}

Quiz _buildQuiz({
  String id = 'quiz-1',
}) {
  return Quiz(
    id: id,
    name: 'Test Quiz',
    templateId: 'std_20q',
    createdAt: DateTime(2024, 1, 1),
    answerKey: const {
      'q1': 'A',
      'q2': 'B',
      'q3': 'C',
      'q4': 'D',
    },
  );
}

GradedResult _buildGradedResult() {
  return GradedResult(
    correctCount: 1,
    incorrectCount: 1,
    blankCount: 1,
    multipleMarkCount: 1,
    total: 4,
    questionResults: const {
      'q1': false,
      'q2': false,
      'q3': false,
      'q4': true,
    },
  );
}

void main() {
  group('GradedPapersBloc', () {
    late MockScanRepository scanRepository;
    late MockQuizRepository quizRepository;
    late MockGradingService gradingService;

    setUpAll(() {
      registerFallbackValue(_buildScanResult());
      registerFallbackValue(<String, AnswerStatus>{});
      registerFallbackValue(<String, String>{});
    });

    setUp(() {
      scanRepository = MockScanRepository();
      quizRepository = MockQuizRepository();
      gradingService = MockGradingService();
    });

    test('initial state is ResultsInitial', () {
      final bloc = GradedPapersBloc(
        scanRepository,
        quizRepository,
        gradingService,
      );
      expect(bloc.state, const ResultsInitial());
      bloc.close();
    });

    group('LoadResults', () {
      blocTest<GradedPapersBloc, GradedPapersState>(
        'emits [ResultsLoading, ResultsLoaded] with sorted results',
        setUp: () {
          final older =
              _buildScanResult(id: 'older', scannedAt: DateTime(2024, 1, 1));
          final newer =
              _buildScanResult(id: 'newer', scannedAt: DateTime(2024, 1, 3));
          when(() => scanRepository.getByQuizId('quiz-1'))
              .thenAnswer((_) async => [older, newer]);
        },
        build: () => GradedPapersBloc(
          scanRepository,
          quizRepository,
          gradingService,
        ),
        act: (bloc) => bloc.add(const LoadResults(quizId: 'quiz-1')),
        expect: () => [
          const ResultsLoading(),
          ResultsLoaded(
            quizId: 'quiz-1',
            results: [
              _buildScanResult(id: 'newer', scannedAt: DateTime(2024, 1, 3)),
              _buildScanResult(id: 'older', scannedAt: DateTime(2024, 1, 1)),
            ],
          ),
        ],
        verify: (_) {
          verify(() => scanRepository.getByQuizId('quiz-1')).called(1);
        },
      );

      blocTest<GradedPapersBloc, GradedPapersState>(
        'emits [ResultsLoading, ResultsError] on repository failure',
        setUp: () {
          when(() => scanRepository.getByQuizId('quiz-1'))
              .thenThrow(Exception('Load failed'));
        },
        build: () => GradedPapersBloc(
          scanRepository,
          quizRepository,
          gradingService,
        ),
        act: (bloc) => bloc.add(const LoadResults(quizId: 'quiz-1')),
        expect: () => [
          const ResultsLoading(),
          isA<ResultsError>().having(
            (state) => state.message,
            'message',
            contains('Failed to load results'),
          ),
        ],
      );
    });

    group('UpdateResult', () {
      blocTest<GradedPapersBloc, GradedPapersState>(
        'regrades and updates result using corrected answers',
        setUp: () {
          when(() => quizRepository.getById('quiz-1'))
              .thenAnswer((_) async => _buildQuiz());
          when(() => gradingService.grade(
                extractedAnswers: any(named: 'extractedAnswers'),
                answerKey: any(named: 'answerKey'),
              )).thenReturn(_buildGradedResult());
          when(() => scanRepository.update(any()))
              .thenAnswer((_) async {});
        },
        build: () => GradedPapersBloc(
          scanRepository,
          quizRepository,
          gradingService,
        ),
        seed: () => ResultsLoaded(
          quizId: 'quiz-1',
          results: [_buildScanResult()],
        ),
        act: (bloc) => bloc.add(UpdateResult(
          result: _buildScanResult(),
          correctedAnswers: const {
            'q1': 'B',
            'q2': null,
            'q3': 'MULTIPLE_MARK',
          },
        )),
        expect: () {
          final updated = _buildScanResult().copyWith(
            correctedAnswers: const {
              'q1': 'B',
              'q2': null,
              'q3': 'MULTIPLE_MARK',
            },
            wasEdited: true,
            score: 1,
            total: 4,
            percentage: 25.0,
          );
          return [
            const ResultsLoading(),
            ResultsLoaded(
              quizId: 'quiz-1',
              results: [updated],
            ),
          ];
        },
        verify: (_) {
          final captured = verify(() => gradingService.grade(
                extractedAnswers: captureAny(named: 'extractedAnswers'),
                answerKey: _buildQuiz().answerKey,
              )).captured;
          final extracted =
              captured.first as Map<String, AnswerStatus>;
          expect(extracted['q1'], AnswerStatus.valid('B'));
          expect(extracted['q2'], const AnswerStatus.blank());
          expect(extracted['q3'], const AnswerStatus.multipleMark());
          verify(() => scanRepository.update(any())).called(1);
        },
      );

      blocTest<GradedPapersBloc, GradedPapersState>(
        'emits error and restores previous state on update failure',
        setUp: () {
          when(() => quizRepository.getById('quiz-1'))
              .thenAnswer((_) async => _buildQuiz());
          when(() => gradingService.grade(
                extractedAnswers: any(named: 'extractedAnswers'),
                answerKey: any(named: 'answerKey'),
              )).thenReturn(_buildGradedResult());
          when(() => scanRepository.update(any()))
              .thenThrow(Exception('Update failed'));
        },
        build: () => GradedPapersBloc(
          scanRepository,
          quizRepository,
          gradingService,
        ),
        seed: () => ResultsLoaded(
          quizId: 'quiz-1',
          results: [_buildScanResult()],
        ),
        act: (bloc) => bloc.add(UpdateResult(
          result: _buildScanResult(),
          correctedAnswers: const {
            'q1': 'B',
          },
        )),
        expect: () => [
          const ResultsLoading(),
          isA<ResultsError>().having(
            (state) => state.message,
            'message',
            contains('Failed to update result'),
          ),
          ResultsLoaded(
            quizId: 'quiz-1',
            results: [_buildScanResult()],
          ),
        ],
      );
    });

    group('DeleteResult', () {
      blocTest<GradedPapersBloc, GradedPapersState>(
        'removes result from list on delete',
        setUp: () {
          when(() => scanRepository.delete('result-1'))
              .thenAnswer((_) async {});
        },
        build: () => GradedPapersBloc(
          scanRepository,
          quizRepository,
          gradingService,
        ),
        seed: () => ResultsLoaded(
          quizId: 'quiz-1',
          results: [
            _buildScanResult(id: 'result-1'),
            _buildScanResult(id: 'result-2'),
          ],
        ),
        act: (bloc) => bloc.add(const DeleteResult(resultId: 'result-1')),
        expect: () => [
          const ResultsLoading(),
          ResultsLoaded(
            quizId: 'quiz-1',
            results: [_buildScanResult(id: 'result-2')],
          ),
        ],
        verify: (_) {
          verify(() => scanRepository.delete('result-1')).called(1);
        },
      );

      blocTest<GradedPapersBloc, GradedPapersState>(
        'emits error and restores previous state on delete failure',
        setUp: () {
          when(() => scanRepository.delete('result-1'))
              .thenThrow(Exception('Delete failed'));
        },
        build: () => GradedPapersBloc(
          scanRepository,
          quizRepository,
          gradingService,
        ),
        seed: () => ResultsLoaded(
          quizId: 'quiz-1',
          results: [_buildScanResult(id: 'result-1')],
        ),
        act: (bloc) => bloc.add(const DeleteResult(resultId: 'result-1')),
        expect: () => [
          const ResultsLoading(),
          isA<ResultsError>().having(
            (state) => state.message,
            'message',
            contains('Failed to delete result'),
          ),
          ResultsLoaded(
            quizId: 'quiz-1',
            results: [_buildScanResult(id: 'result-1')],
          ),
        ],
      );
    });
  });
}
