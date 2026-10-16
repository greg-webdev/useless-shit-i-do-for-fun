import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/camera_service.dart';
import '../services/remote_server.dart';
import '../services/system_control_service.dart';
import '../widgets/test_card_view.dart';
import 'tv_browser_screen.dart';

class TvHomeScreen extends StatefulWidget {
  final CameraService cameraService;
  final RemoteServer remoteServer;

  const TvHomeScreen({
    super.key,
    required this.cameraService,
    required this.remoteServer,
  });

  @override
  State<TvHomeScreen> createState() => _TvHomeScreenState();
}

class _TvHomeScreenState extends State<TvHomeScreen> {
  bool _showOsd = true;
  bool _showQrModal = false;
  bool _showQuickMenu = false;
  bool _isBrowserMode = false;
  Timer? _osdAutoHideTimer;
  StreamSubscription<RemoteCommand>? _commandSub;

  // Virtual cursor for touchpad remote control
  Offset _virtualCursor = const Offset(640, 360);
  bool _showVirtualCursor = false;
  Timer? _cursorFadeTimer;

  // Recent action feedback toast
  String? _bannerMessage;
  Timer? _bannerTimer;

  final FocusNode _mainFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _startOsdAutoHide();

    // Listen to incoming remote commands from WebSocket
    _commandSub = widget.remoteServer.onCommand.listen(_handleRemoteCommand);

    // Sync camera state changes to remote clients
    widget.cameraService.addListener(_syncStateToRemote);

