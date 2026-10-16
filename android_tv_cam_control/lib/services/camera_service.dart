import 'dart:async';
import 'package:camera/camera.dart' as cam_pkg;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum DisplayAspectMode {
  fit169, // 16:9 Standard fit
  fill,   // Fullscreen fill/stretch
  retro43 // 4:3 Retro gaming mode
}

class CameraService extends ChangeNotifier {
  static const MethodChannel _nativeChannel =
      MethodChannel('com.antigravity.tvcapture/video_stream');

  List<cam_pkg.CameraDescription> _availableCameras = [];
  cam_pkg.CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isInitializing = false;
  bool _useTestPattern = false;
  String? _errorMessage;
  DisplayAspectMode _aspectMode = DisplayAspectMode.fit169;
  final cam_pkg.ResolutionPreset _resolutionPreset = cam_pkg.ResolutionPreset.veryHigh;

  // Frame streaming
  void Function(Uint8List frameBytes)? onFrameAvailable;
  bool _isStreamingFrames = false;
  bool _isConvertingFrame = false;
  DateTime _lastFrameSent = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _testPatternTimer;
  int _testFrameCount = 0;

  List<cam_pkg.CameraDescription> get cameraList => _availableCameras;
  cam_pkg.CameraController? get controller => _controller;
  bool get isInitialized => _controller != null && _controller!.value.isInitialized;
  bool get isInitializing => _isInitializing;
  bool get useTestPattern => _useTestPattern || _availableCameras.isEmpty;
  String? get errorMessage => _errorMessage;
  DisplayAspectMode get aspectMode => _aspectMode;
  int get selectedIndex => _selectedCameraIndex;

  String get activeCameraName {
    if (useTestPattern || _availableCameras.isEmpty) {
      return 'SMPTE Test Pattern';
    }
    final cam = _availableCameras[_selectedCameraIndex];
    if (cam.lensDirection == cam_pkg.CameraLensDirection.external) {
      return 'USB Capture Card (${cam.name})';
    }
    return 'Camera ${_selectedCameraIndex + 1} (${cam.name})';
  }

  String get resolutionName {
    if (_controller != null && _controller!.value.isInitialized) {
      final size = _controller!.value.previewSize;
      if (size != null) {
        return '${size.width.toInt()}x${size.height.toInt()}';
      }
    }
    switch (_resolutionPreset) {
      case cam_pkg.ResolutionPreset.ultraHigh:
        return '4K (2160p)';
      case cam_pkg.ResolutionPreset.veryHigh:
        return 'FHD (1080p)';
      case cam_pkg.ResolutionPreset.high:
        return 'HD (720p)';
      default:
        return 'Standard';
    }
  }

  String get aspectModeName {
    switch (_aspectMode) {
      case DisplayAspectMode.fit169:
        return '16:9 Fit';
      case DisplayAspectMode.fill:
        return 'Full / Fill';
      case DisplayAspectMode.retro43:
        return '4:3 Retro';
    }
  }

