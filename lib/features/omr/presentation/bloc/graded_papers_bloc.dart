import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../quiz/domain/repositories/quiz_repository.dart';
import '../../domain/entities/answer_status.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/scan_repository.dart';
import '../../services/grading_service.dart';
import 'graded_papers_event.dart';
import 'graded_papers_state.dart';

@injectable
class GradedPapersBloc extends Bloc<GradedPapersEvent, GradedPapersState> {
  final ScanRepository _scanRepository;
  final QuizRepository _quizRepository;
  final GradingService _gradingService;

  static const _multipleMarkSentinel = 'MULTIPLE_MARK';

  GradedPapersBloc(
    this._scanRepository,
    this._quizRepository,
    this._gradingService,
  ) : super(const ResultsInitial()) {
    on<LoadResults>(_onLoadResults);
    on<UpdateResult>(_onUpdateResult);
    on<DeleteResult>(_onDeleteResult);
  }

  Future<void> _onLoadResults(
    LoadResults event,
    Emitter<GradedPapersState> emit,
  ) async {
    emit(const ResultsLoading());
    try {
      final results = await _scanRepository.getByQuizId(event.quizId);
      if (isClosed) return;
      final sortedResults = _sortByScannedAtDesc(results);
      emit(ResultsLoaded(
        quizId: event.quizId,
        results: sortedResults,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(ResultsError(
        message: 'Failed to load results: ${e.toString()}',
      ));
    }
  }

  List<ScanResult> _sortByScannedAtDesc(List<ScanResult> results) {
    final sorted = List<ScanResult>.from(results)
      ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return sorted;
  }

  Future<void> _onUpdateResult(
    UpdateResult event,
    Emitter<GradedPapersState> emit,
  ) async {
    final currentState = state;
    emit(const ResultsLoading());
    try {
      final quiz = await _quizRepository.getById(event.result.quizId);
      if (isClosed) return;

      if (quiz == null) {
        emit(const ResultsError(
          message: 'Failed to update result: quiz not found',
        ));
        if (currentState is ResultsLoaded) {
          emit(currentState);
        }
        return;
      }

      final updatedCorrectedAnswers =
          Map<String, String?>.from(event.correctedAnswers);
      final effectiveAnswers = _applyCorrections(
        event.result.detectedAnswers,
        updatedCorrectedAnswers,
      );

      final gradedResult = _gradingService.grade(
        extractedAnswers: effectiveAnswers,
        answerKey: quiz.answerKey,
      );

      final updatedResult = event.result.copyWith(
        correctedAnswers: updatedCorrectedAnswers,
        wasEdited:
            event.result.wasEdited || updatedCorrectedAnswers.isNotEmpty,
        score: gradedResult.score,
        total: gradedResult.total,
        percentage: gradedResult.percentage,
      );

      await _scanRepository.update(updatedResult);
      if (isClosed) return;

      if (currentState is ResultsLoaded &&
          currentState.quizId == updatedResult.quizId) {
        final updatedResults = currentState.results
            .map((result) =>
                result.id == updatedResult.id ? updatedResult : result)
            .toList();
        emit(ResultsLoaded(
          quizId: currentState.quizId,
          results: _sortByScannedAtDesc(updatedResults),
        ));
      } else {
        final refreshedResults =
            await _scanRepository.getByQuizId(updatedResult.quizId);
        if (isClosed) return;
        emit(ResultsLoaded(
          quizId: updatedResult.quizId,
          results: _sortByScannedAtDesc(refreshedResults),
        ));
      }
    } catch (e) {
      if (isClosed) return;
      emit(ResultsError(
        message: 'Failed to update result: ${e.toString()}',
      ));
      if (currentState is ResultsLoaded) {
        emit(currentState);
      }
    }
  }

  Map<String, AnswerStatus> _applyCorrections(
    Map<String, AnswerStatus> detectedAnswers,
    Map<String, String?> correctedAnswers,
  ) {
    final effective = Map<String, AnswerStatus>.from(detectedAnswers);
    for (final entry in correctedAnswers.entries) {
      final value = entry.value;
      if (value == null) {
        effective[entry.key] = const AnswerStatus.blank();
      } else if (value == _multipleMarkSentinel) {
        effective[entry.key] = const AnswerStatus.multipleMark();
      } else {
        effective[entry.key] = AnswerStatus.valid(value);
      }
    }
    return effective;
  }

  Future<void> _onDeleteResult(
    DeleteResult event,
    Emitter<GradedPapersState> emit,
  ) async {
    final currentState = state;
    emit(const ResultsLoading());
    try {
      await _scanRepository.delete(event.resultId);
      if (isClosed) return;

      if (currentState is ResultsLoaded) {
        final updatedResults = currentState.results
            .where((result) => result.id != event.resultId)
            .toList();
        emit(ResultsLoaded(
          quizId: currentState.quizId,
          results: _sortByScannedAtDesc(updatedResults),
        ));
      } else {
        emit(const ResultsInitial());
      }
    } catch (e) {
      if (isClosed) return;
      emit(ResultsError(
        message: 'Failed to delete result: ${e.toString()}',
      ));
      if (currentState is ResultsLoaded) {
        emit(currentState);
      }
    }
  }
}