    // Ensure TV remote D-Pad focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mainFocusNode.requestFocus();
      _syncStateToRemote();
    });
  }

  @override
  void dispose() {
    _osdAutoHideTimer?.cancel();
    _cursorFadeTimer?.cancel();
    _bannerTimer?.cancel();
    _commandSub?.cancel();
    widget.cameraService.removeListener(_syncStateToRemote);
    _mainFocusNode.dispose();
    super.dispose();
  }

  void _syncStateToRemote() {
    widget.remoteServer.broadcastState({
      'activeDevice': widget.cameraService.activeCameraName,
      'resolution': widget.cameraService.resolutionName,
      'aspectRatio': widget.cameraService.aspectModeName,
      'isTestPattern': widget.cameraService.useTestPattern,
    });
  }

  void _startOsdAutoHide() {
    _osdAutoHideTimer?.cancel();
    _osdAutoHideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_showQuickMenu && !_showQrModal) {
        setState(() {
          _showOsd = false;
        });
      }
    });
  }

  void _wakeOsd([String? feedback]) {
    setState(() {
      _showOsd = true;
      if (feedback != null) {
        _showBanner(feedback);
      }
    });
    _startOsdAutoHide();
  }

  void _showBanner(String text) {
    _bannerTimer?.cancel();
    setState(() {
      _bannerMessage = text;
    });
    _bannerTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _bannerMessage = null;
        });
      }
    });
  }

  void _handleRemoteCommand(RemoteCommand cmd) {
    debugPrint('[TvHomeScreen] Executing: ${cmd.action}');
    switch (cmd.action) {
      case 'UP':
        _wakeOsd('▲ Remote Up');
        break;
      case 'DOWN':
        _wakeOsd('▼ Remote Down');
        break;
      case 'LEFT':
        _wakeOsd('◀ Remote Left');
        break;
      case 'RIGHT':
        _wakeOsd('▶ Remote Right');
        break;
      case 'SELECT':
        _wakeOsd('✓ OK / Select');
        if (_showQrModal) {
          setState(() => _showQrModal = false);
        } else {
          setState(() => _showQuickMenu = !_showQuickMenu);
        }
        break;
      case 'BACK':
        _wakeOsd('↩ Back');
        if (_showQrModal) {
          setState(() => _showQrModal = false);
        } else if (_showQuickMenu) {
          setState(() => _showQuickMenu = false);
        } else {
          setState(() => _showOsd = false);
        }
        break;
      case 'MENU':
        setState(() {
          _showQuickMenu = !_showQuickMenu;
          _showOsd = true;
        });
        break;
      case 'HOME':
        _wakeOsd('Home');
        SystemControlService.sendGlobalAction('HOME');
        setState(() {
          _showQuickMenu = false;
          _showQrModal = false;
        });
        break;
      case 'SWITCH_TO_BROWSER':
        setState(() => _isBrowserMode = true);
        _wakeOsd('Switched to TV Browser');
        break;
      case 'SWITCH_TO_CAPTURE':
        setState(() => _isBrowserMode = false);
        _wakeOsd('Switched to Capture Card');
        break;
      case 'SYS_HOME':
        SystemControlService.sendGlobalAction('HOME');
        _wakeOsd('System: Home');
        break;
      case 'SYS_BACK':
        SystemControlService.sendGlobalAction('BACK');
        _wakeOsd('System: Back');
        break;
      case 'SYS_RECENTS':
        SystemControlService.sendGlobalAction('RECENTS');
        _wakeOsd('System: Recents');
        break;
      case 'SYS_NOTIF':
        SystemControlService.sendGlobalAction('NOTIFICATIONS');
        _wakeOsd('System: Notifications');
        break;
      case 'SYS_POWER':
        SystemControlService.sendGlobalAction('POWER');
        _wakeOsd('System: Power Menu');
        break;
      case 'SYS_UP':
        SystemControlService.sendKeyevent(SystemControlService.keyDpadUp);
        _wakeOsd('System: ▲');
        break;
      case 'SYS_DOWN':
        SystemControlService.sendKeyevent(SystemControlService.keyDpadDown);
        _wakeOsd('System: ▼');
        break;
      case 'SYS_LEFT':
        SystemControlService.sendKeyevent(SystemControlService.keyDpadLeft);
        _wakeOsd('System: ◀');
        break;
      case 'SYS_RIGHT':
        SystemControlService.sendKeyevent(SystemControlService.keyDpadRight);
        _wakeOsd('System: ▶');
        break;
      case 'SYS_SELECT':
        SystemControlService.sendKeyevent(SystemControlService.keyDpadCenter);
        _wakeOsd('System: Select');
        break;
      case 'SYS_TAP':
      case 'MOVE_CURSOR':
        // Already dispatched by RemoteServer at system level, do not duplicate
        break;
      case 'NEXT_CAM':
        widget.cameraService.switchCamera();
        _wakeOsd('Switched to ${widget.cameraService.activeCameraName}');
        break;
      case 'RELOAD_CAM':
        widget.cameraService.refreshCameras();
        _wakeOsd('Reconnecting Video Feed...');
        break;
      case 'ASPECT_16_9':
        widget.cameraService.setAspectMode(DisplayAspectMode.fit169);
        _wakeOsd('Aspect Ratio: 16:9 Fit');
        break;
      case 'ASPECT_FILL':
        widget.cameraService.setAspectMode(DisplayAspectMode.fill);
        _wakeOsd('Aspect Ratio: Full / Stretch');
        break;
      case 'ASPECT_4_3':
        widget.cameraService.setAspectMode(DisplayAspectMode.retro43);
        _wakeOsd('Aspect Ratio: 4:3 Retro');
        break;
      case 'TOGGLE_OSD':
        setState(() => _showOsd = !_showOsd);
        break;
      case 'TOGGLE_QR':
        setState(() {
          _showQrModal = !_showQrModal;
          _showOsd = true;
        });
        break;
      case 'TEST_PATTERN':
        widget.cameraService.toggleTestPattern();
        _wakeOsd('Toggled Test Pattern');
        break;
      case 'TYPE_TEXT':
        final text = cmd.payload['text']?.toString() ?? '';
        _wakeOsd('Input Received: "$text"');
        break;
      case 'MOUSE_MOVE':
        final dx = (cmd.payload['dx'] as num?)?.toDouble() ?? 0.0;
        final dy = (cmd.payload['dy'] as num?)?.toDouble() ?? 0.0;
        _updateVirtualCursor(dx, dy);
        break;
      case 'VOL_UP':
        SystemControlService.sendKeyevent(SystemControlService.keyVolumeUp);
        _wakeOsd('Volume Up');
        break;
      case 'VOL_DOWN':
        SystemControlService.sendKeyevent(SystemControlService.keyVolumeDown);
        _wakeOsd('Volume Down');
        break;
      case 'MUTE':
        SystemControlService.sendKeyevent(SystemControlService.keyVolumeMute);
        _wakeOsd('Mute Toggled');
        break;
      case 'PLAY_PAUSE':
        SystemControlService.sendKeyevent(SystemControlService.keyMediaPlayPause);
        _wakeOsd('Play / Pause');
        break;
      case 'GET_STATE':
        _syncStateToRemote();
        break;
      default:
        _wakeOsd(cmd.action);
        break;
    }
  }

  void _updateVirtualCursor(double dx, double dy) {
    final size = MediaQuery.of(context).size;
    final newX = (_virtualCursor.dx + dx * 2.2).clamp(0.0, size.width);
    final newY = (_virtualCursor.dy + dy * 2.2).clamp(0.0, size.height);

    setState(() {
      _virtualCursor = Offset(newX, newY);
      _showVirtualCursor = true;
    });

    _cursorFadeTimer?.cancel();
    _cursorFadeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showVirtualCursor = false;
        });
      }
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      _wakeOsd();

      if (event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        setState(() {
          _showQuickMenu = !_showQuickMenu;
        });
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.goBack) {
        if (_showQrModal) {
          setState(() => _showQrModal = false);
          return KeyEventResult.handled;
        }
        if (_showQuickMenu) {
          setState(() => _showQuickMenu = false);
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.contextMenu) {
        setState(() => _showQuickMenu = true);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (_isBrowserMode) {
      return TvBrowserScreen(
        cameraService: widget.cameraService,
        remoteServer: widget.remoteServer,
        onReturnToCapture: () => setState(() => _isBrowserMode = false),
      );
    }

    final serverUrl = 'http://${widget.remoteServer.localIp}:${widget.remoteServer.port}';

    return Focus(
      focusNode: _mainFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => _wakeOsd(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main Video / Capture Stream Viewport
              _buildVideoViewport(serverUrl),

              // Animated Action Banner (Top Center Toast)
              if (_bannerMessage != null)
                Positioned(
                  top: 28,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xEE0F172A),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFF00F2FE),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F2FE).withValues(alpha: 0.35),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Text(
                        _bannerMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),

              // Auto-hiding OSD Top Bar
              AnimatedOpacity(
                opacity: _showOsd ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 350),
                child: IgnorePointer(
                  ignoring: !_showOsd,
                  child: Stack(
                    children: [
                      // Top Left Status Badge
                      Positioned(
                        top: 24,
                        left: 28,
                        child: _buildSourceStatusBadge(),
                      ),

                      // Top Right Connection & QR Trigger
                      Positioned(
                        top: 24,
                        right: 28,
                        child: _buildConnectionBadge(serverUrl),
                      ),

                      // Bottom TV Remote Shortcuts Guide
                      Positioned(
                        bottom: 20,
                        left: 28,
                        right: 28,
                        child: _buildBottomGuide(),
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Settings Floating Panel
              if (_showQuickMenu) _buildQuickMenuModal(),

              // QR Code Full Pairing Modal
              if (_showQrModal) _buildQrPairingModal(serverUrl),

              // Virtual Touchpad Pointer
              if (_showVirtualCursor)
                Positioned(
                  left: _virtualCursor.dx - 12,
                  top: _virtualCursor.dy - 12,
                  child: IgnorePointer(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F2FE),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F2FE).withValues(alpha: 0.8),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoViewport(String serverUrl) {
    return ListenableBuilder(
      listenable: widget.cameraService,
      builder: (context, _) {
        if (widget.cameraService.isInitializing) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF00F2FE)),
                SizedBox(height: 16),
                Text(
                  'CONNECTING TO VIDEO CAPTURE...',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          );
        }

        if (widget.cameraService.useTestPattern ||
            !widget.cameraService.isInitialized) {
          return TestCardView(
            statusMessage: widget.cameraService.errorMessage ??
                'No HDMI video signal detected. Connect capture card via USB.',
            serverUrl: serverUrl,
          );
        }

        final ctrl = widget.cameraService.controller!;
        final preview = CameraPreview(ctrl);

        switch (widget.cameraService.aspectMode) {
          case DisplayAspectMode.fit169:
            return Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: preview,
              ),
            );
          case DisplayAspectMode.fill:
            return SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: ctrl.value.previewSize?.height ?? 1920,
                  height: ctrl.value.previewSize?.width ?? 1080,
                  child: preview,
                ),
              ),
            );
          case DisplayAspectMode.retro43:
            return Center(
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: preview,
              ),
            );
        }
      },
    );
  }

  Widget _buildSourceStatusBadge() {
    return ListenableBuilder(
      listenable: widget.cameraService,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xCC090E17),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.cameraService.useTestPattern
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF10B981),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.cameraService.useTestPattern
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF10B981))
                          .withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.cameraService.activeCameraName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${widget.cameraService.resolutionName} • ${widget.cameraService.aspectModeName}',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionBadge(String serverUrl) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xCC090E17),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() => _showQrModal = true);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_scanner,
                    color: Color(0xFF00F2FE), size: 24),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'REMOTE CONTROLLER',
                      style: TextStyle(
                        color: Color(0xFF00F2FE),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      serverUrl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.remoteServer.clientCount} online',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomGuide() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xAA090E17),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _guideItem('OK / SELECT', 'Quick Menu'),
          const SizedBox(width: 24),
          _guideItem('BACK', 'Dismiss / Exit'),
          const SizedBox(width: 24),
          _guideItem('PHONE BROWSER', 'Full Remote Control'),
        ],
      ),
    );
  }

  Widget _guideItem(String key, String action) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            key,
            style: const TextStyle(
              color: Color(0xFF00F2FE),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          action,
          style: TextStyle(
            color: Colors.grey.shade300,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickMenuModal() {
    return Center(
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xF00F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF00F2FE).withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'QUICK SETTINGS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _showQuickMenu = false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _menuButton(
              icon: Icons.language,
              title: 'Open Dedicated Web Browser',
              subtitle: 'YouTube, Twitch, Google, Reddit, etc.',
              onTap: () {
                setState(() {
                  _showQuickMenu = false;
                  _isBrowserMode = true;
                });
              },
            ),
            const SizedBox(height: 10),
            _menuButton(
              icon: Icons.switch_video,
              title: 'Switch Video Input',
              subtitle: 'Current: ${widget.cameraService.activeCameraName}',
              onTap: () {
                widget.cameraService.switchCamera();
                _wakeOsd('Switched Video Input');
              },
            ),
            const SizedBox(height: 10),
            _menuButton(
              icon: Icons.aspect_ratio,
              title: 'Toggle Aspect Ratio',
              subtitle: 'Current: ${widget.cameraService.aspectModeName}',
              onTap: () {
                widget.cameraService.toggleAspectMode();
                _wakeOsd('Aspect: ${widget.cameraService.aspectModeName}');
              },
            ),
            const SizedBox(height: 10),
            _menuButton(
              icon: Icons.qr_code,
              title: 'Show Mobile Pairing QR',
              subtitle: 'Scan with smartphone to control',
              onTap: () {
                setState(() {
                  _showQuickMenu = false;
                  _showQrModal = true;
                });
              },
            ),
            const SizedBox(height: 10),
            _menuButton(
              icon: Icons.refresh,
              title: 'Reconnect Video Feed',
              subtitle: 'Reload USB capture stream',
              onTap: () {
                widget.cameraService.refreshCameras();
                setState(() => _showQuickMenu = false);
                _wakeOsd('Reconnected Feed');
              },
            ),
            const SizedBox(height: 10),
            _menuButton(
              icon: Icons.tune,
              title: 'Toggle Test Pattern',
              subtitle: 'Simulate SMPTE color bars',
              onTap: () {
                widget.cameraService.toggleTestPattern();
                setState(() => _showQuickMenu = false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF00F2FE), size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white30, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrPairingModal(String serverUrl) {
    return Center(
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xF00F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF00F2FE),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F2FE).withValues(alpha: 0.3),
              blurRadius: 40,
              spreadRadius: 6,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SCAN TO CONNECT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _showQrModal = false),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: serverUrl,
                version: QrVersions.auto,
                size: 220,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              serverUrl,
              style: const TextStyle(
                color: Color(0xFF00F2FE),
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Open your smartphone camera or browser to instantly control this TV app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
