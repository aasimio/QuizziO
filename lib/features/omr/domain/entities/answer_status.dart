import 'package:equatable/equatable.dart';

enum AnswerType { valid, blank, multipleMark }

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

  bool get isValid => type == AnswerType.valid;
  bool get isBlank => type == AnswerType.blank;
  bool get isMultipleMark => type == AnswerType.multipleMark;

  String toJson() {
    switch (type) {
      case AnswerType.valid:
        return 'VALID';
      case AnswerType.blank:
        return 'BLANK';
      case AnswerType.multipleMark:
        return 'MULTIPLE_MARK';
    }
  }

  factory AnswerStatus.fromJson(String json, String? value) {
    switch (json) {
      case 'VALID':
        return AnswerStatus.valid(value ?? '');
      case 'BLANK':
        return const AnswerStatus.blank();
      case 'MULTIPLE_MARK':
        return const AnswerStatus.multipleMark();
      default:
        return const AnswerStatus.blank();
    }
  }

  @override
  List<Object?> get props => [value, type];
}
