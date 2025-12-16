import 'package:equatable/equatable.dart';

import '../../domain/entities/quiz.dart';

sealed class QuizEvent extends Equatable {
  const QuizEvent();

  @override
  List<Object?> get props => [];
}

class LoadQuizzes extends QuizEvent {
  const LoadQuizzes();
}

class CreateQuiz extends QuizEvent {
  final String name;
  final String templateId;

  const CreateQuiz({
    required this.name,
    required this.templateId,
  });

  @override
  List<Object?> get props => [name, templateId];
}

class UpdateQuiz extends QuizEvent {
  final Quiz quiz;

  const UpdateQuiz({required this.quiz});

  @override
  List<Object?> get props => [quiz];
}

class DeleteQuiz extends QuizEvent {
  final String id;

  const DeleteQuiz({required this.id});

  @override
  List<Object?> get props => [id];
}
