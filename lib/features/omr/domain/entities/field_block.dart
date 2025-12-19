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
    // Validate required 'name' field
    final name = json['name'];
    if (name == null) {
      throw const FormatException("FieldBlock: missing required field 'name'");
    }
    if (name is! String) {
      throw FormatException(
        "FieldBlock: 'name' must be a String, got ${name.runtimeType}",
      );
    }

    // Validate required 'origin' field
    final origin = json['origin'];
    if (origin == null) {
      throw const FormatException(
        "FieldBlock: missing required field 'origin'",
      );
    }
    if (origin is! Map<String, dynamic>) {
      throw FormatException(
        "FieldBlock: 'origin' must be a Map<String, dynamic>, "
        "got ${origin.runtimeType}",
      );
    }

    // Validate origin.x
    final originX = origin['x'];
    if (originX == null) {
      throw const FormatException(
        "FieldBlock: missing required field 'origin.x'",
      );
    }
    if (originX is! int) {
      throw FormatException(
        "FieldBlock: 'origin.x' must be an int, got ${originX.runtimeType}",
      );
    }

    // Validate origin.y
    final originY = origin['y'];
    if (originY == null) {
      throw const FormatException(
        "FieldBlock: missing required field 'origin.y'",
      );
    }
    if (originY is! int) {
      throw FormatException(
        "FieldBlock: 'origin.y' must be an int, got ${originY.runtimeType}",
      );
    }

    // Validate required 'direction' field
    final direction = json['direction'];
    if (direction == null) {
      throw const FormatException(
        "FieldBlock: missing required field 'direction'",
      );
    }
    if (direction is! String) {
      throw FormatException(
        "FieldBlock: 'direction' must be a String, got ${direction.runtimeType}",
      );
    }

    // Validate required 'bubblesGap' field
    final bubblesGap = json['bubblesGap'];
    if (bubblesGap == null) {
      throw const FormatException(
        "FieldBlock: missing required field 'bubblesGap'",
      );
    }
    if (bubblesGap is! int) {
      throw FormatException(
        "FieldBlock: 'bubblesGap' must be an int, got ${bubblesGap.runtimeType}",
      );
    }

    // Validate required 'labelsGap' field
    final labelsGap = json['labelsGap'];
    if (labelsGap == null) {
      throw const FormatException(
        "FieldBlock: missing required field 'labelsGap'",
      );
    }
    if (labelsGap is! int) {
      throw FormatException(
        "FieldBlock: 'labelsGap' must be an int, got ${labelsGap.runtimeType}",
      );
    }

    // Parse options list with safe casting (fallback to empty list)
    final optionsRaw = json['options'];
    final List<String> options;
    if (optionsRaw == null) {
      options = [];
    } else if (optionsRaw is List) {
      options = optionsRaw.map((e) => e?.toString() ?? '').toList();
    } else {
      throw FormatException(
        "FieldBlock: 'options' must be a List, got ${optionsRaw.runtimeType}",
      );
    }

    // Parse questionLabels list with safe casting (fallback to empty list)
    final questionLabelsRaw = json['questionLabels'];
    final List<String> questionLabels;
    if (questionLabelsRaw == null) {
      questionLabels = [];
    } else if (questionLabelsRaw is List) {
      questionLabels =
          questionLabelsRaw.map((e) => e?.toString() ?? '').toList();
    } else {
      throw FormatException(
        "FieldBlock: 'questionLabels' must be a List, "
        "got ${questionLabelsRaw.runtimeType}",
      );
    }

    return FieldBlock(
      name: name,
      originX: originX,
      originY: originY,
      options: options,
      bubblesGap: bubblesGap,
      labelsGap: labelsGap,
      questionLabels: questionLabels,
      direction: direction,
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
