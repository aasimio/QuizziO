import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../omr/domain/repositories/scan_repository.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/repositories/quiz_repository.dart';
import 'quiz_event.dart';
import 'quiz_state.dart';

@injectable
class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final QuizRepository _repository;
  final ScanRepository _scanRepository;
  final Uuid _uuid;

  QuizBloc(this._repository, this._scanRepository, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid(),
        super(const QuizInitial()) {
    on<LoadQuizzes>(_onLoadQuizzes);
    on<CreateQuiz>(_onCreateQuiz);
    on<UpdateQuiz>(_onUpdateQuiz);
    on<DeleteQuiz>(_onDeleteQuiz);
  }

  Future<void> _onLoadQuizzes(
    LoadQuizzes event,
    Emitter<QuizState> emit,
  ) async {
    emit(const QuizLoading());
    try {
      final quizzes = await _repository.getAll();
      if (isClosed) return;
      final sorted = List<Quiz>.from(quizzes)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(QuizLoaded(quizzes: sorted));
    } catch (e) {
      if (isClosed) return;
      emit(QuizError(message: 'Failed to load quizzes: ${e.toString()}'));
    }
  }

  Future<void> _onCreateQuiz(
    CreateQuiz event,
    Emitter<QuizState> emit,
  ) async {
    final currentState = state;
    emit(const QuizLoading());
    try {
      final quiz = Quiz(
        id: _uuid.v4(),
        name: event.name,
        templateId: event.templateId,
        createdAt: DateTime.now(),
      );
      await _repository.save(quiz);
      if (isClosed) return;
      final quizzes = await _repository.getAll();
      if (isClosed) return;
      final sorted = List<Quiz>.from(quizzes)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(QuizLoaded(quizzes: sorted));
    } catch (e) {
      if (isClosed) return;
      emit(QuizError(message: 'Failed to create quiz: ${e.toString()}'));
      if (currentState is QuizLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onUpdateQuiz(
    UpdateQuiz event,
    Emitter<QuizState> emit,
  ) async {
    final currentState = state;
    emit(const QuizLoading());
    try {
      await _repository.save(event.quiz);
      if (isClosed) return;
      final quizzes = await _repository.getAll();
      if (isClosed) return;
      final sorted = List<Quiz>.from(quizzes)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(QuizLoaded(quizzes: sorted));
    } catch (e) {
      if (isClosed) return;
      emit(QuizError(message: 'Failed to update quiz: ${e.toString()}'));
      if (currentState is QuizLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onDeleteQuiz(
    DeleteQuiz event,
    Emitter<QuizState> emit,
  ) async {
    final currentState = state;
    emit(const QuizLoading());
    try {
      await _scanRepository.deleteByQuizId(event.id);
      await _repository.delete(event.id);
      if (isClosed) return;
      final quizzes = await _repository.getAll();
      if (isClosed) return;
      final sorted = List<Quiz>.from(quizzes)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(QuizLoaded(quizzes: sorted));
    } catch (e) {
      if (isClosed) return;
      emit(QuizError(message: 'Failed to delete quiz: ${e.toString()}'));
      if (currentState is QuizLoaded) {
        emit(currentState);
      }
    }
  }
}
