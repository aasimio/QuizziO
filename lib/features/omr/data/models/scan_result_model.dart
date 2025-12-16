import 'dart:typed_data';

import 'package:hive/hive.dart';

import '../../domain/entities/answer_status.dart';
import '../../domain/entities/scan_result.dart';

part 'scan_result_model.g.dart';

@HiveType(typeId: 1)
class ScanResultModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String quizId;

  @HiveField(2)
  final DateTime scannedAt;

  @HiveField(3)
  final Uint8List nameRegionImage;

  @HiveField(4)
  final Map<String, String?> detectedAnswerValues;

  @HiveField(5)
  final Map<String, String> answerStatuses;

  @HiveField(6)
  final Map<String, String?> correctedAnswers;

  @HiveField(7)
  final int score;

  @HiveField(8)
  final int total;

  @HiveField(9)
  final double percentage;

  @HiveField(10)
  final bool wasEdited;

  @HiveField(11)
  final double scanConfidence;

  @HiveField(12)
  final String? rawBubbleValues;

  ScanResultModel({
    required this.id,
    required this.quizId,
    required this.scannedAt,
    required this.nameRegionImage,
    required this.detectedAnswerValues,
    required this.answerStatuses,
    required this.correctedAnswers,
    required this.score,
    required this.total,
    required this.percentage,
    required this.wasEdited,
    required this.scanConfidence,
    this.rawBubbleValues,
  });

  ScanResult toEntity() {
    final Map<String, AnswerStatus> detectedAnswers = {};
    for (final entry in detectedAnswerValues.entries) {
      final statusString = answerStatuses[entry.key] ?? 'BLANK';
      detectedAnswers[entry.key] = AnswerStatus.fromJson(
        statusString,
        entry.value,
      );
    }

    return ScanResult(
      id: id,
      quizId: quizId,
      scannedAt: scannedAt,
      nameRegionImage: Uint8List.fromList(nameRegionImage),
      detectedAnswers: detectedAnswers,
      correctedAnswers: Map<String, String?>.from(correctedAnswers),
      score: score,
      total: total,
      percentage: percentage,
      wasEdited: wasEdited,
      scanConfidence: scanConfidence,
      rawBubbleValues: rawBubbleValues,
    );
  }

  factory ScanResultModel.fromEntity(ScanResult result) {
    final Map<String, String?> answerValues = {};
    final Map<String, String> statuses = {};

    for (final entry in result.detectedAnswers.entries) {
      answerValues[entry.key] = entry.value.value;
      statuses[entry.key] = entry.value.toJson();
    }

    return ScanResultModel(
      id: result.id,
      quizId: result.quizId,
      scannedAt: result.scannedAt,
      nameRegionImage: Uint8List.fromList(result.nameRegionImage),
      detectedAnswerValues: answerValues,
      answerStatuses: statuses,
      correctedAnswers: Map<String, String?>.from(result.correctedAnswers),
      score: result.score,
      total: result.total,
      percentage: result.percentage,
      wasEdited: result.wasEdited,
      scanConfidence: result.scanConfidence,
      rawBubbleValues: result.rawBubbleValues,
    );
  }
}
