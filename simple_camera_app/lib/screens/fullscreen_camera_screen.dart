import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum AspectDisplayMode {
  fit,  // Fits entire camera stream preserving aspect ratio
  fill, // Scales stream to fill entire screen edge-to-edge
}

class FullscreenCameraScreen extends StatefulWidget {
  final CameraDescription initialCamera;
  final List<CameraDescription> availableCameras;
  final ResolutionPreset resolutionPreset;

  const FullscreenCameraScreen({
    super.key,
    required this.initialCamera,
    required this.availableCameras,
    this.resolutionPreset = ResolutionPreset.max,
  });

  @override
  State<FullscreenCameraScreen> createState() => _FullscreenCameraScreenState();
}

class _FullscreenCameraScreenState extends State<FullscreenCameraScreen> {
  late CameraDescription _currentCamera;
  CameraController? _controller;
  bool _isInitializing = true;
  String? _errorMessage;

  // Mirroring state: STRICTLY FALSE by default (Unmirrored raw input)
  bool _isMirrored = false;

  // Display aspect mode: default to Fill for edge-to-edge fullscreen
  AspectDisplayMode _displayMode = AspectDisplayMode.fill;

  // Auto-hiding HUD controls
  bool _showOverlay = true;
  Timer? _overlayTimer;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentCamera = widget.initialCamera;

    // Enable sticky immersive mode (hides Android navigation and status bar)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Keep screen awake while previewing
    WakelockPlus.enable().catchError((_) {});

    // Initialize camera
    _initCamera(_currentCamera);
    _startOverlayTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _overlayTimer?.cancel();
    _controller?.dispose();

    // Restore normal system UI mode and screen wakelock
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable().catchError((_) {});
    super.dispose();
  }

  void _startOverlayTimer() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showOverlay) {
        setState(() {
          _showOverlay = false;
        });
      }
    });
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
      if (_showOverlay) {
        _startOverlayTimer();
      } else {
        _overlayTimer?.cancel();
      }
    });
  }

  Future<void> _initCamera(CameraDescription camera) async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    final oldController = _controller;
    _controller = null;
    if (oldController != null) {
      await oldController.dispose();
    }

    final newController = CameraController(
      camera,
      widget.resolutionPreset,
      enableAudio: false, // Pure camera video stream, no audio recording needed
    );

    try {
      await newController.initialize();
      if (mounted) {
        setState(() {
          _controller = newController;
          _currentCamera = camera;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  void _cycleNextCamera() {
    if (widget.availableCameras.length <= 1) return;
    final currentIndex = widget.availableCameras.indexWhere(
      (c) => c.name == _currentCamera.name,
    );
    final nextIndex = (currentIndex + 1) % widget.availableCameras.length;
    _initCamera(widget.availableCameras[nextIndex]);
    _startOverlayTimer();
  }

  String _getCameraTitle(CameraDescription cam) {
    switch (cam.lensDirection) {
      case CameraLensDirection.back:
        return 'Back Camera (${cam.name})';
      case CameraLensDirection.front:
        return 'Front Camera (${cam.name})';
      case CameraLensDirection.external:
        return 'External / USB (${cam.name})';
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _toggleOverlay();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.goBack) {
        Navigator.of(context).pop();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _toggleOverlay();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleOverlay,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Live Camera Viewport
              _buildCameraViewport(),

              // Minimalist Auto-Hiding Controls Overlay
              AnimatedOpacity(
                opacity: _showOverlay ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !_showOverlay,
                  child: _buildControlsOverlay(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraViewport() {
    if (_isInitializing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF00F2FE),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Starting ${_getCameraTitle(_currentCamera)}...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _controller == null || !_controller!.value.isInitialized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Camera not available',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _initCamera(_currentCamera),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F2FE),
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final ctrl = _controller!;
    final previewSize = ctrl.value.previewSize;

    // Build raw camera preview
    Widget previewWidget = CameraPreview(ctrl);

    // Ensure raw unmirrored input (or allow user to flip if hardware inverted it)
    if (_isMirrored) {
      previewWidget = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
        child: previewWidget,
      );
    }

    if (_displayMode == AspectDisplayMode.fill) {
      // Fullscreen fill (crops letterboxing to fill entire screen)
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize?.height ?? 1920,
            height: previewSize?.width ?? 1080,
            child: previewWidget,
          ),
        ),
      );
    } else {
      // Aspect fit (shows full sensor frame with letterboxing if aspect ratios differ)
      return Center(
        child: AspectRatio(
          aspectRatio: ctrl.value.aspectRatio,
          child: previewWidget,
        ),
      );
    }
  }

  Widget _buildControlsOverlay() {
    final resolutionText = _controller != null && _controller!.value.isInitialized && _controller!.value.previewSize != null
        ? '${_controller!.value.previewSize!.height.toInt()}x${_controller!.value.previewSize!.width.toInt()}'
        : '';

    return SafeArea(
      child: Column(
        children: [
          // Top Control Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Back to Camera Selection
                _buildOverlayButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: 'Select Camera',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),

                // Active Camera Info Badge
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _currentCamera.lensDirection == CameraLensDirection.front
                              ? Icons.camera_front_rounded
                              : (_currentCamera.lensDirection == CameraLensDirection.external
                                  ? Icons.videocam_rounded
                                  : Icons.camera_rear_rounded),
                          color: const Color(0xFF00F2FE),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _getCameraTitle(_currentCamera),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (resolutionText.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00F2FE).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              resolutionText,
                              style: const TextStyle(
                                color: Color(0xFF00F2FE),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Switch Camera button (if multiple cameras available)
                if (widget.availableCameras.length > 1)
                  _buildOverlayButton(
                    icon: Icons.cameraswitch_rounded,
                    tooltip: 'Switch Camera',
                    onPressed: _cycleNextCamera,
                  ),
              ],
            ),
          ),

          const Spacer(),

          // Bottom Bar Options
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Aspect Ratio Toggle (Fit vs Fill)
                _buildGlassPill(
                  icon: _displayMode == AspectDisplayMode.fill
                      ? Icons.fullscreen_rounded
                      : Icons.fit_screen_rounded,
                  label: _displayMode == AspectDisplayMode.fill ? 'Fill Screen' : 'Fit Aspect',
                  onTap: () {
                    setState(() {
                      _displayMode = _displayMode == AspectDisplayMode.fill
                          ? AspectDisplayMode.fit
                          : AspectDisplayMode.fill;
                    });
                    _startOverlayTimer();
                  },
                ),
                const SizedBox(width: 12),

                // Mirror Input Toggle (Default Unmirrored)
                _buildGlassPill(
                  icon: Icons.flip_rounded,
                  label: _isMirrored ? 'Mirrored' : 'Unmirrored (Raw)',
                  active: !_isMirrored,
                  onTap: () {
                    setState(() {
                      _isMirrored = !_isMirrored;
                    });
                    _startOverlayTimer();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildGlassPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: active ? const Color(0xFF00F2FE) : Colors.white24,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active ? const Color(0xFF00F2FE) : Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: active ? const Color(0xFF00F2FE) : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
