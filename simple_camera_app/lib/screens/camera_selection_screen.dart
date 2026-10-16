import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'fullscreen_camera_screen.dart';

class CameraSelectionScreen extends StatefulWidget {
  const CameraSelectionScreen({super.key});

  @override
  State<CameraSelectionScreen> createState() => _CameraSelectionScreenState();
}

class _CameraSelectionScreenState extends State<CameraSelectionScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  bool _isLoading = true;
  String? _errorMessage;
  ResolutionPreset _selectedPreset = ResolutionPreset.max;
  Timer? _autoDetectTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCameras();

    // Auto-detect when USB cameras / capture cards are plugged in
    _autoDetectTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_cameras.isEmpty && mounted) {
        _loadCameras(silent: true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoDetectTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadCameras();
    }
  }

  Future<void> _loadCameras({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final cameras = await availableCameras();
      if (mounted) {
        setState(() {
          _cameras = cameras;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not access cameras: $e';
        });
      }
    }
  }

  void _openCamera(CameraDescription camera) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenCameraScreen(
          initialCamera: camera,
          availableCameras: _cameras,
          resolutionPreset: _selectedPreset,
        ),
      ),
    );
  }

  String _getLensTitle(CameraDescription camera) {
    switch (camera.lensDirection) {
      case CameraLensDirection.back:
        return 'Back Camera';
      case CameraLensDirection.front:
        return 'Front Camera';
      case CameraLensDirection.external:
        return 'External / USB Capture Card';
    }
  }

  IconData _getLensIcon(CameraDescription camera) {
    switch (camera.lensDirection) {
      case CameraLensDirection.back:
        return Icons.camera_rear_rounded;
      case CameraLensDirection.front:
        return Icons.camera_front_rounded;
      case CameraLensDirection.external:
        return Icons.videocam_rounded;
    }
  }

  Color _getLensColor(CameraDescription camera) {
    switch (camera.lensDirection) {
      case CameraLensDirection.back:
        return const Color(0xFF00F2FE);
      case CameraLensDirection.front:
        return const Color(0xFF4FACFE);
      case CameraLensDirection.external:
        return const Color(0xFF00E676);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Camera',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Choose a video source for fullscreen preview (unmirrored)',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00F2FE)),
            tooltip: 'Refresh Camera List',
            onPressed: () => _loadCameras(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Resolution selector bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF131C2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.hd_rounded, color: Color(0xFF00F2FE), size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Resolution:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Spacer(),
                DropdownButtonHideUnderline(
                  child: DropdownButton<ResolutionPreset>(
                    value: _selectedPreset,
                    dropdownColor: const Color(0xFF1A2438),
                    style: const TextStyle(
                      color: Color(0xFF00F2FE),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ResolutionPreset.max,
                        child: Text('Maximum / Native'),
                      ),
                      DropdownMenuItem(
                        value: ResolutionPreset.veryHigh,
                        child: Text('1080p FHD'),
                      ),
                      DropdownMenuItem(
                        value: ResolutionPreset.high,
                        child: Text('720p HD'),
                      ),
                      DropdownMenuItem(
                        value: ResolutionPreset.medium,
                        child: Text('480p SD'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedPreset = val;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main list or status
          Expanded(
            child: _buildCameraList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF00F2FE)),
            SizedBox(height: 16),
            Text(
              'Scanning for cameras...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_rounded, color: Colors.orangeAccent, size: 52),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _loadCameras(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
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

    if (_cameras.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_rounded, color: Colors.white30, size: 60),
              const SizedBox(height: 16),
              const Text(
                'No Cameras Detected',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connect a camera or USB capture card, then tap refresh.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadCameras(),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F2FE),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _cameras.length,
      itemBuilder: (context, index) {
        final camera = _cameras[index];
        final lensColor = _getLensColor(camera);
        final lensIcon = _getLensIcon(camera);
        final lensTitle = _getLensTitle(camera);

        return Focus(
          autofocus: index == 0,
          child: Builder(
            builder: (focusContext) {
              final isFocused = Focus.of(focusContext).hasFocus;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isFocused ? const Color(0xFF1C2842) : const Color(0xFF131C2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isFocused ? const Color(0xFF00F2FE) : Colors.white12,
                    width: isFocused ? 2 : 1,
                  ),
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00F2FE).withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openCamera(camera),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Camera Type Icon Avatar
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: lensColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: lensColor.withValues(alpha: 0.4)),
                            ),
                            child: Icon(lensIcon, color: lensColor, size: 26),
                          ),
                          const SizedBox(width: 16),

                          // Camera Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lensTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Device ID: ${camera.name}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Open Fullscreen Action Indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00F2FE).withValues(alpha: isFocused ? 0.3 : 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Open Fullscreen',
                                  style: TextStyle(
                                    color: Color(0xFF00F2FE),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF00F2FE), size: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
