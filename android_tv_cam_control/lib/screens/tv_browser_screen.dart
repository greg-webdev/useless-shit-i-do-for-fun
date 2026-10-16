import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/camera_service.dart';
import '../services/remote_server.dart';

class TvBrowserScreen extends StatefulWidget {
  final CameraService cameraService;
  final RemoteServer remoteServer;
  final VoidCallback onReturnToCapture;

  const TvBrowserScreen({
    super.key,
    required this.cameraService,
    required this.remoteServer,
    required this.onReturnToCapture,
  });

  @override
  State<TvBrowserScreen> createState() => _TvBrowserScreenState();
}

class _TvBrowserScreenState extends State<TvBrowserScreen> {
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();

  bool _isLoading = false;
  double _loadProgress = 0.0;
  bool _showSpeedDial = true;
  bool _showPip = false;
  bool _virtualCursorActive = true;
  Offset _cursorPos = const Offset(640, 360);

  StreamSubscription<RemoteCommand>? _commandSub;

  final List<Map<String, String>> _bookmarks = [
    {'title': 'YouTube', 'url': 'https://www.youtube.com', 'icon': '📺'},
    {'title': 'Twitch', 'url': 'https://www.twitch.tv', 'icon': '🎮'},
    {'title': 'Google', 'url': 'https://www.google.com', 'icon': '🔍'},
    {'title': 'Reddit', 'url': 'https://www.reddit.com', 'icon': '👾'},
    {'title': 'Fast.com', 'url': 'https://fast.com', 'icon': '⚡'},
    {'title': 'Wikipedia', 'url': 'https://www.wikipedia.org', 'icon': '📖'},
    {'title': 'GitHub', 'url': 'https://github.com', 'icon': '🐙'},
    {'title': 'News', 'url': 'https://news.google.com', 'icon': '📰'},
  ];

