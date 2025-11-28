import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omr_spike/services/image_preprocessor.dart';
import 'package:omr_spike/services/marker_detector.dart';
import 'package:omr_spike/services/perspective_transformer.dart';
import 'package:omr_spike/models/template_config.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:path_provider/path_provider.dart';
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
  final PerspectiveTransformer _perspectiveTransformer = PerspectiveTransformer();

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
        _statusMessage = '''
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
      print('  Processed Mat: ${processed.rows}x${processed.cols}, channels: ${processed.channels}');

      // Convert back to verify
      final processedBytes = _preprocessor.matToUint8List(processed);
      processed.dispose(); // Dispose processed mat

      setState(() {
        _statusMessage = '''
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

      print('✓ Marker detection completed in ${stopwatch.elapsedMilliseconds}ms');
      print('  Result: $result');

      // Format confidence values
      final confidenceStr = result.perMarkerConfidence
          .asMap()
          .entries
          .map((e) => '  ${['TL', 'TR', 'BR', 'BL'][e.key]}: ${(e.value * 100).toStringAsFixed(1)}%')
          .join('\n');

      setState(() {
        _statusMessage = '''
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
      print('✓ Markers detected: ${markerResult.allMarkersFound ? '4/4' : 'Failed'}');

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
        _statusMessage = '''
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

  @override
  void dispose() {
    _markerDetector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('OMR Spike - Asset Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.image,
                size: 64,
                color: Colors.blue,
              ),
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
                    ElevatedButton.icon(
                      onPressed: _testAssetLoading,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Test Asset Loading'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _testPreprocessing,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Test Image Preprocessing'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _testMarkerDetection,
                      icon: const Icon(Icons.center_focus_strong),
                      label: const Text('Test Marker Detection'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _testPerspectiveTransform,
                      icon: const Icon(Icons.transform),
                      label: const Text('Test Perspective Transform'),
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
