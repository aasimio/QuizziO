import 'package:equatable/equatable.dart';

class FieldBlock extends Equatable {
  final String name;
  final int originX;
  final int originY;
  final List<String> options;
  final int bubblesGap;
  final int labelsGap;
  final List<String> questionLabels;
  final String direction;

  const FieldBlock({
    required this.name,
    required this.originX,
    required this.originY,
    required this.options,
    required this.bubblesGap,
    required this.labelsGap,
    required this.questionLabels,
    required this.direction,
  });

  factory FieldBlock.fromJson(Map<String, dynamic> json) {
    final origin = json['origin'] as Map<String, dynamic>;
    return FieldBlock(
      name: json['name'] as String,
      originX: origin['x'] as int,
      originY: origin['y'] as int,
      options: List<String>.from(json['options'] as List),
      bubblesGap: json['bubblesGap'] as int,
      labelsGap: json['labelsGap'] as int,
      questionLabels: List<String>.from(json['questionLabels'] as List),
      direction: json['direction'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'origin': {'x': originX, 'y': originY},
      'options': options,
      'bubblesGap': bubblesGap,
      'labelsGap': labelsGap,
      'questionLabels': questionLabels,
      'direction': direction,
    };
  }

  @override
  List<Object?> get props => [
        name,
        originX,
        originY,
        options,
        bubblesGap,
        labelsGap,
        questionLabels,
        direction,
      ];
}
