import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:quizzio/core/constants/omr_constants.dart';
import 'package:quizzio/features/omr/domain/entities/field_block.dart';
import 'package:quizzio/features/omr/domain/entities/omr_template.dart';

void main(List<String> args) async {
  final templatePath =
      args.isNotEmpty ? args[0] : 'assets/templates/template_10q.json';
  final outputBase =
      args.length > 1 ? args[1] : 'assets/sheets/answer_sheet_10q';
  final markerSizeOverride = _parseIntArg(args, '--marker-size');
  final markerPaddingOverride = _parseIntArg(args, '--marker-padding');

  final templateJson = _loadTemplateJson(templatePath);
  final markerConfig = templateJson['markerConfig'] as Map<String, dynamic>?;
  final configMarkerSize = _readInt(markerConfig?['sizePx']);
  final configMarkerPadding = _readInt(markerConfig?['paddingPx']);
  final template = OmrTemplate.fromJson(templateJson);

  final markerSizePx = markerSizeOverride ??
      configMarkerSize ??
      OmrConstants.markerSizePx;
  final markerPaddingPx = markerPaddingOverride ??
      configMarkerPadding ??
      OmrConstants.markerPaddingPx;

  final outputDir = File(outputBase).parent;
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final sheet = _buildSheet(
    template,
    markerSizePx: markerSizePx,
    markerPaddingPx: markerPaddingPx,
  );
  final pngBytes = img.encodePng(sheet, level: 6);

  final pngPath = '$outputBase.png';
  File(pngPath).writeAsBytesSync(pngBytes);

  final pdfBytes = await _buildPdf(pngBytes, template);
  final pdfPath = '$outputBase.pdf';
  File(pdfPath).writeAsBytesSync(pdfBytes);

  stdout.writeln('Generated: $pngPath');
  stdout.writeln('Generated: $pdfPath');
}

int? _parseIntArg(List<String> args, String name) {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == name && i + 1 < args.length) {
      return int.tryParse(args[i + 1]);
    }
    if (arg.startsWith('$name=')) {
      return int.tryParse(arg.substring(name.length + 1));
    }
  }
  return null;
}

