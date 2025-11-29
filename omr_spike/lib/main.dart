import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omr_spike/services/image_preprocessor.dart';
import 'package:omr_spike/services/marker_detector.dart';
import 'package:omr_spike/services/perspective_transformer.dart';
import 'package:omr_spike/services/bubble_reader.dart';
import 'package:omr_spike/models/template_config.dart';
import 'package:omr_spike/omr_pipeline.dart';
import 'package:omr_spike/services/threshold_calculator.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OMR Spike - Asset Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AssetTestPage(),
    );
  }
}

class AssetTestPage extends StatefulWidget {
  const AssetTestPage({super.key});

  @override
  State<AssetTestPage> createState() => _AssetTestPageState();
}

class _AssetTestPageState extends State<AssetTestPage> {
  String _statusMessage = 'Press button to test asset loading';
  bool _isLoading = false;
  final ImagePreprocessor _preprocessor = ImagePreprocessor();
  final MarkerDetector _markerDetector = MarkerDetector();
  final PerspectiveTransformer _perspectiveTransformer =
      PerspectiveTransformer();
  final BubbleReader _bubbleReader = BubbleReader();
  final OmrPipeline _pipeline = OmrPipeline();
  final ImagePicker _picker = ImagePicker();

  // Current loaded image for pipeline processing
  Uint8List? _currentImageBytes;
  String? _currentImageName;
  OmrResult? _pipelineResult;

