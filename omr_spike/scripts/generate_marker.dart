import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  // Create a 50x50 solid black square
  final image = img.Image(width: 50, height: 50);

  // Fill with black color
  img.fill(image, color: img.ColorRgb8(0, 0, 0));

  // Save to assets folder
  final pngBytes = img.encodePng(image);
  final file = File('assets/marker.png');
  file.writeAsBytesSync(pngBytes);

  print('marker.png created successfully (50x50 pixels, solid black)');
}
