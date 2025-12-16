import 'package:hive/hive.dart';

import '../../domain/entities/quiz.dart';

part 'quiz_model.g.dart';

@HiveType(typeId: 0)
class QuizModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String templateId;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final Map<String, String> answerKey;

  QuizModel({
    required this.id,
    required this.name,
    required this.templateId,
    required this.createdAt,
    required this.answerKey,
  });

  Quiz toEntity() {
    return Quiz(
      id: id,
      name: name,
      templateId: templateId,
      createdAt: createdAt,
      answerKey: Map<String, String>.from(answerKey),
    );
  }

  factory QuizModel.fromEntity(Quiz quiz) {
    return QuizModel(
      id: quiz.id,
      name: quiz.name,
      templateId: quiz.templateId,
      createdAt: quiz.createdAt,
      answerKey: Map<String, String>.from(quiz.answerKey),
    );
  }
}