  Future<void> _testAssetLoading() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing asset loading...';
    });

    try {
      // Test loading marker.png
      final markerData = await rootBundle.load('assets/marker.png');
      print('✓ Marker loaded: ${markerData.lengthInBytes} bytes');

      // Test loading test_sheet_blank.png
      final blankData = await rootBundle.load('assets/test_sheet_blank.png');
      print('✓ Blank sheet loaded: ${blankData.lengthInBytes} bytes');

      // Test loading test_sheet_filled.png
      final filledData = await rootBundle.load('assets/test_sheet_filled.png');
      print('✓ Filled sheet loaded: ${filledData.lengthInBytes} bytes');

      setState(() {
        _statusMessage =
            '''
✅ All assets loaded successfully!

marker.png: ${markerData.lengthInBytes} bytes
test_sheet_blank.png: ${blankData.lengthInBytes} bytes
test_sheet_filled.png: ${filledData.lengthInBytes} bytes
''';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error loading assets:\n$e';
        _isLoading = false;
      });
      print('Error loading assets: $e');
    }
  }

  Future<void> _testPreprocessing() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing image preprocessing...';
    });

    try {
      // Load test image
      final imageData = await rootBundle.load('assets/test_sheet_filled.png');
      final bytes = imageData.buffer.asUint8List();
      print('✓ Loaded test image: ${bytes.length} bytes');

      // Convert to Mat
      final mat = _preprocessor.uint8ListToMat(bytes);
      print('✓ Converted to Mat: ${mat.rows}x${mat.cols}');

      // Preprocess
      final stopwatch = Stopwatch()..start();
      final processed = await _preprocessor.preprocess(mat);
      stopwatch.stop();
      mat.dispose(); // Dispose original mat

      print('✓ Preprocessing completed in ${stopwatch.elapsedMilliseconds}ms');
      print(
        '  Processed Mat: ${processed.rows}x${processed.cols}, channels: ${processed.channels}',
      );

      // Convert back to verify
      final processedBytes = _preprocessor.matToUint8List(processed);
      processed.dispose(); // Dispose processed mat

      setState(() {
        _statusMessage =
            '''
✅ Preprocessing test successful!

Input image: ${bytes.length} bytes
Processing time: ${stopwatch.elapsedMilliseconds}ms
Output: Grayscale, CLAHE applied, normalized
Output size: ${processedBytes.length} bytes

The image has been converted to grayscale,
contrast-enhanced with CLAHE, and normalized.
''';
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _statusMessage = '❌ Error during preprocessing:\n$e';
        _isLoading = false;
      });
      print('Error during preprocessing: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _testMarkerDetection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing marker detection...';
    });

    try {
      final stopwatch = Stopwatch()..start();

      // 1. Load marker template
      final markerData = await rootBundle.load('assets/marker.png');
      final markerBytes = markerData.buffer.asUint8List();
      await _markerDetector.loadMarkerTemplate(markerBytes);
      print('✓ Marker template loaded: ${markerBytes.length} bytes');

      // 2. Load test image (filled sheet)
      final imageData = await rootBundle.load('assets/test_sheet_filled.png');
      final imageBytes = imageData.buffer.asUint8List();
      print('✓ Test image loaded: ${imageBytes.length} bytes');

      // 3. Preprocess image
      final mat = _preprocessor.uint8ListToMat(imageBytes);
      final processed = await _preprocessor.preprocess(mat);
      mat.dispose();
      print('✓ Image preprocessed: ${processed.rows}x${processed.cols}');

      // 4. Detect markers
      final result = await _markerDetector.detect(processed);
      processed.dispose();
      stopwatch.stop();

      print(
        '✓ Marker detection completed in ${stopwatch.elapsedMilliseconds}ms',
      );
      print('  Result: $result');

      // Format confidence values
      final confidenceStr = result.perMarkerConfidence
          .asMap()
          .entries
          .map(
            (e) =>
                '  ${['TL', 'TR', 'BR', 'BL'][e.key]}: ${(e.value * 100).toStringAsFixed(1)}%',
          )
          .join('\n');

      setState(() {
        _statusMessage =
            '''
${result.isValid ? '✅' : '❌'} Marker Detection ${result.isValid ? 'Successful' : 'Failed'}!

Detection time: ${stopwatch.elapsedMilliseconds}ms
Markers found: ${result.allMarkersFound ? '4/4' : '${result.perMarkerConfidence.where((c) => c >= _markerDetector.minConfidence).length}/4'}
Average confidence: ${(result.avgConfidence * 100).toStringAsFixed(1)}%

Per-marker confidence:
$confidenceStr

Marker centers (TL, TR, BR, BL):
${result.markerCenters.map((p) => '  (${p.x.toStringAsFixed(1)}, ${p.y.toStringAsFixed(1)})').join('\n')}

${result.isValid ? 'All markers detected successfully! ✓' : 'Warning: Some markers have low confidence.'}
''';
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _statusMessage = '❌ Error during marker detection:\n$e';
        _isLoading = false;
      });
      print('Error during marker detection: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _testPerspectiveTransform() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing perspective transform...';
    });

    try {
      final stopwatch = Stopwatch()..start();

      // 1. Load marker template
      final markerData = await rootBundle.load('assets/marker.png');
      final markerBytes = markerData.buffer.asUint8List();
      await _markerDetector.loadMarkerTemplate(markerBytes);
      print('✓ Marker template loaded');

      // 2. Load test image (filled sheet)
      final imageData = await rootBundle.load('assets/test_sheet_filled.png');
      final imageBytes = imageData.buffer.asUint8List();
      print('✓ Test image loaded: ${imageBytes.length} bytes');

      // 3. Preprocess image
      final mat = _preprocessor.uint8ListToMat(imageBytes);
      final processed = await _preprocessor.preprocess(mat);
      mat.dispose();
      print('✓ Image preprocessed: ${processed.rows}x${processed.cols}');

      // 4. Detect markers
      final markerResult = await _markerDetector.detect(processed);
      print(
        '✓ Markers detected: ${markerResult.allMarkersFound ? '4/4' : 'Failed'}',
      );

      if (!markerResult.isValid) {
        processed.dispose();
        setState(() {
          _statusMessage = '❌ Failed: Could not detect all 4 markers';
          _isLoading = false;
        });
        return;
      }

      // Store input dimensions before disposal
      final inputRows = processed.rows;
      final inputCols = processed.cols;

      // 5. Transform perspective
      final warped = await _perspectiveTransformer.transform(
        processed,
        markerResult.markerCenters,
        kTemplateWidth,
        kTemplateHeight,
      );
      processed.dispose();
      print('✓ Perspective transform applied: ${warped.rows}x${warped.cols}');

      // 6. Save warped output to device
      final directory = await getApplicationDocumentsDirectory();
      final outputPath = '${directory.path}/warped_output.png';
      final success = await cv.imwriteAsync(outputPath, warped);
      print('✓ Warped image saved to: $outputPath (success: $success)');

      // Verify file exists
      final file = File(outputPath);
      final fileExists = await file.exists();
      final fileSize = fileExists ? await file.length() : 0;

      warped.dispose();
      stopwatch.stop();

      setState(() {
        _statusMessage =
            '''
✅ Perspective Transform Successful!

Total processing time: ${stopwatch.elapsedMilliseconds}ms
Markers detected: 4/4
Average confidence: ${(markerResult.avgConfidence * 100).toStringAsFixed(1)}%

Transform details:
• Input: ${inputRows}x${inputCols} pixels
• Output: ${kTemplateWidth}x${kTemplateHeight} pixels
• Output file: warped_output.png
• File size: ${(fileSize / 1024).toStringAsFixed(1)} KB
• File location: $outputPath

${fileExists ? '✓ Output file saved successfully!' : '⚠️ Warning: Output file not found'}

You can manually verify the warped image is correctly aligned by checking the saved file.
''';
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _statusMessage = '❌ Error during perspective transform:\n$e';
        _isLoading = false;
      });
      print('Error during perspective transform: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _testBubbleReading() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing bubble reading...';
    });

    try {
      final stopwatch = Stopwatch()..start();

      // 1. Load marker template
      final markerData = await rootBundle.load('assets/marker.png');
      final markerBytes = markerData.buffer.asUint8List();
      await _markerDetector.loadMarkerTemplate(markerBytes);
      print('✓ Marker template loaded');

      // 2. Load test image (filled sheet)
      final imageData = await rootBundle.load('assets/test_sheet_filled.png');
      final imageBytes = imageData.buffer.asUint8List();
      print('✓ Test image loaded: ${imageBytes.length} bytes');

      // 3. Preprocess image
      final mat = _preprocessor.uint8ListToMat(imageBytes);
      final processed = await _preprocessor.preprocess(mat);
      mat.dispose();
      print('✓ Image preprocessed: ${processed.rows}x${processed.cols}');

      // 4. Detect markers
      final markerResult = await _markerDetector.detect(processed);
      print(
        '✓ Markers detected: ${markerResult.allMarkersFound ? '4/4' : 'Failed'}',
      );

      if (!markerResult.isValid) {
        processed.dispose();
        setState(() {
          _statusMessage = '❌ Failed: Could not detect all 4 markers';
          _isLoading = false;
        });
        return;
      }

      // 5. Transform perspective
      final warped = await _perspectiveTransformer.transform(
        processed,
        markerResult.markerCenters,
        kTemplateWidth,
        kTemplateHeight,
      );
      processed.dispose();
      print('✓ Perspective transform applied: ${warped.rows}x${warped.cols}');

      // 6. Read all bubbles
      final bubbleResult = await _bubbleReader.readAllBubbles(
        warped,
        kBubblePositions,
      );
      warped.dispose();
      stopwatch.stop();

      print('✓ Bubble reading completed in ${stopwatch.elapsedMilliseconds}ms');
      print('  Total bubbles read: ${bubbleResult.allValues.length}');

      // Format bubble values for each question
      final options = ['A', 'B', 'C', 'D', 'E'];
      final bubbleValuesStr = bubbleResult.bubbleValues.entries
          .map((entry) {
            final question = entry.key;
            final values = entry.value;
            final valuesStr = values
                .asMap()
                .entries
                .map((e) => '${options[e.key]}: ${e.value.toStringAsFixed(1)}')
                .join(', ');
            return '  $question: $valuesStr';
          })
          .join('\n');

      // Statistics
      final allValues = bubbleResult.allValues;

      // Guard against empty list to prevent StateError
      if (allValues.isEmpty) {
        setState(() {
          _statusMessage =
              '''
⚠️ Bubble Reading Warning

Total processing time: ${stopwatch.elapsedMilliseconds}ms
Questions: ${bubbleResult.bubbleValues.length}
Total bubbles: 0

No bubble values were read. This could indicate:
• Empty bubble positions configuration
• Template configuration error
• Image processing failure

Please check the template configuration.
''';
          _isLoading = false;
        });
        return;
      }

      final minValue = allValues.reduce((a, b) => a < b ? a : b);
      final maxValue = allValues.reduce((a, b) => a > b ? a : b);
      final avgValue = allValues.reduce((a, b) => a + b) / allValues.length;

      setState(() {
        _statusMessage =
            '''
✅ Bubble Reading Successful!

Total processing time: ${stopwatch.elapsedMilliseconds}ms
Questions: ${bubbleResult.bubbleValues.length}
Total bubbles: ${bubbleResult.allValues.length}

Bubble intensity values (0=black, 255=white):
$bubbleValuesStr

Statistics:
• Min intensity: ${minValue.toStringAsFixed(1)} (darkest)
• Max intensity: ${maxValue.toStringAsFixed(1)} (lightest)
• Average: ${avgValue.toStringAsFixed(1)}
• Range: ${(maxValue - minValue).toStringAsFixed(1)}

Lower values indicate filled (darker) bubbles.
Higher values indicate unfilled (lighter) bubbles.

Next step: Implement threshold calculator to determine which bubbles are filled.
''';
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _statusMessage = '❌ Error during bubble reading:\n$e';
        _isLoading = false;
      });
      print('Error during bubble reading: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Load image from assets
  Future<void> _loadAssetImage(String assetPath, String imageName) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading $imageName...';
      _pipelineResult = null;
    });

    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      // Load marker template for pipeline
      final markerData = await rootBundle.load('assets/marker.png');
      await _pipeline.loadMarkerTemplate(markerData.buffer.asUint8List());

      setState(() {
        _currentImageBytes = bytes;
        _currentImageName = imageName;
        _statusMessage =
            '✅ Loaded $imageName (${bytes.length} bytes)\n\nReady to run OMR pipeline.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error loading image:\n$e';
        _isLoading = false;
      });
    }
  }

  // Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        setState(() {
          _statusMessage = 'No image selected';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _statusMessage = 'Loading image from gallery...';
        _pipelineResult = null;
      });

      final bytes = await image.readAsBytes();

      // Load marker template for pipeline
      final markerData = await rootBundle.load('assets/marker.png');
      await _pipeline.loadMarkerTemplate(markerData.buffer.asUint8List());

      setState(() {
        _currentImageBytes = bytes;
        _currentImageName = image.name;
        _statusMessage =
            '✅ Loaded ${image.name} (${bytes.length} bytes)\n\nReady to run OMR pipeline.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error picking image:\n$e';
        _isLoading = false;
      });
    }
  }

  // Run full OMR pipeline
  Future<void> _runOmrPipeline() async {
    if (_currentImageBytes == null) {
      setState(() {
        _statusMessage = '⚠️ Please load an image first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Running OMR pipeline...';
    });

    try {
      // Load marker template
      final markerData = await rootBundle.load('assets/marker.png');
      await _pipeline.loadMarkerTemplate(markerData.buffer.asUint8List());

      // Run pipeline
      final result = await _pipeline.process(_currentImageBytes!);

      setState(() {
        _pipelineResult = result;
        _statusMessage = _buildPipelineResultMessage(result);
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _statusMessage = '❌ Pipeline error:\n$e\n$stackTrace';
        _isLoading = false;
      });
      print('Pipeline error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Build comprehensive result message
  String _buildPipelineResultMessage(OmrResult result) {
    if (!result.success) {
      // Use actual configured threshold from marker detector
      final threshold = _markerDetector.minConfidence;
      return '''
❌ OMR Pipeline Failed

Error: ${result.errorMessage}
Processing time: ${result.processingTimeMs}ms

${result.markerResult != null ? 'Marker detection: ${result.markerResult!.allMarkersFound ? '4/4' : '${result.markerResult!.perMarkerConfidence.where((c) => c >= threshold).length}/4'} markers found (threshold: ${threshold.toStringAsFixed(2)})' : 'Marker detection not attempted'}
''';
    }

    final answers = result.answers!;
    final threshold = result.thresholdResult!;
    final markers = result.markerResult!;

    // Format answers with status
    final options = ['A', 'B', 'C', 'D', 'E'];
    final answersStr = answers.entries
        .map((entry) {
          final q = entry.key;
          final answer = entry.value;

          String statusIcon;
          String statusText;
          switch (answer.status) {
            case AnswerStatus.valid:
              // Compare with expected answers if this is the filled test sheet
              if (_currentImageName?.contains('filled') ?? false) {
                final expected = kTestSheetAnswers[q];
                final isCorrect = answer.value == expected;
                statusIcon = isCorrect ? '✅' : '❌';
                statusText = isCorrect
                    ? '${answer.value} (correct)'
                    : '${answer.value} (expected: $expected)';
              } else {
                statusIcon = '✅';
                statusText = answer.value!;
              }
              break;
            case AnswerStatus.blank:
              statusIcon = '⚪';
              statusText = 'BLANK';
              break;
            case AnswerStatus.multipleMark:
              statusIcon = '⚠️';
              statusText = 'MULTIPLE MARKS';
              break;
          }

          return '  ${q.toUpperCase()}: $statusIcon $statusText';
        })
        .join('\n');

    // Calculate correctness if this is the filled test sheet
    String correctnessInfo = '';
    if (_currentImageName?.contains('filled') ?? false) {
      final correctCount = answers.entries.where((entry) {
        final expected = kTestSheetAnswers[entry.key];
        return entry.value.status == AnswerStatus.valid &&
            entry.value.value == expected;
      }).length;
      correctnessInfo =
          '\n\nAccuracy: $correctCount/${answers.length} correct (${(correctCount / answers.length * 100).toStringAsFixed(1)}%)';
    }

    // Format marker confidence
    final markerConfStr = markers.perMarkerConfidence
        .asMap()
        .entries
        .map(
          (e) =>
              '${['TL', 'TR', 'BR', 'BL'][e.key]}: ${(e.value * 100).toStringAsFixed(1)}%',
        )
        .join(', ');

    return '''
✅ OMR Pipeline Successful!

Processing time: ${result.processingTimeMs}ms
Image: $_currentImageName

Marker Detection:
• Found: 4/4 markers
• Avg confidence: ${(markers.avgConfidence * 100).toStringAsFixed(1)}%
• Per-marker: $markerConfStr

Threshold Calculation:
• Threshold: ${threshold.threshold.toStringAsFixed(1)}
• Confidence: ${(threshold.confidence * 100).toStringAsFixed(1)}%
• Max gap: ${threshold.maxGap.toStringAsFixed(1)}

Extracted Answers:
$answersStr$correctnessInfo

${result.success ? '🎉 All steps completed successfully!' : ''}
''';
  }

  @override
  void dispose() {
    _markerDetector.dispose();
    _pipeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('OMR Spike - Asset Test'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image, size: 64, color: Colors.blue),
              const SizedBox(height: 24),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    // === OMR PIPELINE TEST SECTION ===
                    const Text(
                      'OMR Pipeline Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Image loading buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _loadAssetImage(
                            'assets/test_sheet_blank.png',
                            'Blank Sheet',
                          ),
                          icon: const Icon(Icons.insert_drive_file),
                          label: const Text('Load Blank'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _loadAssetImage(
                            'assets/test_sheet_filled.png',
                            'Filled Sheet',
                          ),
                          icon: const Icon(Icons.description),
                          label: const Text('Load Filled'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Pick from Gallery'),
                    ),
                    const SizedBox(height: 16),

                    // Run pipeline button
                    ElevatedButton.icon(
                      onPressed: _currentImageBytes != null
                          ? _runOmrPipeline
                          : null,
                      icon: const Icon(Icons.play_circle_filled),
                      label: const Text('Run OMR Pipeline'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),

                    // === INDIVIDUAL STEP TESTS ===
                    const Text(
                      'Individual Step Tests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _testAssetLoading,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Test Asset Loading'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _testPreprocessing,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Test Image Preprocessing'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _testMarkerDetection,
                      icon: const Icon(Icons.center_focus_strong),
                      label: const Text('Test Marker Detection'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _testPerspectiveTransform,
                      icon: const Icon(Icons.transform),
                      label: const Text('Test Perspective Transform'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _testBubbleReading,
                      icon: const Icon(Icons.circle_outlined),
                      label: const Text('Test Bubble Reading'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
