import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../omr/services/template_manager.dart';
import '../../domain/repositories/quiz_repository.dart';
import 'answer_key_state.dart';

@injectable
class AnswerKeyCubit extends Cubit<AnswerKeyState> {
  final QuizRepository _quizRepository;
  final TemplateManager _templateManager;

  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 500);

  AnswerKeyCubit(this._quizRepository, this._templateManager)
      : super(const AnswerKeyState.initial());

  Future<void> load(String quizId) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final quiz = await _quizRepository.getById(quizId);
      if (isClosed) return;

      if (quiz == null) {
        emit(state.copyWith(
          isLoading: false,
          error: 'Quiz not found',
        ));
        return;
      }

      final template = await _templateManager.getTemplate(quiz.templateId);
      if (isClosed) return;

      emit(state.copyWith(
        quiz: quiz,
        answers: Map<String, String>.from(quiz.answerKey),
        isLoading: false,
        questionCount: template.questionCount,
        options: template.options,
        questionLabels: template.allQuestionLabels,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load answer key: ${e.toString()}',
      ));
    }
  }

  void selectAnswer(String questionId, String option) {
    final updatedAnswers = Map<String, String>.from(state.answers);
    updatedAnswers[questionId] = option;

    emit(state.copyWith(answers: updatedAnswers, clearError: true));

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, _debouncedSave);
  }

  void clearAnswer(String questionId) {
    final updatedAnswers = Map<String, String>.from(state.answers);
    updatedAnswers.remove(questionId);

    emit(state.copyWith(answers: updatedAnswers, clearError: true));

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, _debouncedSave);
  }

  Future<void> _debouncedSave() async {
    if (state.quiz == null) return;

    emit(state.copyWith(isSaving: true));

    try {
      final updatedQuiz = state.quiz!.copyWith(answerKey: state.answers);
      await _quizRepository.save(updatedQuiz);
      if (isClosed) return;

      emit(state.copyWith(
        quiz: updatedQuiz,
        isSaving: false,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isSaving: false,
        error: 'Failed to save: ${e.toString()}',
      ));
    }
  }

  Future<void> saveNow() async {
    _debounceTimer?.cancel();
    await _debouncedSave();
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
