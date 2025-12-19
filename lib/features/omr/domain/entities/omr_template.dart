import 'package:equatable/equatable.dart';

import 'field_block.dart';

class OmrTemplate extends Equatable {
  final String id;
  final String name;
  final String version;
  final int questionCount;
  final int pageWidth;
  final int pageHeight;
  final int pageDpi;
  final int bubbleWidth;
  final int bubbleHeight;
  final int nameRegionX;
  final int nameRegionY;
  final int nameRegionWidth;
  final int nameRegionHeight;
  final List<FieldBlock> fieldBlocks;

  const OmrTemplate({
    required this.id,
    required this.name,
    required this.version,
    required this.questionCount,
    required this.pageWidth,
    required this.pageHeight,
    required this.pageDpi,
    required this.bubbleWidth,
    required this.bubbleHeight,
    required this.nameRegionX,
    required this.nameRegionY,
    required this.nameRegionWidth,
    required this.nameRegionHeight,
    required this.fieldBlocks,
  });

  factory OmrTemplate.fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'] as String? ??
          (throw FormatException('Missing required field: id'));
      final name = json['name'] as String? ??
          (throw FormatException('Missing required field: name'));
      final version = json['version'] as String? ??
          (throw FormatException('Missing required field: version'));
      final questionCount = json['questionCount'] as int? ??
          (throw FormatException('Missing required field: questionCount'));

      final pageDimensions = json['pageDimensions'] as Map<String, dynamic>? ??
          (throw FormatException('Missing required field: pageDimensions'));
      final pageWidth = pageDimensions['width'] as int? ??
          (throw FormatException(
              'Missing required field: pageDimensions.width'));
      final pageHeight = pageDimensions['height'] as int? ??
          (throw FormatException(
              'Missing required field: pageDimensions.height'));
      final pageDpi = pageDimensions['dpi'] as int? ??
          (throw FormatException('Missing required field: pageDimensions.dpi'));

      final bubbleDimensions = json['bubbleDimensions']
              as Map<String, dynamic>? ??
          (throw FormatException('Missing required field: bubbleDimensions'));
      final bubbleWidth = bubbleDimensions['width'] as int? ??
          (throw FormatException(
              'Missing required field: bubbleDimensions.width'));
      final bubbleHeight = bubbleDimensions['height'] as int? ??
          (throw FormatException(
              'Missing required field: bubbleDimensions.height'));

      final nameRegion = json['nameRegion'] as Map<String, dynamic>? ??
          (throw FormatException('Missing required field: nameRegion'));
      final nameRegionX = nameRegion['x'] as int? ??
          (throw FormatException('Missing required field: nameRegion.x'));
      final nameRegionY = nameRegion['y'] as int? ??
          (throw FormatException('Missing required field: nameRegion.y'));
      final nameRegionWidth = nameRegion['width'] as int? ??
          (throw FormatException('Missing required field: nameRegion.width'));
      final nameRegionHeight = nameRegion['height'] as int? ??
          (throw FormatException('Missing required field: nameRegion.height'));

      final fieldBlocksList = json['fieldBlocks'] as List? ??
          (throw FormatException('Missing required field: fieldBlocks'));

      final fieldBlocks = <FieldBlock>[];
      for (var i = 0; i < fieldBlocksList.length; i++) {
        final block = fieldBlocksList[i];
        if (block is! Map<String, dynamic>) {
          throw FormatException(
            'Invalid fieldBlocks[$i]: expected Map<String, dynamic>, got ${block.runtimeType}',
          );
        }
        try {
          fieldBlocks.add(FieldBlock.fromJson(block));
        } on FormatException catch (e) {
          throw FormatException('Invalid fieldBlocks[$i]: ${e.message}');
        }
      }

      return OmrTemplate(
        id: id,
        name: name,
        version: version,
        questionCount: questionCount,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        pageDpi: pageDpi,
        bubbleWidth: bubbleWidth,
        bubbleHeight: bubbleHeight,
        nameRegionX: nameRegionX,
        nameRegionY: nameRegionY,
        nameRegionWidth: nameRegionWidth,
        nameRegionHeight: nameRegionHeight,
        fieldBlocks: fieldBlocks,
      );
    } on FormatException {
      rethrow;
    } on TypeError catch (e) {
      throw FormatException('Invalid JSON type: $e');
    } catch (e) {
      throw FormatException('Failed to parse OmrTemplate: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'questionCount': questionCount,
      'pageDimensions': {
        'width': pageWidth,
        'height': pageHeight,
        'dpi': pageDpi,
      },
      'bubbleDimensions': {
        'width': bubbleWidth,
        'height': bubbleHeight,
      },
      'nameRegion': {
        'x': nameRegionX,
        'y': nameRegionY,
        'width': nameRegionWidth,
        'height': nameRegionHeight,
      },
      'fieldBlocks': fieldBlocks.map((block) => block.toJson()).toList(),
    };
  }

  List<String> get allQuestionLabels {
    return fieldBlocks.expand((block) => block.questionLabels).toList();
  }

  List<String> get options {
    if (fieldBlocks.isEmpty) return [];
    return fieldBlocks.first.options;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        version,
        questionCount,
        pageWidth,
        pageHeight,
        pageDpi,
        bubbleWidth,
        bubbleHeight,
        nameRegionX,
        nameRegionY,
        nameRegionWidth,
        nameRegionHeight,
        fieldBlocks,
      ];
}
