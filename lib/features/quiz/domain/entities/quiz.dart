import 'package:equatable/equatable.dart';

class Quiz extends Equatable {
  final String id;
  final String name;
  final String templateId;
  final DateTime createdAt;
  final Map<String, String> answerKey;

  // ignore: prefer_const_constructors_in_immutables
  Quiz({
    required this.id,
    required this.name,
    required this.templateId,
    required this.createdAt,
    Map<String, String> answerKey = const {},
  }) : answerKey = Map.unmodifiable(Map.from(answerKey));

  const Quiz._internal({
    required this.id,
    required this.name,
    required this.templateId,
    required this.createdAt,
    required this.answerKey,
  });

  Quiz copyWith({
    String? id,
    String? name,
    String? templateId,
    DateTime? createdAt,
    Map<String, String>? answerKey,
  }) {
    return Quiz._internal(
      id: id ?? this.id,
      name: name ?? this.name,
      templateId: templateId ?? this.templateId,
      createdAt: createdAt ?? this.createdAt,
      answerKey: answerKey != null
          ? Map.unmodifiable(Map.from(answerKey))
          : Map.unmodifiable(Map.from(this.answerKey)),
    );
  }

  @override
  List<Object?> get props => [id, name, templateId, createdAt, answerKey];
}
