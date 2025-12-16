import 'package:equatable/equatable.dart';

enum AnswerType { valid, blank, multipleMark, inconsistent }

class AnswerStatus extends Equatable {
  final String? value;
  final AnswerType type;

  const AnswerStatus({
    this.value,
    required this.type,
  });

  const AnswerStatus.valid(String answer)
      : value = answer,
        type = AnswerType.valid;

  const AnswerStatus.blank()
      : value = null,
        type = AnswerType.blank;

  const AnswerStatus.multipleMark()
      : value = null,
        type = AnswerType.multipleMark;

  /// Data inconsistency detected (e.g., missing status for a detected answer key)
  const AnswerStatus.inconsistent(String context)
      : value = context,
        type = AnswerType.inconsistent;

  bool get isValid => type == AnswerType.valid;
  bool get isBlank => type == AnswerType.blank;
  bool get isMultipleMark => type == AnswerType.multipleMark;
  bool get isInconsistent => type == AnswerType.inconsistent;

  Map<String, dynamic> toJson() {
    return {
      'type': switch (type) {
        AnswerType.valid => 'VALID',
        AnswerType.blank => 'BLANK',
        AnswerType.multipleMark => 'MULTIPLE_MARK',
        AnswerType.inconsistent => 'INCONSISTENT',
      },
      if (value != null) 'value': value,
    };
  }

  factory AnswerStatus.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final value = json['value'] as String?;

    switch (typeStr) {
      case 'VALID':
        if (value == null || value.isEmpty) {
          throw FormatException(
            'AnswerStatus.fromJson: VALID type requires a non-null, non-empty value',
          );
        }
        return AnswerStatus.valid(value);
      case 'BLANK':
        return const AnswerStatus.blank();
      case 'MULTIPLE_MARK':
        return const AnswerStatus.multipleMark();
      case 'INCONSISTENT':
        return AnswerStatus.inconsistent(value ?? 'Unknown inconsistency');
      default:
        throw FormatException(
          'AnswerStatus.fromJson: Unknown type "$typeStr"',
        );
    }
  }

  @override
  List<Object?> get props => [value, type];
}
