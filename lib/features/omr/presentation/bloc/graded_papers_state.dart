import 'package:equatable/equatable.dart';

import '../../domain/entities/scan_result.dart';

sealed class GradedPapersState extends Equatable {
  const GradedPapersState();

  @override
  List<Object?> get props => [];
}

class ResultsInitial extends GradedPapersState {
  const ResultsInitial();
}

class ResultsLoading extends GradedPapersState {
  const ResultsLoading();
}

class ResultsLoaded extends GradedPapersState {
  final String quizId;
  final List<ScanResult> results;

  const ResultsLoaded({
    required this.quizId,
    required this.results,
  });

  ResultsLoaded copyWith({
    String? quizId,
    List<ScanResult>? results,
  }) {
    return ResultsLoaded(
      quizId: quizId ?? this.quizId,
      results: results ?? this.results,
    );
  }

  @override
  List<Object?> get props => [quizId, results];
}

class ResultsError extends GradedPapersState {
  final String message;

  const ResultsError({required this.message});

  @override
  List<Object?> get props => [message];
}
