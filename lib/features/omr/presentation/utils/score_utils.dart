import 'package:flutter/material.dart';

const Color _scoreHighColor = Color(0xFF4ECDC4);
const Color _scoreLowColor = Color(0xFFFF6B6B);

Color getScoreColor(double percentage) {
  if (percentage >= 0.8) return _scoreHighColor;
  if (percentage >= 0.5) return Colors.amber;
  return _scoreLowColor;
}
