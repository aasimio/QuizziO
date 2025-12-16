import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'answer_status.dart';

class ScanResult extends Equatable {
  final String id;
  final String quizId;
  final DateTime scannedAt;
  final Uint8List nameRegionImage;
  final Map<String, AnswerStatus> detectedAnswers;
  final Map<String, String?> correctedAnswers;
  final int score;
  final int total;
  final double percentage;
  final bool wasEdited;
  final double scanConfidence;
  final String? rawBubbleValues;

  const ScanResult({
    required this.id,
    required this.quizId,
    required this.scannedAt,
    required this.nameRegionImage,
    required this.detectedAnswers,
    this.correctedAnswers = const {},
    required this.score,
    required this.total,
    required this.percentage,
    this.wasEdited = false,
    required this.scanConfidence,
    this.rawBubbleValues,
  });

  String? getAnswer(String questionId) {
    if (correctedAnswers.containsKey(questionId)) {
      return correctedAnswers[questionId];
    }
    final detected = detectedAnswers[questionId];
    return detected?.value;
  }

  AnswerStatus? getAnswerStatus(String questionId) {
    return detectedAnswers[questionId];
  }

  int get blankCount =>
      detectedAnswers.values.where((s) => s.isBlank).length;

  int get multipleMarkCount =>
      detectedAnswers.values.where((s) => s.isMultipleMark).length;

  ScanResult copyWith({
    String? id,
    String? quizId,
    DateTime? scannedAt,
    Uint8List? nameRegionImage,
    Map<String, AnswerStatus>? detectedAnswers,
    Map<String, String?>? correctedAnswers,
    int? score,
    int? total,
    double? percentage,
    bool? wasEdited,
    double? scanConfidence,
    String? rawBubbleValues,
  }) {
    return ScanResult(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      scannedAt: scannedAt ?? this.scannedAt,
      nameRegionImage: nameRegionImage ?? this.nameRegionImage,
      detectedAnswers: detectedAnswers ?? this.detectedAnswers,
      correctedAnswers: correctedAnswers ?? this.correctedAnswers,
      score: score ?? this.score,
      total: total ?? this.total,
      percentage: percentage ?? this.percentage,
      wasEdited: wasEdited ?? this.wasEdited,
      scanConfidence: scanConfidence ?? this.scanConfidence,
      rawBubbleValues: rawBubbleValues ?? this.rawBubbleValues,
    );
  }

  @override
  List<Object?> get props => [
        id,
        quizId,
        scannedAt,
        nameRegionImage,
        detectedAnswers,
        correctedAnswers,
        score,
        total,
        percentage,
        wasEdited,
        scanConfidence,
        rawBubbleValues,
      ];
}
