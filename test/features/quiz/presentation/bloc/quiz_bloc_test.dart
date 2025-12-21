import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quizzio/features/omr/domain/repositories/scan_repository.dart';
import 'package:quizzio/features/quiz/domain/entities/quiz.dart';
import 'package:quizzio/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:quizzio/features/quiz/presentation/bloc/quiz_bloc.dart';
import 'package:quizzio/features/quiz/presentation/bloc/quiz_event.dart';
import 'package:quizzio/features/quiz/presentation/bloc/quiz_state.dart';
import 'package:uuid/uuid.dart';

class MockQuizRepository extends Mock implements QuizRepository {}

class MockScanRepository extends Mock implements ScanRepository {}

class MockUuid extends Mock implements Uuid {}

void main() {
  late QuizRepository repository;
  late ScanRepository scanRepository;
  late Uuid uuid;

  final testQuiz1 = Quiz(
    id: 'quiz-1',
    name: 'Math Quiz',
    templateId: 'template_20q',
    createdAt: DateTime(2024, 1, 15),
  );

  final testQuiz2 = Quiz(
    id: 'quiz-2',
    name: 'Science Quiz',
    templateId: 'template_10q',
    createdAt: DateTime(2024, 1, 20),
  );

  final testQuizzes = [testQuiz1, testQuiz2];

  setUp(() {
    repository = MockQuizRepository();
    scanRepository = MockScanRepository();
    uuid = MockUuid();
    when(() => uuid.v4()).thenReturn('new-quiz-id');
    when(() => scanRepository.deleteByQuizId(any())).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(testQuiz1);
  });

  group('QuizBloc', () {
    test('initial state is QuizInitial', () {
      final bloc = QuizBloc(repository, scanRepository, uuid: uuid);
      expect(bloc.state, const QuizInitial());
      bloc.close();
    });

    group('LoadQuizzes', () {
      blocTest<QuizBloc, QuizState>(
        'emits [QuizLoading, QuizLoaded] with sorted quizzes on success',
        setUp: () {
          when(() => repository.getAll()).thenAnswer((_) async => testQuizzes);
        },
        build: () => QuizBloc(repository, scanRepository, uuid: uuid),
        act: (bloc) => bloc.add(const LoadQuizzes()),
        expect: () => [
          const QuizLoading(),
          QuizLoaded(quizzes: [testQuiz2, testQuiz1]), // Sorted by date desc
        ],
        verify: (_) {
          verify(() => repository.getAll()).called(1);
        },
      );

      blocTest<QuizBloc, QuizState>(
        'emits [QuizLoading, QuizLoaded] with empty list when no quizzes',
        setUp: () {
          when(() => repository.getAll()).thenAnswer((_) async => []);
        },
        build: () => QuizBloc(repository, scanRepository, uuid: uuid),
        act: (bloc) => bloc.add(const LoadQuizzes()),
        expect: () => [
          const QuizLoading(),
          const QuizLoaded(quizzes: []),
        ],
      );

      blocTest<QuizBloc, QuizState>(
        'emits [QuizLoading, QuizError] on repository failure',
        setUp: () {
          when(() => repository.getAll())
              .thenThrow(Exception('Database error'));
        },
        build: () => QuizBloc(repository, scanRepository, uuid: uuid),
        act: (bloc) => bloc.add(const LoadQuizzes()),
        expect: () => [
          const QuizLoading(),
          isA<QuizError>()
              .having((e) => e.message, 'message', contains('Failed to load')),
        ],
      );
    });

    group('CreateQuiz', () {
      blocTest<QuizBloc, QuizState>(
        'emits [QuizLoading, QuizLoaded] with new quiz on success',
        setUp: () {
          when(() => repository.save(any())).thenAnswer((_) async {});
          when(() => repository.getAll()).thenAnswer((_) async {
            final newQuiz = Quiz(
              id: 'new-quiz-id',
              name: 'New Quiz',
              templateId: 'template_20q',
              createdAt: DateTime(2024, 1, 25),
            );
            return [newQuiz, ...testQuizzes];
          });
        },
        build: () => QuizBloc(repository, scanRepository, uuid: uuid),
        act: (bloc) => bloc.add(const CreateQuiz(
          name: 'New Quiz',
          templateId: 'template_20q',
        )),
        expect: () => [
          const QuizLoading(),
          isA<QuizLoaded>().having(
            (s) => s.quizzes.length,
            'quizzes length',
            3,
          ),
        ],
        verify: (_) {
          verify(() => repository.save(any())).called(1);
          verify(() => repository.getAll()).called(1);
        },
      );

      blocTest<QuizBloc, QuizState>(
        'emits [QuizLoading, QuizError] on save failure',
        setUp: () {
          when(() => repository.save(any()))
              .thenThrow(Exception('Save failed'));
        },
        build: () => QuizBloc(repository, scanRepository, uuid: uuid),
        act: (bloc) => bloc.add(const CreateQuiz(
          name: 'New Quiz',
          templateId: 'template_20q',
        )),
        expect: () => [
          const QuizLoading(),
          isA<QuizError>().having(
              (e) => e.message, 'message', contains('Failed to create')),
        ],
      );

      blocTest<QuizBloc, QuizState>(
        'generates unique UUID for new quiz',
        setUp: () {
          when(() => repository.save(any())).thenAnswer((_) async {});
          when(() => repository.getAll()).thenAnswer((_) async => []);
        },
        build: () => QuizBloc(repository, scanRepository, uuid: uuid),
        act: (bloc) => bloc.add(const CreateQuiz(
          name: 'Test',
          templateId: 'template_10q',
        )),
        verify: (_) {
          verify(() => uuid.v4()).called(1);
          final captured = verify(() => repository.save(captureAny())).captured;
          expect((captured.first as Quiz).id, 'new-quiz-id');
        },
      );
    });

    group('UpdateQuiz', () {
      final updatedQuiz = testQuiz1.copyWith(name: 'Updated Math Quiz');

      blocTest<QuizBloc, QuizState>(
        'emits [QuizLoading, QuizLoaded] with updated quiz on success',
        setUp: () {
          when(() => repository.save(any())).thenAnswer((_) async {});
          when(() => repository.getAll())
              .thenAnswer((_) async => [updatedQuiz, testQuiz2]);
        },
        build: () => QuizBloc(repository, scanRepository, uuid: uuid),
        act: (bloc) => bloc.add(UpdateQuiz(quiz: updatedQuiz)),
        expect: () => [
          const QuizLoading(),
          QuizLoaded(quizzes: [testQuiz2, updatedQuiz]),
        ],
        verify: (_) {
          verify(() => repository.save(updatedQuiz)).called(1);
          verify(() => repository.getAll()).called(1);
        },
      );

      blocTest<QuizBloc, QuizState>(
        'emits [QuizLoading, QuizError] on update failure',
        setUp: () {
          when(() => repository.save(any()))
              .thenThrow(Exception('Update failed'));
        },
        build: () => QuizBloc(repository, scanRepository, uuid: uuid),
        act: (bloc) => bloc.add(UpdateQuiz(quiz: updatedQuiz)),
        expect: () => [
          const QuizLoading(),
          isA<QuizError>().having(
              (e) => e.message, 'message', contains('Failed to update')),
        ],
      );
    });

    group('DeleteQuiz', () {
      blocTest<QuizBloc, QuizState>(
        'emits [QuizLoading, QuizLoaded] without deleted quiz on success',
        setUp: () {
          when(() => repository.delete(any())).thenAnswer((_) async {});
          when(() => repository.getAll()).thenAnswer((_) async => [testQuiz2]);
        },
        build: () => QuizBloc(repository, scanRepository, uuid: uuid),
        act: (bloc) => bloc.add(const DeleteQuiz(id: 'quiz-1')),
        expect: () => [
          const QuizLoading(),
          QuizLoaded(quizzes: [testQuiz2]),
        ],
        verify: (_) {
          verify(() => scanRepository.deleteByQuizId('quiz-1')).called(1);
          verify(() => repository.delete('quiz-1')).called(1);
          verify(() => repository.getAll()).called(1);
        },
      );

      blocTest<QuizBloc, QuizState>(
        'emits [QuizLoading, QuizError] on delete failure',
        setUp: () {
          when(() => repository.delete(any()))
              .thenThrow(Exception('Delete failed'));
        },
        build: () => QuizBloc(repository, scanRepository, uuid: uuid),
        act: (bloc) => bloc.add(const DeleteQuiz(id: 'quiz-1')),
        expect: () => [
          const QuizLoading(),
          isA<QuizError>().having(
              (e) => e.message, 'message', contains('Failed to delete')),
        ],
      );
    });

    group('Event props', () {
      test('LoadQuizzes has empty props', () {
        expect(const LoadQuizzes().props, []);
      });

      test('CreateQuiz has name and templateId in props', () {
        const event = CreateQuiz(name: 'Test', templateId: 'template_10q');
        expect(event.props, ['Test', 'template_10q']);
      });

      test('UpdateQuiz has quiz in props', () {
        final event = UpdateQuiz(quiz: testQuiz1);
        expect(event.props, [testQuiz1]);
      });

      test('DeleteQuiz has id in props', () {
        const event = DeleteQuiz(id: 'quiz-1');
        expect(event.props, ['quiz-1']);
      });
    });

    group('State props', () {
      test('QuizInitial has empty props', () {
        expect(const QuizInitial().props, []);
      });

      test('QuizLoading has empty props', () {
        expect(const QuizLoading().props, []);
      });

      test('QuizLoaded has quizzes in props', () {
        final state = QuizLoaded(quizzes: testQuizzes);
        expect(state.props, [testQuizzes]);
      });

      test('QuizError has message in props', () {
        const state = QuizError(message: 'Error');
        expect(state.props, ['Error']);
      });
    });

    group('State equality', () {
      test('two QuizLoaded with same quizzes are equal', () {
        final state1 = QuizLoaded(quizzes: testQuizzes);
        final state2 = QuizLoaded(quizzes: testQuizzes);
        expect(state1, state2);
      });

      test('two QuizLoaded with different quizzes are not equal', () {
        final state1 = QuizLoaded(quizzes: testQuizzes);
        final state2 = QuizLoaded(quizzes: [testQuiz1]);
        expect(state1, isNot(state2));
      });

      test('two QuizError with same message are equal', () {
        const state1 = QuizError(message: 'Error');
        const state2 = QuizError(message: 'Error');
        expect(state1, state2);
      });
    });
  });
}
