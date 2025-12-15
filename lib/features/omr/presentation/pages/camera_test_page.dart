import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../../core/services/camera_service.dart';
import '../../../../injection.dart';
import '../../services/image_preprocessor.dart';
import '../../services/marker_detector.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Test page for validating camera integration with marker detection
///
/// This page demonstrates:
/// - Camera initialization and preview
/// - Real-time frame processing
/// - Marker detection integration
/// - Performance monitoring (FPS)
class CameraTestPage extends StatefulWidget {
  const CameraTestPage({super.key});

  @override
  State<CameraTestPage> createState() => _CameraTestPageState();
}

class _CameraTestPageState extends State<CameraTestPage> {
  final CameraService _cameraService = getIt<CameraService>();
  final ImagePreprocessor _preprocessor = getIt<ImagePreprocessor>();
  final MarkerDetector _markerDetector = getIt<MarkerDetector>();

  bool _isInitializing = true;
  String? _error;
  StreamSubscription? _imageStreamSubscription;

  // Detection state
  bool _isDetecting = false;
  int _markersDetected = 0;
  double _avgConfidence = 0.0;
  int _frameCount = 0;
  DateTime? _lastFrameTime;
  double _currentFps = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Initialize camera
      await _cameraService.initialize();

      // Load marker template
      final markerBytes = await rootBundle.load('assets/templates/marker.png');
      await _markerDetector.loadMarkerTemplate(markerBytes.buffer.asUint8List());

      // Start image stream for real-time detection
      _cameraService.startImageStream();

      // Subscribe to frame stream with throttling (10 FPS target)
      _imageStreamSubscription = _cameraService.imageStream
          .asyncMap((image) => _processFrame(image))
          .listen((_) {});

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _error = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    // Skip if already processing
    if (_isDetecting) {
      return;
    }

    _isDetecting = true;

    try {
      // Calculate FPS
      final now = DateTime.now();
      if (_lastFrameTime != null) {
        final elapsed = now.difference(_lastFrameTime!).inMilliseconds;
        if (elapsed > 0) {
          _currentFps = 1000 / elapsed;
        }
      }
      _lastFrameTime = now;

      // Convert camera image to bytes
      final bytes = CameraService.convertCameraImageToBytes(image);

      // Create Mat from raw pixel data (not imdecode)
      final isBGRA = image.format.group == ImageFormatGroup.bgra8888;
      final mat = _preprocessor.createMatFromPixels(
        bytes,
        image.width,
        image.height,
        isBGRA,
      );

      // Validate Mat was created successfully
      if (mat.isEmpty) {
        debugPrint('ERROR: Created Mat is empty');
        return;
      }

      debugPrint('Mat created: ${mat.width}x${mat.height}, channels: ${mat.channels}');

      try {
        // Preprocess
        final processed = await _preprocessor.preprocess(mat);

        try {
          // Detect markers
          final result = await _markerDetector.detect(processed);

          // Update UI
          if (mounted) {
            setState(() {
              _frameCount++;
              _markersDetected = result.markerCenters.length;
              _avgConfidence = result.avgConfidence;
            });
          }

          // Print coordinates if all markers detected
          if (result.allMarkersFound) {
            debugPrint('Markers detected: ${result.markerCenters}');
          }
        } finally {
          processed.dispose();
        }
      } finally {
        mat.dispose();
      }
    } catch (e) {
      debugPrint('Frame processing error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isInitializing = true;
                  });
                  _initializeCamera();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Camera preview
        Expanded(
          child: _cameraService.controller != null
              ? CameraPreview(_cameraService.controller!)
              : const Center(child: Text('Camera not available')),
        ),

        // Detection stats
        Container(
          color: Colors.black87,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detection Stats',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'FPS: ${_currentFps.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'Frames Processed: $_frameCount',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'Markers Detected: $_markersDetected / 4',
                style: TextStyle(
                  color: _markersDetected == 4 ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Confidence: ${(_avgConfidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: _avgConfidence > 0.3 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _imageStreamSubscription?.cancel();
    _cameraService.dispose();
    _markerDetector.dispose();
    super.dispose();
  }
}