Map<String, dynamic> _loadTemplateJson(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

img.Image _buildSheet(
  OmrTemplate template, {
  required int markerSizePx,
  required int markerPaddingPx,
}) {
  final sheet =
      img.Image(width: template.pageWidth, height: template.pageHeight);
  img.fill(sheet, color: img.ColorRgb8(255, 255, 255));

  _drawMarkers(sheet, markerSizePx, markerPaddingPx);
  _drawHeader(sheet, template, markerSizePx, markerPaddingPx);
  _drawNameRegion(sheet, template);
  _drawBubbles(sheet, template);

  return sheet;
}

void _drawMarkers(img.Image sheet, int markerSize, int markerPadding) {
  final markerPaths = [
    'assets/templates/aruco_0.png',
    'assets/templates/aruco_1.png',
    'assets/templates/aruco_2.png',
    'assets/templates/aruco_3.png',
  ];

  final markers =
      markerPaths.map((path) => _loadMarker(path, markerSize)).toList();

  final width = sheet.width;
  final height = sheet.height;

  img.compositeImage(sheet, markers[0],
      dstX: markerPadding, dstY: markerPadding, blend: img.BlendMode.direct);
  img.compositeImage(sheet, markers[1],
      dstX: width - markerSize - markerPadding,
      dstY: markerPadding,
      blend: img.BlendMode.direct);
  img.compositeImage(sheet, markers[2],
      dstX: width - markerSize - markerPadding,
      dstY: height - markerSize - markerPadding,
      blend: img.BlendMode.direct);
  img.compositeImage(sheet, markers[3],
      dstX: markerPadding,
      dstY: height - markerSize - markerPadding,
      blend: img.BlendMode.direct);
}

img.Image _loadMarker(String path, int size) {
  final decoded = img.decodePng(File(path).readAsBytesSync());
  if (decoded == null) {
    throw StateError('Failed to decode marker image: $path');
  }
  final rgbMarker = decoded.numChannels == 1
      ? decoded.convert(numChannels: 3)
      : decoded;
  if (decoded.width == size && decoded.height == size) {
    return rgbMarker;
  }
  return img.copyResize(
    rgbMarker,
    width: size,
    height: size,
    interpolation: img.Interpolation.nearest,
  );
}

void _drawHeader(
  img.Image sheet,
  OmrTemplate template,
  int markerSize,
  int markerPadding,
) {
  final font = img.arial48;
  final text = 'QuizziO OMR - ${template.questionCount} Questions';
  final textWidth = _measureTextWidth(font, text);
  final x = (sheet.width - textWidth) ~/ 2;
  final y = math.max(
    10,
    markerPadding + ((markerSize - font.lineHeight) ~/ 2),
  );
  img.drawString(sheet,
      text, font: font, x: x, y: y, color: img.ColorRgb8(0, 0, 0));
}

void _drawNameRegion(img.Image sheet, OmrTemplate template) {
  final font = img.arial24;
  final textX = template.nameRegionX;
  final textY = template.nameRegionY + 20;
  final lineY = template.nameRegionY + template.nameRegionHeight - 40;
  final lineStartX = template.nameRegionX + 160;
  final lineEndX = template.nameRegionX + template.nameRegionWidth;

  final lineColor = img.ColorRgb8(80, 80, 80);

  img.drawString(sheet,
      'Name:', font: font, x: textX, y: textY, color: img.ColorRgb8(0, 0, 0));
  img.drawLine(sheet,
      x1: lineStartX,
      y1: lineY,
      x2: lineEndX,
      y2: lineY,
      color: lineColor,
      thickness: 2);
}

void _drawBubbles(img.Image sheet, OmrTemplate template) {
  final bubbleWidth = template.bubbleWidth;
  final bubbleHeight = template.bubbleHeight;
  final outlineColor = img.ColorRgb8(50, 50, 50);
  final backgroundColor = img.ColorRgb8(255, 255, 255);
  final labelFont = img.arial24;

  for (final block in template.fieldBlocks) {
    final isHorizontal = block.direction.toLowerCase() == 'horizontal';

    if (isHorizontal) {
      _drawOptionLabelsHorizontal(
          sheet, block, bubbleWidth, bubbleHeight, labelFont);
      _drawQuestionLabelsHorizontal(
          sheet, block, bubbleWidth, bubbleHeight, labelFont);
    } else {
      _drawOptionLabelsVertical(
          sheet, block, bubbleWidth, bubbleHeight, labelFont);
      _drawQuestionLabelsVertical(
          sheet, block, bubbleWidth, bubbleHeight, labelFont);
    }

    for (var qIdx = 0; qIdx < block.questionLabels.length; qIdx++) {
      for (var optIdx = 0; optIdx < block.options.length; optIdx++) {
        final bubbleX = isHorizontal
            ? block.originX +
                (optIdx * (bubbleWidth + block.bubblesGap))
            : block.originX +
                (qIdx * (bubbleWidth + block.bubblesGap));
        final bubbleY = isHorizontal
            ? block.originY +
                (qIdx * (bubbleHeight + block.labelsGap))
            : block.originY +
                (optIdx * (bubbleHeight + block.labelsGap));

        _drawBubbleRing(sheet, bubbleX, bubbleY, bubbleWidth, bubbleHeight,
            outlineColor, backgroundColor);
      }
    }
  }
}

void _drawOptionLabelsVertical(
  img.Image sheet,
  FieldBlock block,
  int bubbleWidth,
  int bubbleHeight,
  img.BitmapFont font,
) {
  final labelX = block.originX - 60;
  for (var optIdx = 0; optIdx < block.options.length; optIdx++) {
    final bubbleY = block.originY + (optIdx * (bubbleHeight + block.labelsGap));
    final labelY = bubbleY + (bubbleHeight - font.lineHeight) ~/ 2;
    img.drawString(
      sheet,
      block.options[optIdx],
      font: font,
      x: labelX,
      y: labelY,
      color: img.ColorRgb8(0, 0, 0),
    );
  }
}

void _drawQuestionLabelsVertical(
  img.Image sheet,
  FieldBlock block,
  int bubbleWidth,
  int bubbleHeight,
  img.BitmapFont font,
) {
  final baseY = block.originY - (block.labelsGap ~/ 2) - (font.lineHeight ~/ 2);
  final labelY = math.max(10, baseY);

  for (var qIdx = 0; qIdx < block.questionLabels.length; qIdx++) {
    final label = _formatQuestionLabel(block.questionLabels[qIdx]);
    final bubbleX = block.originX + (qIdx * (bubbleWidth + block.bubblesGap));
    final textWidth = _measureTextWidth(font, label);
    final labelX = bubbleX + (bubbleWidth ~/ 2) - (textWidth ~/ 2);
    img.drawString(
      sheet,
      label,
      font: font,
      x: labelX,
      y: labelY,
      color: img.ColorRgb8(0, 0, 0),
    );
  }
}

void _drawOptionLabelsHorizontal(
  img.Image sheet,
  FieldBlock block,
  int bubbleWidth,
  int bubbleHeight,
  img.BitmapFont font,
) {
  final baseY = block.originY - (block.labelsGap ~/ 2) - (font.lineHeight ~/ 2);
  final labelY = math.max(10, baseY);

  for (var optIdx = 0; optIdx < block.options.length; optIdx++) {
    final bubbleX = block.originX + (optIdx * (bubbleWidth + block.bubblesGap));
    final label = block.options[optIdx];
    final textWidth = _measureTextWidth(font, label);
    final labelX = bubbleX + (bubbleWidth ~/ 2) - (textWidth ~/ 2);
    img.drawString(
      sheet,
      label,
      font: font,
      x: labelX,
      y: labelY,
      color: img.ColorRgb8(0, 0, 0),
    );
  }
}

void _drawQuestionLabelsHorizontal(
  img.Image sheet,
  FieldBlock block,
  int bubbleWidth,
  int bubbleHeight,
  img.BitmapFont font,
) {
  final labelX = block.originX - 60;

  for (var qIdx = 0; qIdx < block.questionLabels.length; qIdx++) {
    final label = _formatQuestionLabel(block.questionLabels[qIdx]);
    final bubbleY = block.originY + (qIdx * (bubbleHeight + block.labelsGap));
    final labelY = bubbleY + (bubbleHeight - font.lineHeight) ~/ 2;
    img.drawString(
      sheet,
      label,
      font: font,
      x: labelX,
      y: labelY,
      color: img.ColorRgb8(0, 0, 0),
    );
  }
}

void _drawBubbleRing(
  img.Image sheet,
  int x,
  int y,
  int width,
  int height,
  img.Color outline,
  img.Color background,
) {
  final centerX = x + (width ~/ 2);
  final centerY = y + (height ~/ 2);
  final outerRadius = (math.min(width, height) ~/ 2) - 2;
  final innerRadius = outerRadius - 3;
  if (innerRadius <= 0) {
    return;
  }

  img.fillCircle(sheet,
      x: centerX, y: centerY, radius: outerRadius, color: outline);
  img.fillCircle(sheet,
      x: centerX, y: centerY, radius: innerRadius, color: background);
}

String _formatQuestionLabel(String label) {
  final match = RegExp(r'^[qQ](\d+)$').firstMatch(label);
  return match?.group(1) ?? label;
}

int _measureTextWidth(img.BitmapFont font, String text) {
  var width = 0;
  for (final rune in text.runes) {
    width += font.characters[rune]?.xAdvance ?? (font.base ~/ 2);
  }
  return width;
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

Future<List<int>> _buildPdf(
  List<int> pngBytes,
  OmrTemplate template,
) async {
  final document = pw.Document();
  final pageWidthInches = template.pageWidth / template.pageDpi;
  final pageHeightInches = template.pageHeight / template.pageDpi;
  final format = PdfPageFormat(
    pageWidthInches * PdfPageFormat.inch,
    pageHeightInches * PdfPageFormat.inch,
  );

  final image = pw.MemoryImage(Uint8List.fromList(pngBytes));
  document.addPage(
    pw.Page(
      pageFormat: format,
      build: (context) => pw.Center(
        child: pw.Image(image, fit: pw.BoxFit.fill),
      ),
    ),
  );

  return document.save();
}
