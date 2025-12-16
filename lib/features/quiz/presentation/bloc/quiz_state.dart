import 'package:equatable/equatable.dart';

import '../../domain/entities/quiz.dart';

sealed class QuizState extends Equatable {
  const QuizState();

  @override
  List<Object?> get props => [];
}

class QuizInitial extends QuizState {
  const QuizInitial();
}

class QuizLoading extends QuizState {
  const QuizLoading();
}

class QuizLoaded extends QuizState {
  final List<Quiz> quizzes;

  const QuizLoaded({required this.quizzes});

  @override
  List<Object?> get props => [quizzes];
}

class QuizError extends QuizState {
  final String message;

  const QuizError({required this.message});

  @override
  List<Object?> get props => [message];
}
