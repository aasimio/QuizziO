import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  // Load the blank test sheet
  final blankFile = File('assets/test_sheet_blank.png');
  final blankBytes = blankFile.readAsBytesSync();
  final image = img.decodePng(blankBytes)!;

  // Define filled color (dark gray/black for pencil mark)
  final filledColor = img.ColorRgb8(40, 40, 40);

  // Define which bubbles to fill
  // Q1: B, Q2: A, Q3: D, Q4: C, Q5: E
  final answers = {
    'q1': 1, // B (index 1)
    'q2': 0, // A (index 0)
    'q3': 3, // D (index 3)
    'q4': 2, // C (index 2)
    'q5': 4, // E (index 4)
  };

  final bubblePositions = [
    {'q': 'q1', 'y': 300},
    {'q': 'q2', 'y': 360},
    {'q': 'q3', 'y': 420},
    {'q': 'q4', 'y': 480},
    {'q': 'q5', 'y': 540},
  ];

  final bubbleXPositions = [150, 200, 250, 300, 350];

  // Fill the selected bubbles
  for (final question in bubblePositions) {
    final qKey = question['q'] as String;
    final y = question['y'] as int;
    final answerIndex = answers[qKey]!;

    final x = bubbleXPositions[answerIndex];

    // Fill circle at (x+15, y+15) with radius 13
    img.fillCircle(image, x: x + 15, y: y + 15, radius: 13, color: filledColor);
  }

  // Save to assets folder
  final pngBytes = img.encodePng(image);
  final file = File('assets/test_sheet_filled.png');
  file.writeAsBytesSync(pngBytes);

  print('test_sheet_filled.png created successfully');
  print('Filled answers: Q1=B, Q2=A, Q3=D, Q4=C, Q5=E');
}
