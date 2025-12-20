import 'package:equatable/equatable.dart';

import '../../domain/entities/scan_result.dart';

sealed class GradedPapersEvent extends Equatable {
  const GradedPapersEvent();

  @override
  List<Object?> get props => [];
}

class LoadResults extends GradedPapersEvent {
  final String quizId;

  const LoadResults({required this.quizId});

  @override
  List<Object?> get props => [quizId];
}

class UpdateResult extends GradedPapersEvent {
  final ScanResult result;
  final Map<String, String?> correctedAnswers;

  const UpdateResult({
    required this.result,
    required this.correctedAnswers,
  });

  @override
  List<Object?> get props => [result, correctedAnswers];
}

class DeleteResult extends GradedPapersEvent {
  final String resultId;

  const DeleteResult({required this.resultId});

  @override
  List<Object?> get props => [resultId];
}
