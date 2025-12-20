import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:injectable/injectable.dart';

/// Service for managing camera lifecycle and providing camera frames
@lazySingleton
class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  final StreamController<CameraImage> _imageStreamController =
      StreamController<CameraImage>.broadcast();

  /// Stream of camera preview frames
  Stream<CameraImage> get imageStream => _imageStreamController.stream;

  /// Whether the camera is currently initialized
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  /// Current camera controller (for preview widget)
  CameraController? get controller => _controller;

  /// Initialize camera with available cameras
  ///
  /// Uses the first back-facing camera if available, otherwise first camera
  /// Sets resolution to high (not max) for OMR scanning per CLAUDE.md
  Future<void> initialize() async {
    try {
      // Get available cameras
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw CameraException(
          'noCameras',
          'No cameras available on this device',
        );
      }

      // Prefer back camera for OMR scanning
      final camera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      // Create controller with high resolution (not max per CLAUDE.md)
      // imageFormatGroup left as platform default (yuv420 on Android, bgra8888 on iOS)
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      // Initialize controller
      await _controller!.initialize();

      // Lock to portrait orientation for consistency
      await _controller!.lockCaptureOrientation();
    } catch (e) {
      throw CameraException(
        'initializationFailed',
        'Failed to initialize camera: $e',
      );
    }
  }

  /// Start streaming camera frames for real-time detection
  ///
  /// Frames are emitted to [imageStream] for processing
  void startImageStream() {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw StateError('Camera not initialized. Call initialize() first.');
    }

    _controller!.startImageStream((CameraImage image) {
      if (!_imageStreamController.isClosed) {
        _imageStreamController.add(image);
      }
    });
  }

  /// Stop streaming camera frames
  Future<void> stopImageStream() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      await _controller!.stopImageStream();
    } catch (e) {
      // Ignore errors if stream wasn't running
    }
  }

  /// Capture a high-resolution still image
  ///
  /// Returns image bytes as Uint8List
  /// Use this for final capture after marker alignment
  Future<Uint8List> captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw StateError('Camera not initialized. Call initialize() first.');
    }

    try {
      final XFile imageFile = await _controller!.takePicture();
      return await imageFile.readAsBytes();
    } catch (e) {
      throw CameraException(
        'captureFailed',
        'Failed to capture image: $e',
      );
    }
  }

  /// Convert CameraImage to Uint8List for OpenCV processing
  ///
  /// Handles both YUV420 (Android) and BGRA8888 (iOS) formats
  /// Returns image bytes suitable for cv.imdecode()
  static Uint8List convertCameraImageToBytes(CameraImage image) {
    try {
      // Handle different image formats
      if (image.format.group == ImageFormatGroup.yuv420) {
        // Android YUV420 format
        return _convertYUV420ToBytes(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        // iOS BGRA8888 format
        return _convertBGRA8888ToBytes(image);
      } else {
        throw UnsupportedError(
          'Unsupported image format: ${image.format.group}',
        );
      }
    } catch (e) {
      throw Exception('Failed to convert camera image: $e');
    }
  }

  /// Convert YUV420 format (Android) to bytes
  static Uint8List _convertYUV420ToBytes(CameraImage image) {
    // For YUV420, we can use the Y plane directly for grayscale
    // This is faster than full color conversion
    final int width = image.width;
    final int height = image.height;

    // Get Y plane (luminance)
    final yPlane = image.planes[0];
    final bytes = yPlane.bytes;

    // If plane is contiguous (no row padding), return directly
    if (yPlane.bytesPerRow == width) {
      return Uint8List.fromList(bytes);
    }

    // Otherwise, copy without row padding
    final result = Uint8List(width * height);
    int resultIndex = 0;

    for (int row = 0; row < height; row++) {
      final int rowStart = row * yPlane.bytesPerRow;
      for (int col = 0; col < width; col++) {
        result[resultIndex++] = bytes[rowStart + col];
      }
    }

    return result;
  }

  /// Convert BGRA8888 format (iOS) to bytes
  static Uint8List _convertBGRA8888ToBytes(CameraImage image) {
    final plane = image.planes[0];
    final bytesPerRow = plane.bytesPerRow;
    final bytesPerPixel = plane.bytesPerPixel ?? 4;
    final width = image.width;
    final height = image.height;
    final rowBytes = width * bytesPerPixel;

    if (bytesPerRow == rowBytes) {
      // Contiguous rows, no padding
      return Uint8List.fromList(plane.bytes);
    }

    // Remove row padding for OpenCV Mat creation
    final result = Uint8List(width * height * bytesPerPixel);
    var offset = 0;

    for (int row = 0; row < height; row++) {
      final start = row * bytesPerRow;
      result.setRange(
        offset,
        offset + rowBytes,
        plane.bytes,
        start,
      );
      offset += rowBytes;
    }

    return result;
  }

  /// Dispose camera resources
  Future<void> dispose() async {
    await stopImageStream();
    await _imageStreamController.close();
    await _controller?.dispose();
    _controller = null;
  }
}
