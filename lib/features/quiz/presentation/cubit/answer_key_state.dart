import 'package:equatable/equatable.dart';

import '../../domain/entities/quiz.dart';

class AnswerKeyState extends Equatable {
  final Quiz? quiz;
  final Map<String, String> answers;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final int questionCount;
  final List<String> options;
  final List<String> questionLabels;

  const AnswerKeyState({
    this.quiz,
    this.answers = const {},
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.questionCount = 0,
    this.options = const [],
    this.questionLabels = const [],
  });

  const AnswerKeyState.initial()
      : quiz = null,
        answers = const {},
        isLoading = false,
        isSaving = false,
        error = null,
        questionCount = 0,
        options = const [],
        questionLabels = const [];

  AnswerKeyState copyWith({
    Quiz? quiz,
    Map<String, String>? answers,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    int? questionCount,
    List<String>? options,
    List<String>? questionLabels,
  }) {
    return AnswerKeyState(
      quiz: quiz ?? this.quiz,
      answers: answers ?? this.answers,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      questionCount: questionCount ?? this.questionCount,
      options: options ?? this.options,
      questionLabels: questionLabels ?? this.questionLabels,
    );
  }

  @override
  List<Object?> get props => [
        quiz,
        answers,
        isLoading,
        isSaving,
        error,
        questionCount,
        options,
        questionLabels,
      ];
}