  Future<void> init() async {
    _isInitializing = true;
    notifyListeners();

    try {
      _availableCameras = await cam_pkg.availableCameras();
      debugPrint('[CameraService] Found ${_availableCameras.length} cameras');

      if (_availableCameras.isEmpty) {
        _useTestPattern = true;
        _errorMessage = 'No camera or USB capture card detected yet.';
        _startTestPatternStream();
      } else {
        int externalIndex = _availableCameras.indexWhere(
          (c) => c.lensDirection == cam_pkg.CameraLensDirection.external,
        );
        _selectedCameraIndex = externalIndex != -1 ? externalIndex : 0;
        await _initCurrentCamera();
      }
    } catch (e) {
      debugPrint('[CameraService] Init error: $e');
      _errorMessage = 'Failed to access camera: $e';
      _useTestPattern = true;
      _startTestPatternStream();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _initCurrentCamera() async {
    if (_availableCameras.isEmpty) return;

    _stopTestPatternStream();

    final prev = _controller;
    _controller = null;
    if (prev != null) {
      if (_isStreamingFrames) {
        try {
          await prev.stopImageStream();
        } catch (_) {}
        _isStreamingFrames = false;
      }
      await prev.dispose();
    }

    final targetCam = _availableCameras[_selectedCameraIndex];
    debugPrint('[CameraService] Initializing camera: ${targetCam.name} (${targetCam.lensDirection})');

    final ctrl = cam_pkg.CameraController(
      targetCam,
      _resolutionPreset,
      enableAudio: false,
      imageFormatGroup: cam_pkg.ImageFormatGroup.yuv420,
    );

    _controller = ctrl;

    try {
      await ctrl.initialize();
      _useTestPattern = false;
      _errorMessage = null;

      // Start hardware frame analysis for web streaming
      await _startCameraFrameStream(ctrl);
    } catch (e) {
      debugPrint('[CameraService] Camera init failure: $e');
      _errorMessage = 'Error initializing video capture: $e';
      _useTestPattern = true;
      _startTestPatternStream();
    }
    notifyListeners();
  }

  Future<void> _startCameraFrameStream(cam_pkg.CameraController ctrl) async {
    if (_isStreamingFrames) return;

    try {
      await ctrl.startImageStream((cam_pkg.CameraImage image) {
        _onCameraFrame(image);
      });
      _isStreamingFrames = true;
      debugPrint('[CameraService] Camera image stream active');
    } catch (e) {
      debugPrint('[CameraService] Failed to start image stream: $e');
    }
  }

  void _onCameraFrame(cam_pkg.CameraImage image) async {
    if (onFrameAvailable == null) return;

    final now = DateTime.now();
    // Throttle to ~25 fps (40ms interval) to keep TV UI and Wi-Fi super smooth
    if (now.difference(_lastFrameSent).inMilliseconds < 40) return;
    if (_isConvertingFrame) return;

    _isConvertingFrame = true;
    _lastFrameSent = now;

    try {
      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];

      final Uint8List? jpeg = await _nativeChannel.invokeMethod<Uint8List>(
        'convertYuvToJpeg',
        {
          'width': image.width,
          'height': image.height,
          'quality': 65,
          'y': yPlane.bytes,
          'u': uPlane.bytes,
          'v': vPlane.bytes,
          'yRowStride': yPlane.bytesPerRow,
          'uvRowStride': uPlane.bytesPerRow,
          'uvPixelStride': uPlane.bytesPerPixel ?? 1,
        },
      );

      if (jpeg != null && jpeg.isNotEmpty) {
        onFrameAvailable?.call(jpeg);
      }
    } catch (e) {
      // If native conversion isn't available (e.g. desktop), fall back gracefully
    } finally {
      _isConvertingFrame = false;
    }
  }

  void _startTestPatternStream() {
    _testPatternTimer?.cancel();
    _testPatternTimer = Timer.periodic(const Duration(milliseconds: 66), (timer) {
      _testFrameCount++;
      final bmp = _generateTestBmpFrame(_testFrameCount);
      onFrameAvailable?.call(bmp);
    });
  }

  void _stopTestPatternStream() {
    _testPatternTimer?.cancel();
    _testPatternTimer = null;
  }

  Uint8List _generateTestBmpFrame(int frameNum) {
    const width = 320;
    const height = 180;
    const fileHeaderSize = 14;
    const dibHeaderSize = 40;
    const imageSize = width * height * 3;
    const totalSize = fileHeaderSize + dibHeaderSize + imageSize;

    final buffer = Uint8List(totalSize);
    final data = ByteData.view(buffer.buffer);

    // BMP Header
    buffer[0] = 0x42; // 'B'
    buffer[1] = 0x4D; // 'M'
    data.setUint32(2, totalSize, Endian.little);
    data.setUint32(10, fileHeaderSize + dibHeaderSize, Endian.little);

    // DIB Header
    data.setUint32(14, dibHeaderSize, Endian.little);
    data.setInt32(18, width, Endian.little);
    data.setInt32(22, -height, Endian.little); // Top-down
    data.setUint16(26, 1, Endian.little); // Planes
    data.setUint16(28, 24, Endian.little); // 24-bit BGR
    data.setUint32(34, imageSize, Endian.little);

    // Colors: BGR
    const colors = [
      [192, 192, 192], // White
      [0, 192, 192],   // Yellow
      [192, 192, 0],   // Cyan
      [0, 192, 0],     // Green
      [192, 0, 192],   // Magenta
      [0, 0, 192],     // Red
      [192, 0, 0],     // Blue
    ];

    int offset = fileHeaderSize + dibHeaderSize;
    final sweepX = (frameNum * 6) % width;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (x >= sweepX - 2 && x <= sweepX + 2) {
          // Bright scanline
          buffer[offset++] = 255;
          buffer[offset++] = 255;
          buffer[offset++] = 255;
        } else if (y < height * 0.7) {
          final barIdx = (x * colors.length) ~/ width;
          final c = colors[barIdx];
          buffer[offset++] = c[0];
          buffer[offset++] = c[1];
          buffer[offset++] = c[2];
        } else {
          // Dark bottom bar
          buffer[offset++] = 20;
          buffer[offset++] = 15;
          buffer[offset++] = 10;
        }
      }
    }

    return buffer;
  }

  Future<void> switchCamera() async {
    if (_availableCameras.isEmpty) {
      await refreshCameras();
      return;
    }

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    _isInitializing = true;
    notifyListeners();

    await _initCurrentCamera();
    _isInitializing = false;
    notifyListeners();
  }

  Future<void> refreshCameras() async {
    _isInitializing = true;
    notifyListeners();

    try {
      _availableCameras = await cam_pkg.availableCameras();
      if (_availableCameras.isNotEmpty) {
        _selectedCameraIndex = 0;
        await _initCurrentCamera();
      } else {
        _useTestPattern = true;
        _errorMessage = 'No capture device detected. Plug in USB capture card.';
        _startTestPatternStream();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _useTestPattern = true;
      _startTestPatternStream();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  void setAspectMode(DisplayAspectMode mode) {
    _aspectMode = mode;
    notifyListeners();
  }

  void toggleAspectMode() {
    switch (_aspectMode) {
      case DisplayAspectMode.fit169:
        _aspectMode = DisplayAspectMode.fill;
        break;
      case DisplayAspectMode.fill:
        _aspectMode = DisplayAspectMode.retro43;
        break;
      case DisplayAspectMode.retro43:
        _aspectMode = DisplayAspectMode.fit169;
        break;
    }
    notifyListeners();
  }

  void toggleTestPattern() {
    _useTestPattern = !_useTestPattern;
    if (_useTestPattern) {
      _startTestPatternStream();
    } else {
      _stopTestPatternStream();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTestPatternStream();
    _controller?.dispose();
    super.dispose();
  }
}
