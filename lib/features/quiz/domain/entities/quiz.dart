import 'package:equatable/equatable.dart';

class Quiz extends Equatable {
  final String id;
  final String name;
  final String templateId;
  final DateTime createdAt;
  final Map<String, String> answerKey;

  const Quiz({
    required this.id,
    required this.name,
    required this.templateId,
    required this.createdAt,
    this.answerKey = const {},
  });

  Quiz copyWith({
    String? id,
    String? name,
    String? templateId,
    DateTime? createdAt,
    Map<String, String>? answerKey,
  }) {
    return Quiz(
      id: id ?? this.id,
      name: name ?? this.name,
      templateId: templateId ?? this.templateId,
      createdAt: createdAt ?? this.createdAt,
      answerKey: answerKey ?? this.answerKey,
    );
  }

  @override
  List<Object?> get props => [id, name, templateId, createdAt, answerKey];
}