  @override
  void initState() {
    super.initState();
    _initWebView();

    _commandSub = widget.remoteServer.onCommand.listen(_handleRemoteCommand);
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 11; MiTV) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _loadProgress = progress / 100.0;
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _showSpeedDial = false;
                _urlController.text = url;
              });
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _urlController.text = url;
              });
            }
          },
        ),
      );
  }

  @override
  void dispose() {
    _commandSub?.cancel();
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  void _handleRemoteCommand(RemoteCommand cmd) {
    if (!mounted) return;

    switch (cmd.action) {
      case 'BROWSER_URL':
        final url = cmd.payload['url']?.toString() ?? '';
        if (url.isNotEmpty) _loadUrl(url);
        break;
      case 'BROWSER_BACK':
        _controller.goBack();
        break;
      case 'BROWSER_FORWARD':
        _controller.goForward();
        break;
      case 'BROWSER_RELOAD':
        _controller.reload();
        break;
      case 'BROWSER_HOME':
        setState(() => _showSpeedDial = true);
        break;
      case 'TOGGLE_PIP':
        setState(() => _showPip = !_showPip);
        break;
      case 'MOUSE_MOVE':
        final dx = (cmd.payload['dx'] as num?)?.toDouble() ?? 0.0;
        final dy = (cmd.payload['dy'] as num?)?.toDouble() ?? 0.0;
        _moveCursor(dx, dy);
        break;
      case 'SELECT':
        if (_virtualCursorActive) {
          _clickAtCursor();
        }
        break;
      case 'BACK':
        _controller.canGoBack().then((can) {
          if (can) {
            _controller.goBack();
          } else if (!_showSpeedDial) {
            setState(() => _showSpeedDial = true);
          } else {
            widget.onReturnToCapture();
          }
        });
        break;
    }
  }

  void _moveCursor(double dx, double dy) {
    final size = MediaQuery.of(context).size;
    final newX = (_cursorPos.dx + dx * 2.5).clamp(0.0, size.width);
    final newY = (_cursorPos.dy + dy * 2.5).clamp(48.0, size.height);

    setState(() {
      _cursorPos = Offset(newX, newY);
      _virtualCursorActive = true;
    });
  }

  void _clickAtCursor() {
    // Offset for the top toolbar (height 52)
    final webY = (_cursorPos.dy - 52).clamp(0.0, 9999.0);
    final webX = _cursorPos.dx;

    // Dispatch JavaScript synthetic click event on element at cursor coordinates
    _controller.runJavaScript('''
      (function() {
        var el = document.elementFromPoint($webX, $webY);
        if (el) {
          el.focus();
          el.click();
          var ev = new MouseEvent('click', {
            'view': window,
            'bubbles': true,
            'cancelable': true,
            'clientX': $webX,
            'clientY': $webY
          });
          el.dispatchEvent(ev);
        }
      })();
    ''');
  }

  void _loadUrl(String input) {
    String trimmed = input.trim();
    if (trimmed.isEmpty) return;

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      if (trimmed.contains('.') && !trimmed.contains(' ')) {
        trimmed = 'https://$trimmed';
      } else {
        // Google Search query
        trimmed = 'https://www.google.com/search?q=${Uri.encodeComponent(trimmed)}';
      }
    }

    setState(() {
      _showSpeedDial = false;
      _urlController.text = trimmed;
    });

    _controller.loadRequest(Uri.parse(trimmed));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Main Body
          Column(
            children: [
              // Browser Toolbar
              _buildTopToolbar(),

              // Progress Bar
              if (_isLoading)
                LinearProgressIndicator(
                  value: _loadProgress,
                  backgroundColor: Colors.transparent,
                  color: const Color(0xFF00F2FE),
                  minHeight: 2,
                ),

              // View Area
              Expanded(
                child: _showSpeedDial
                    ? _buildSpeedDialGrid()
                    : WebViewWidget(controller: _controller),
              ),
            ],
          ),

          // Virtual Mouse Cursor
          if (_virtualCursorActive)
            Positioned(
              left: _cursorPos.dx - 10,
              top: _cursorPos.dy - 10,
              child: IgnorePointer(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F2FE),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F2FE).withValues(alpha: 0.8),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),

          // Picture-in-Picture Mini Capture Feed Overlay
          if (_showPip)
            Positioned(
              bottom: 24,
              right: 24,
              child: Container(
                width: 280,
                height: 158,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF00F2FE), width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black87, blurRadius: 20)
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.cameraService.controller != null &&
                        widget.cameraService.isInitialized
                    ? CameraPreview(widget.cameraService.controller!)
                    : Container(
                        color: Colors.black,
                        child: const Center(
                          child: Text(
                            'HDMI In',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopToolbar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          // Return to Capture Card Button
          IconButton(
            icon: const Icon(Icons.videocam, color: Color(0xFF00F2FE)),
            tooltip: 'Return to Capture Card',
            onPressed: widget.onReturnToCapture,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => _controller.goBack(),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white70),
            onPressed: () => _controller.goForward(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white70),
            onPressed: () => setState(() => _showSpeedDial = true),
          ),
          const SizedBox(width: 8),

          // URL / Omnibox
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.search, color: Colors.white38, size: 18),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      focusNode: _urlFocusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search Google or enter web address...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                        isDense: true,
                      ),
                      onSubmitted: _loadUrl,
                    ),
                  ),
                  if (_urlController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38, size: 16),
                      onPressed: () => _urlController.clear(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // PiP Toggle
          IconButton(
            icon: Icon(
              _showPip ? Icons.picture_in_picture : Icons.picture_in_picture_alt,
              color: _showPip ? const Color(0xFF00F2FE) : Colors.white70,
            ),
            tooltip: 'Toggle Capture Card PiP',
            onPressed: () => setState(() => _showPip = !_showPip),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDialGrid() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QUICK LAUNCH SITES',
              style: TextStyle(
                color: Color(0xFF00F2FE),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            GridView.builder(
              shrinkWrap: true,
              itemCount: _bookmarks.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.6,
              ),
              itemBuilder: (context, idx) {
                final b = _bookmarks[idx];
                return Material(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  borderOnForeground: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _loadUrl(b['url']!),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Text(b['icon']!, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              b['title']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
