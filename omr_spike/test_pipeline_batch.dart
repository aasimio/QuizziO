#!/usr/bin/env dart
/// Batch test script to run OMR pipeline on all gallery test images
/// and record results for validation.
///
/// Run with: dart run test_pipeline_batch.dart

import 'dart:io';
import 'package:omr_spike/omr_pipeline.dart';
import 'package:omr_spike/models/template_config.dart';
import 'package:omr_spike/services/threshold_calculator.dart';

Future<void> main() async {
  print('🔬 OMR Pipeline Batch Test\n');
  print('=' * 80);

  // Gallery images to test
  final testImages = [
    '01_original.png',
    '02_rotated_10deg.png',
    '03_rotated_minus15deg.png',
    '04_dim_lighting.png',
    '05_bright_lighting.png',
    '06_noisy.png',
    '07_rotated_dim.png',
  ];

  // Expected answers for validation
  final expectedAnswers = kTestSheetAnswers;

  // Create pipeline
  final pipeline = OmrPipeline();

  // Load marker template
  print('\n📌 Loading marker template...');
  final markerFile = File('assets/marker.png');
  if (!await markerFile.exists()) {
    print('❌ Error: Marker template not found at assets/marker.png');
    exit(1);
  }
  final markerBytes = await markerFile.readAsBytes();
  await pipeline.loadMarkerTemplate(markerBytes);
  print('✅ Marker template loaded\n');

  // Results table
  final results = <Map<String, dynamic>>[];

  // Process each test image
  for (final imageName in testImages) {
    print('\n' + '-' * 80);
    print('Testing: $imageName');
    print('-' * 80);

    final imagePath = 'assets/gallery/$imageName';
    final imageFile = File(imagePath);

    if (!await imageFile.exists()) {
      print('⚠️  File not found: $imagePath\n   Skipping...');
      results.add({
        'image': imageName,
        'success': false,
        'error': 'File not found',
        'markers_found': 'N/A',
        'confidence': 'N/A',
        'correct': 'N/A',
        'time_ms': 'N/A',
      });
      continue;
    }

    try {
      // Load image
      final imageBytes = await imageFile.readAsBytes();

      // Run pipeline
      final result = await pipeline.process(imageBytes);

      if (!result.success) {
        print('❌ Pipeline failed: ${result.errorMessage}');
        results.add({
          'image': imageName,
          'success': false,
          'error': result.errorMessage,
          'markers_found':
              result.markerResult != null ? '${result.markerResult!.perMarkerConfidence.where((c) => c >= 0.3).length}/4' : 'N/A',
          'confidence': result.markerResult != null
              ? '${(result.markerResult!.avgConfidence * 100).toStringAsFixed(1)}%'
              : 'N/A',
          'correct': 'N/A',
          'time_ms': result.processingTimeMs,
        });
        continue;
      }

      // Validate results
      final answers = result.answers!;
      var correctCount = 0;
      var totalCount = 0;

      for (final entry in answers.entries) {
        final questionKey = entry.key;
        final extractedAnswer = entry.value;

        if (extractedAnswer.status == AnswerStatus.valid) {
          totalCount++;
          final expected = expectedAnswers[questionKey];
          if (extractedAnswer.value == expected) {
            correctCount++;
          }
        }
      }

      final accuracy = totalCount > 0 ? (correctCount / totalCount * 100) : 0.0;

      // Calculate actual detected markers (confidence >= 0.3 threshold)
      const expectedMarkers = 4;
      final detectedMarkers = result.markerResult!.perMarkerConfidence.where((c) => c >= 0.3).length;
      final markerCountStr = '$detectedMarkers/$expectedMarkers';

      print('✅ Success!');
      print('   Markers: $markerCountStr found');
      print('   Confidence: ${(result.markerResult!.avgConfidence * 100).toStringAsFixed(1)}%');
      print('   Answers: $correctCount/$totalCount correct (${accuracy.toStringAsFixed(1)}%)');
      print('   Time: ${result.processingTimeMs}ms');

      results.add({
        'image': imageName,
        'success': true,
        'error': null,
        'markers_found': markerCountStr,
        'confidence': '${(result.markerResult!.avgConfidence * 100).toStringAsFixed(1)}%',
        'correct': '$correctCount/$totalCount',
        'accuracy': accuracy,
        'time_ms': result.processingTimeMs,
        'threshold': result.thresholdResult!.threshold.toStringAsFixed(1),
        'threshold_confidence':
            '${(result.thresholdResult!.confidence * 100).toStringAsFixed(1)}%',
      });
    } catch (e, stackTrace) {
      print('❌ Exception: $e');
      print('   Stack trace: $stackTrace');
      results.add({
        'image': imageName,
        'success': false,
        'error': e.toString(),
        'markers_found': 'N/A',
        'confidence': 'N/A',
        'correct': 'N/A',
        'time_ms': 'N/A',
      });
    }
  }

  // Dispose pipeline
  pipeline.dispose();

  // Print results table
  print('\n\n' + '=' * 80);
  print('📊 BATCH TEST RESULTS');
  print('=' * 80);
  print('');

  // Table header
  print('| Image                     | Markers | Confidence | Correct | Time    | Status |');
  print('|---------------------------|---------|------------|---------|---------|--------|');

  // Table rows
  for (final result in results) {
    final image = result['image'].toString().padRight(25);
    final markers = result['markers_found'].toString().padRight(7);
    final confidence = result['confidence'].toString().padRight(10);
    final correct = result['correct'].toString().padRight(7);
    final time = result['time_ms'].toString().padRight(7);
    final status = result['success'] ? '  ✅   ' : '  ❌   ';

    print('| $image | $markers | $confidence | $correct | ${time}ms | $status |');
  }

  print('');

  // Calculate overall metrics
  final successfulResults = results.where((r) => r['success'] == true).toList();
  final successRate =
      (successfulResults.length / results.length * 100).toStringAsFixed(1);

  // Calculate metrics that will be reused in Go/No-Go assessment
  final avgTime = successfulResults.isNotEmpty
      ? successfulResults
              .map((r) => r['time_ms'] as int)
              .reduce((a, b) => a + b) /
          successfulResults.length
      : 0.0;

  final accuracies = successfulResults
      .where((r) => r['accuracy'] != null)
      .map((r) => r['accuracy'] as double)
      .toList();

  final avgAccuracy =
      accuracies.isNotEmpty ? accuracies.reduce((a, b) => a + b) / accuracies.length : 0.0;

  // Calculate marker detection rate from actual results
  var totalDetectedMarkers = 0;
  var totalExpectedMarkers = 0;

  for (final r in successfulResults) {
    final markersFound = r['markers_found'] as String;
    // Parse "X/Y" format to get detected count
    final parts = markersFound.split('/');
    if (parts.length == 2) {
      totalDetectedMarkers += int.tryParse(parts[0]) ?? 0;
      totalExpectedMarkers += int.tryParse(parts[1]) ?? 0;
    }
  }

  final markerDetectionPct = totalExpectedMarkers > 0
      ? (totalDetectedMarkers / totalExpectedMarkers * 100)
      : 0.0;

  print('\n📈 OVERALL METRICS:');
  print('-' * 80);
  print('Total images tested: ${results.length}');
  print('Successful: ${successfulResults.length}/${results.length} ($successRate%)');

  if (successfulResults.isNotEmpty) {
    print('Average processing time: ${avgTime.toStringAsFixed(0)}ms');
    print('Average answer accuracy: ${avgAccuracy.toStringAsFixed(1)}%');
    print('Marker detection rate: ${markerDetectionPct.toStringAsFixed(1)}% ($totalDetectedMarkers/$totalExpectedMarkers markers)');
  }

  print('');
  print('=' * 80);
  print('');

  // Go/No-Go assessment
  print('\n🎯 GO/NO-GO ASSESSMENT:');
  print('-' * 80);

  // Reuse already-computed metrics (safe, no risk of StateError)
  final markerDetectionRate = successRate;
  final bubbleAccuracy = avgAccuracy;
  final avgProcessingTime = avgTime;

  print('');
  print('| Criteria                | Target   | Actual                           | Pass? |');
  print('|-------------------------|----------|----------------------------------|-------|');
  print('| Markers detected        | >90%     | $successRate%                           | ${double.parse(successRate) > 90 ? '  ✅  ' : '  ❌  '} |');
  print('| Bubble accuracy         | >95%     | ${bubbleAccuracy.toStringAsFixed(1)}%                          | ${bubbleAccuracy > 95 ? '  ✅  ' : '  ❌  '} |');
  print('| Processing time         | <500ms   | ${avgProcessingTime.toStringAsFixed(0)}ms                           | ${avgProcessingTime < 500 ? '  ✅  ' : '  ❌  '} |');
  print('');

  // Final decision
  final passMarkers = double.parse(successRate) > 90;
  final passAccuracy = bubbleAccuracy > 95;
  final passTime = avgProcessingTime < 500;

  if (passMarkers && passAccuracy && passTime) {
    print('✅ DECISION: GO');
    print('   All criteria met. opencv_dart is suitable for OMR processing.');
  } else if (passMarkers && bubbleAccuracy > 80) {
    print('⚠️  DECISION: CONDITIONAL GO');
    print('   Core functionality works but some criteria not met.');
    print('   Consider parameter tuning or accept slightly lower thresholds.');
  } else {
    print('❌ DECISION: NO-GO');
    print('   Critical failures detected. opencv_dart may not be suitable.');
  }

  print('');
  print('=' * 80);
  print('\n✅ Batch test complete!\n');
}
