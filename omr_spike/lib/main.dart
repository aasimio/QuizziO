import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omr_spike/services/image_preprocessor.dart';
import 'dart:typed_data';

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
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
