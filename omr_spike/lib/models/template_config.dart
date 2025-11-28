// Template configuration for OMR test sheets
// These dimensions define the reference size after perspective warp

import 'dart:ui';

// Template dimensions (pixels) - approximately A4 ratio
const kTemplateWidth = 800;
const kTemplateHeight = 1100;

// Corner marker size (pixels)
const kMarkerSize = 50;

// Bubble dimensions (pixels)
const kBubbleWidth = 30.0;
const kBubbleHeight = 30.0;

// Bubble positions relative to warped template (800x1100)
// Each question has 5 bubbles: A, B, C, D, E
// Format: Rect(left, top, width, height)
const kBubblePositions = {
  'q1': [
    Rect.fromLTWH(150.0, 300.0, kBubbleWidth, kBubbleHeight), // A
    Rect.fromLTWH(200.0, 300.0, kBubbleWidth, kBubbleHeight), // B
    Rect.fromLTWH(250.0, 300.0, kBubbleWidth, kBubbleHeight), // C
    Rect.fromLTWH(300.0, 300.0, kBubbleWidth, kBubbleHeight), // D
    Rect.fromLTWH(350.0, 300.0, kBubbleWidth, kBubbleHeight), // E
  ],
  'q2': [
    Rect.fromLTWH(150.0, 360.0, kBubbleWidth, kBubbleHeight), // A
    Rect.fromLTWH(200.0, 360.0, kBubbleWidth, kBubbleHeight), // B
    Rect.fromLTWH(250.0, 360.0, kBubbleWidth, kBubbleHeight), // C
    Rect.fromLTWH(300.0, 360.0, kBubbleWidth, kBubbleHeight), // D
    Rect.fromLTWH(350.0, 360.0, kBubbleWidth, kBubbleHeight), // E
  ],
  'q3': [
    Rect.fromLTWH(150.0, 420.0, kBubbleWidth, kBubbleHeight), // A
    Rect.fromLTWH(200.0, 420.0, kBubbleWidth, kBubbleHeight), // B
    Rect.fromLTWH(250.0, 420.0, kBubbleWidth, kBubbleHeight), // C
    Rect.fromLTWH(300.0, 420.0, kBubbleWidth, kBubbleHeight), // D
    Rect.fromLTWH(350.0, 420.0, kBubbleWidth, kBubbleHeight), // E
  ],
  'q4': [
    Rect.fromLTWH(150.0, 480.0, kBubbleWidth, kBubbleHeight), // A
    Rect.fromLTWH(200.0, 480.0, kBubbleWidth, kBubbleHeight), // B
    Rect.fromLTWH(250.0, 480.0, kBubbleWidth, kBubbleHeight), // C
    Rect.fromLTWH(300.0, 480.0, kBubbleWidth, kBubbleHeight), // D
    Rect.fromLTWH(350.0, 480.0, kBubbleWidth, kBubbleHeight), // E
  ],
  'q5': [
    Rect.fromLTWH(150.0, 540.0, kBubbleWidth, kBubbleHeight), // A
    Rect.fromLTWH(200.0, 540.0, kBubbleWidth, kBubbleHeight), // B
    Rect.fromLTWH(250.0, 540.0, kBubbleWidth, kBubbleHeight), // C
    Rect.fromLTWH(300.0, 540.0, kBubbleWidth, kBubbleHeight), // D
    Rect.fromLTWH(350.0, 540.0, kBubbleWidth, kBubbleHeight), // E
  ],
};

// Test sheet answers (for verification during testing)
// These are the answers filled in test_sheet_filled.png
const kTestSheetAnswers = {
  'q1': 'B',
  'q2': 'A',
  'q3': 'D',
  'q4': 'C',
  'q5': 'E',
};
