import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  // Create 800x1100 white canvas
  final image = img.Image(width: 800, height: 1100);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));

  // Define colors
  final black = img.ColorRgb8(0, 0, 0);
  final lineColor = img.ColorRgb8(100, 100, 100);

  // Draw 4 corner markers (50x50 black squares, 20px from edges)
  // Top-left
  img.fillRect(image, x1: 20, y1: 20, x2: 70, y2: 70, color: black);
  // Top-right
  img.fillRect(image, x1: 730, y1: 20, x2: 780, y2: 70, color: black);
  // Bottom-right
  img.fillRect(image, x1: 730, y1: 1030, x2: 780, y2: 1080, color: black);
  // Bottom-left
  img.fillRect(image, x1: 20, y1: 1030, x2: 70, y2: 1080, color: black);

  // Draw "Name:" text region at top (y: 100-200)
  // Draw a horizontal line for name
  img.drawLine(image, x1: 150, y1: 150, x2: 650, y2: 150, color: lineColor, thickness: 2);

  // Draw text "Name:" (we'll draw it as simple pixels for the word)
  drawText(image, 'Name:', 100, 145, black);

  // Draw question numbers and bubbles
  final bubblePositions = [
    {'q': 1, 'y': 300},
    {'q': 2, 'y': 360},
    {'q': 3, 'y': 420},
    {'q': 4, 'y': 480},
    {'q': 5, 'y': 540},
  ];

  final options = ['A', 'B', 'C', 'D', 'E'];
  final bubbleXPositions = [150, 200, 250, 300, 350];

  for (final question in bubblePositions) {
    final qNum = question['q'] as int;
    final y = question['y'] as int;

    // Draw question number
    drawText(image, '$qNum.', 100, y + 10, black);

    // Draw bubbles (empty circles with thin black outline)
    for (int i = 0; i < 5; i++) {
      final x = bubbleXPositions[i];
      drawCircle(image, x + 15, y + 15, 14, lineColor, filled: false);

      // Draw option label above bubble
      drawText(image, options[i], x + 10, y - 5, black);
    }
  }

  // Save to assets folder
  final pngBytes = img.encodePng(image);
  final file = File('assets/test_sheet_blank.png');
  file.writeAsBytesSync(pngBytes);

  print('test_sheet_blank.png created successfully (800x1100 pixels)');
}

void drawCircle(img.Image image, int cx, int cy, int radius, img.Color color, {bool filled = false}) {
  if (filled) {
    img.fillCircle(image, x: cx, y: cy, radius: radius, color: color);
  } else {
    // Draw circle outline
    img.drawCircle(image, x: cx, y: cy, radius: radius, color: color);
  }
}

void drawText(img.Image image, String text, int x, int y, img.Color color) {
  // Simple text rendering using built-in font
  img.drawString(image, text, font: img.arial14, x: x, y: y, color: color);
}
