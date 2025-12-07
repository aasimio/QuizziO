import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omr_spike/models/template_config.dart';
import 'package:omr_spike/omr_pipeline.dart';
import 'package:omr_spike/services/threshold_calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OMR Pipeline Batch Test', () {
    late OmrPipeline pipeline;

    setUp(() async {
      pipeline = OmrPipeline();

      // Load marker template
      final markerData = await rootBundle.load('assets/marker.png');
      await pipeline.loadMarkerTemplate(markerData.buffer.asUint8List());
    });

    tearDown(() {
      pipeline.dispose();
    });

    final testImages = [
      '01_original.png',
      '02_rotated_10deg.png',
      '03_rotated_minus15deg.png',
      '04_dim_lighting.png',
      '05_bright_lighting.png',
      '06_noisy.png',
      '07_rotated_dim.png',
    ];

    for (final imageName in testImages) {
      test('Process $imageName', () async {
        // Load image
        final imageData =
            await rootBundle.load('assets/gallery/$imageName');
        final imageBytes = imageData.buffer.asUint8List();

        // Run pipeline
        final result = await pipeline.process(imageBytes);

        // Print results
        print('\n${'=' * 80}');
        print('Image: $imageName');
        print('=' * 80);

        if (!result.success) {
          print('❌ Failed: ${result.errorMessage}');
          print('Time: ${result.processingTimeMs}ms');
          if (result.markerResult != null) {
            print('Markers found: ${result.markerResult!.perMarkerConfidence.where((c) => c >= 0.3).length}/4');
          }
        } else {
          print('✅ Success');
          print('Time: ${result.processingTimeMs}ms');
          print('Markers: 4/4 found');
          print('Confidence: ${(result.markerResult!.avgConfidence * 100).toStringAsFixed(1)}%');
          print('Threshold: ${result.thresholdResult!.threshold.toStringAsFixed(1)}');

          // Check answers
          final answers = result.answers!;
          var correctCount = 0;
          var totalValidAnswers = 0;

          for (final entry in answers.entries) {
            final question = entry.key;
            final answer = entry.value;
            final expected = kTestSheetAnswers[question];

            if (answer.status == AnswerStatus.valid) {
              totalValidAnswers++;
              if (answer.value == expected) {
                correctCount++;
              }
              print('  $question: ${answer.value} ${answer.value == expected ? '✅' : '❌ (expected: $expected)'}');
            } else if (answer.status == AnswerStatus.blank) {
              print('  $question: BLANK ⚪');
            } else {
              print('  $question: MULTIPLE MARKS ⚠️');
            }
          }

          final accuracy = totalValidAnswers > 0
              ? (correctCount / totalValidAnswers * 100)
              : 0.0;
          print('Accuracy: $correctCount/$totalValidAnswers (${accuracy.toStringAsFixed(1)}%)');
        }

        print('');

        // Assertions
        expect(result.success, isTrue,
            reason: '$imageName: Pipeline should succeed');
        expect(result.markerResult?.allMarkersFound, isTrue,
            reason: '$imageName: All 4 markers should be detected');
        expect(result.processingTimeMs, lessThan(500),
            reason: '$imageName: Processing should complete in <500ms');

        // Check answer accuracy
        if (result.answers != null) {
          var correctCount = 0;
          var totalCount = 0;

          for (final entry in result.answers!.entries) {
            if (entry.value.status == AnswerStatus.valid) {
              totalCount++;
              final expected = kTestSheetAnswers[entry.key];
              if (entry.value.value == expected) {
                correctCount++;
              }
            }
          }

          final accuracy = totalCount > 0 ? (correctCount / totalCount) : 0.0;
          expect(accuracy, greaterThanOrEqualTo(0.95),
              reason: '$imageName: Answer accuracy should be ≥95%');
        }
      }, timeout: const Timeout(Duration(seconds: 30)));
    }

    test('Batch test summary', () async {
      final results = <Map<String, dynamic>>[];

      for (final imageName in testImages) {
        // Load image
        final imageData =
            await rootBundle.load('assets/gallery/$imageName');
        final imageBytes = imageData.buffer.asUint8List();

        // Run pipeline
        final result = await pipeline.process(imageBytes);

        // Calculate accuracy
        var correctCount = 0;
        var totalCount = 0;

        if (result.answers != null) {
          for (final entry in result.answers!.entries) {
            if (entry.value.status == AnswerStatus.valid) {
              totalCount++;
              final expected = kTestSheetAnswers[entry.key];
              if (entry.value.value == expected) {
                correctCount++;
              }
            }
          }
        }

        results.add({
          'image': imageName,
          'success': result.success,
          'markers': result.markerResult?.allMarkersFound ?? false,
          'confidence':
              result.markerResult?.avgConfidence ?? 0.0,
          'correct': correctCount,
          'total': totalCount,
          'accuracy': totalCount > 0 ? (correctCount / totalCount) : 0.0,
          'time_ms': result.processingTimeMs,
        });
      }

      // Print summary table
      print('\n\n${'=' * 100}');
      print('BATCH TEST SUMMARY');
      print('=' * 100);
      print('');
      print('| Image                     | Markers | Confidence | Correct | Time    | Status |');
      print('|---------------------------|---------|------------|---------|---------|--------|');

      for (final r in results) {
        final image = (r['image'] as String).padRight(25);
        final markers = r['markers'] ? '  4/4  ' : '  <4   ';
        final confidence = '${((r['confidence'] as double) * 100).toStringAsFixed(1)}%'.padRight(10);
        final correct = '${r['correct']}/${r['total']}'.padRight(7);
        final time = '${r['time_ms']}'.padRight(7);
        final status = r['success'] ? '  ✅   ' : '  ❌   ';

        print('| $image | $markers | $confidence | $correct | ${time}ms | $status |');
      }

      print('');

      // Calculate overall metrics
      final successfulResults = results.where((r) => r['success'] == true).toList();
      final successRate = successfulResults.length / results.length;
      final avgTime = successfulResults.isNotEmpty
          ? successfulResults.map((r) => r['time_ms'] as int).reduce((a, b) => a + b) /
              successfulResults.length
          : 0.0;
      final avgAccuracy = successfulResults.isNotEmpty
          ? successfulResults.map((r) => r['accuracy'] as double).reduce((a, b) => a + b) /
              successfulResults.length
          : 0.0;

      print('OVERALL METRICS:');
      print('-' * 100);
      print('Total images: ${results.length}');
      print('Success rate: ${successfulResults.length}/${results.length} (${(successRate * 100).toStringAsFixed(1)}%)');
      print('Avg processing time: ${avgTime.toStringAsFixed(0)}ms');
      print('Avg answer accuracy: ${(avgAccuracy * 100).toStringAsFixed(1)}%');
      print('Marker detection: 100% (on successful runs)');
      print('');

      // Go/No-Go decision
      print('GO/NO-GO ASSESSMENT:');
      print('-' * 100);
      print('');
      print('| Criteria                | Target   | Actual                           | Pass? |');
      print('|-------------------------|----------|----------------------------------|-------|');
      print('| Markers detected        | >90%     | ${(successRate * 100).toStringAsFixed(1)}%                           | ${successRate > 0.9 ? '  ✅  ' : '  ❌  '} |');
      print('| Bubble accuracy         | >95%     | ${(avgAccuracy * 100).toStringAsFixed(1)}%                          | ${avgAccuracy > 0.95 ? '  ✅  ' : '  ❌  '} |');
      print('| Processing time         | <500ms   | ${avgTime.toStringAsFixed(0)}ms                           | ${avgTime < 500 ? '  ✅  ' : '  ❌  '} |');
      print('');

      final passMarkers = successRate > 0.9;
      final passAccuracy = avgAccuracy > 0.95;
      final passTime = avgTime < 500;

      if (passMarkers && passAccuracy && passTime) {
        print('✅ DECISION: GO');
        print('   All criteria met. opencv_dart is suitable for OMR processing.');
      } else if (passMarkers && avgAccuracy > 0.8) {
        print('⚠️  DECISION: CONDITIONAL GO');
        print('   Core functionality works but some criteria not met.');
      } else {
        print('❌ DECISION: NO-GO');
        print('   Critical failures detected.');
      }

      print('');
      print('=' * 100);
      print('');
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
