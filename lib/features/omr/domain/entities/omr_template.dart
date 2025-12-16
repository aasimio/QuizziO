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
    final pageDimensions = json['pageDimensions'] as Map<String, dynamic>;
    final bubbleDimensions = json['bubbleDimensions'] as Map<String, dynamic>;
    final nameRegion = json['nameRegion'] as Map<String, dynamic>;
    final fieldBlocksList = json['fieldBlocks'] as List;

    return OmrTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      questionCount: json['questionCount'] as int,
      pageWidth: pageDimensions['width'] as int,
      pageHeight: pageDimensions['height'] as int,
      pageDpi: pageDimensions['dpi'] as int,
      bubbleWidth: bubbleDimensions['width'] as int,
      bubbleHeight: bubbleDimensions['height'] as int,
      nameRegionX: nameRegion['x'] as int,
      nameRegionY: nameRegion['y'] as int,
      nameRegionWidth: nameRegion['width'] as int,
      nameRegionHeight: nameRegion['height'] as int,
      fieldBlocks: fieldBlocksList
          .map((block) => FieldBlock.fromJson(block as Map<String, dynamic>))
          .toList(),
    );
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
