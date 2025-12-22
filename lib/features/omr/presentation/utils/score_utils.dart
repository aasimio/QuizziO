import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

const Color _scoreHighColor = AppColors.detection;
const Color _scoreLowColor = AppColors.error;

Color getScoreColor(double percentage) {
  if (percentage >= 0.8) return _scoreHighColor;
  if (percentage >= 0.5) return Colors.amber;
  return _scoreLowColor;
}
