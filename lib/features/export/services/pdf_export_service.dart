import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../quiz/domain/entities/quiz.dart';
import '../../omr/domain/entities/scan_result.dart';

/// Exception thrown when PDF export operations fail.
class PdfExportException implements Exception {
  final String message;
  final Object? cause;

  PdfExportException(this.message, [this.cause]);

  @override
  String toString() =>
      'PdfExportException: $message${cause != null ? ' ($cause)' : ''}';
}

/// Data transfer object for passing quiz data to compute isolate.
class _PdfGenerationParams {
  final String quizName;
  final DateTime quizCreatedAt;
  final List<_ScanResultData> results;

  _PdfGenerationParams({
    required this.quizName,
    required this.quizCreatedAt,
    required this.results,
  });
}

/// Simplified scan result data for isolate serialization.
class _ScanResultData {
  final Uint8List nameRegionImage;
  final int score;
  final int total;
  final double percentage;

  _ScanResultData({
    required this.nameRegionImage,
    required this.score,
    required this.total,
    required this.percentage,
  });
}

/// Top-level function for compute() - generates PDF bytes in isolate.
Future<Uint8List> _generatePdfInIsolate(_PdfGenerationParams params) async {
  const nameImageMaxWidth = 200.0;
  const nameImageMaxHeight = 50.0;
  const resultsPerPage = 8;

  final pdf = pw.Document();
  final dateFormat = DateFormat('MMMM d, yyyy');

  // Calculate average percentage
  final average = params.results.isEmpty
      ? 0.0
      : params.results.fold(0.0, (sum, r) => sum + r.percentage) /
          params.results.length;

  // Paginate results
  final totalPages = params.results.isEmpty
      ? 1
      : (params.results.length / resultsPerPage).ceil();

  for (var pageIndex = 0; pageIndex < totalPages; pageIndex++) {
    final startIndex = pageIndex * resultsPerPage;
    final endIndex = (startIndex + resultsPerPage < params.results.length)
        ? startIndex + resultsPerPage
        : params.results.length;
    final pageResults = params.results.isEmpty
        ? <_ScanResultData>[]
        : params.results.sublist(startIndex, endIndex);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header (only on first page)
              if (pageIndex == 0) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Quiz: ${params.quizName}',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Date: ${dateFormat.format(params.quizCreatedAt)}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Students: ${params.results.length}'),
                          pw.Text('Average: ${average.toStringAsFixed(1)}%'),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
              ],

              // Column headers
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey600, width: 2),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 30,
                      child: pw.Text(
                        '#',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        'Student Name',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Text(
                      'Score',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // Student rows
              ...pageResults.asMap().entries.map((entry) {
                final globalIndex = startIndex + entry.key;
                final result = entry.value;

                // Build name image widget
                pw.Widget nameImageWidget;
                if (result.nameRegionImage.isEmpty) {
                  nameImageWidget = pw.Container(
                    width: nameImageMaxWidth,
                    height: 30,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        '[No name captured]',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ),
                  );
                } else {
                  try {
                    final image = pw.MemoryImage(result.nameRegionImage);
                    nameImageWidget = pw.Container(
                      constraints: pw.BoxConstraints(
                        maxWidth: nameImageMaxWidth,
                        maxHeight: nameImageMaxHeight,
                      ),
                      child: pw.Image(image, fit: pw.BoxFit.contain),
                    );
                  } catch (_) {
                    // Handle invalid image data gracefully
                    nameImageWidget = pw.Container(
                      width: nameImageMaxWidth,
                      height: 30,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          '[Invalid image]',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ),
                    );
                  }
                }

                return pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Index
                      pw.SizedBox(
                        width: 30,
                        child: pw.Text(
                          '${globalIndex + 1}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      // Name image
                      pw.Expanded(child: nameImageWidget),
                      // Score (right-aligned)
                      pw.Text(
                        '${result.score}/${result.total} (${result.percentage.toStringAsFixed(0)}%)',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),

              pw.Spacer(),

              // Footer with page number only (no branding per PRD)
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Page ${pageIndex + 1} of $totalPages',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  return pdf.save();
}

/// Service for generating PDF reports from quiz results.
///
/// Generates offline PDFs with quiz metadata, student name images,
/// and scores. Uses compute() for off-main-thread generation.
@lazySingleton
class PdfExportService {
  /// Generates a PDF containing quiz results.
  ///
  /// [quiz] - The quiz entity with name and metadata.
  /// [results] - List of scan results to include in the report.
  ///
  /// Returns PDF bytes as Uint8List.
  /// Throws [PdfExportException] on failure.
  Future<Uint8List> generateResultsPdf(
    Quiz quiz,
    List<ScanResult> results,
  ) async {
    try {
      // Sort results by scannedAt descending (most recent first)
      final sortedResults = List<ScanResult>.from(results)
        ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));

      // Convert to serializable DTOs for isolate
      final params = _PdfGenerationParams(
        quizName: quiz.name,
        quizCreatedAt: quiz.createdAt,
        results: sortedResults
            .map((r) => _ScanResultData(
                  nameRegionImage: r.nameRegionImage,
                  score: r.score,
                  total: r.total,
                  percentage: r.percentage,
                ))
            .toList(),
      );

      // Generate PDF off main thread
      return compute(_generatePdfInIsolate, params);
    } catch (e, stackTrace) {
      debugPrint('PdfExportService.generateResultsPdf failed: $e\n$stackTrace');
      throw PdfExportException('Failed to generate PDF', e);
    }
  }

  /// Saves PDF bytes to temporary directory.
  ///
  /// [pdfBytes] - The PDF data to save.
  /// [filename] - Name for the PDF file (should include .pdf extension).
  ///
  /// Returns the saved File.
  /// Throws [PdfExportException] on failure.
  Future<File> savePdf(Uint8List pdfBytes, String filename) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$filename';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // Verify file exists per CLAUDE.md
      if (!await file.exists()) {
        throw PdfExportException('PDF file was not created after write');
      }

      return file;
    } catch (e, stackTrace) {
      debugPrint('PdfExportService.savePdf failed: $e\n$stackTrace');
      if (e is PdfExportException) rethrow;
      throw PdfExportException('Failed to save PDF file', e);
    }
  }

  /// Shares PDF file via system share sheet.
  ///
  /// [pdfFile] - The PDF file to share.
  ///
  /// Throws [PdfExportException] if file doesn't exist or sharing fails.
  Future<void> sharePdf(File pdfFile) async {
    try {
      if (!await pdfFile.exists()) {
        throw PdfExportException('PDF file does not exist: ${pdfFile.path}');
      }

      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        subject: 'Quiz Results',
      );
    } catch (e, stackTrace) {
      debugPrint('PdfExportService.sharePdf failed: $e\n$stackTrace');
      if (e is PdfExportException) rethrow;
      throw PdfExportException('Failed to share PDF', e);
    }
  }

  /// Convenience method: generates PDF, saves to temp, and shares.
  ///
  /// [quiz] - The quiz entity.
  /// [results] - List of scan results.
  ///
  /// Throws [PdfExportException] on any failure.
  Future<void> exportAndShare(Quiz quiz, List<ScanResult> results) async {
    final pdfBytes = await generateResultsPdf(quiz, results);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'quiz_results_$timestamp.pdf';
    final file = await savePdf(pdfBytes, filename);
    await sharePdf(file);
  }
}
