import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'ssl_certs.dart';
import 'system_control_service.dart';
import 'web_controller_html.dart';

class RemoteCommand {
  final String action;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  RemoteCommand({
    required this.action,
    this.payload = const {},
    required this.timestamp,
  });

  @override
  String toString() => 'RemoteCommand($action, $payload)';
}

class RemoteServer {
  HttpServer? _httpServer;
  HttpServer? _httpsServer;
  final Set<WebSocket> _clients = {};
  final Set<HttpResponse> _mjpegClients = {};
  final StreamController<RemoteCommand> _commandController =
      StreamController<RemoteCommand>.broadcast();

  String? _localIp;
  int _httpPort = 8080;
  int _httpsPort = 9293;
  bool _isRunning = false;
  Uint8List? _latestFrameBytes;
  Uint8List? _latestTvScreenBytes;

  double _currentCursorX = 960.0;
  double _currentCursorY = 540.0;

  Stream<RemoteCommand> get onCommand => _commandController.stream;
  String get localIp => _localIp ?? '127.0.0.1';
  int get port => _httpPort;
  int get httpsPort => _httpsPort;
  bool get isRunning => _isRunning;
  int get clientCount => _clients.length + _mjpegClients.length;
  bool get hasStreamSubscribers => _mjpegClients.isNotEmpty || _clients.isNotEmpty;
  Uint8List? get latestFrameBytes => _latestFrameBytes;

  Future<void> start({int port = 8080}) async {
    _httpPort = port;
    await _resolveLocalIp();

    // 1. Start HTTP Server (port 8080 or fallback)
    try {
      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, _httpPort);
      _isRunning = true;
      debugPrint('[RemoteServer] HTTP running on http://$localIp:$_httpPort');

      _httpServer!.listen(_handleHttpRequest, onError: (err) {
        debugPrint('[RemoteServer] HTTP Server error: $err');
      });
    } catch (e) {
      debugPrint('[RemoteServer] Failed to bind HTTP port $_httpPort: $e');
      if (_httpPort == 8080) {
        try {
          _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, 8088);
          _httpPort = 8088;
          _isRunning = true;
          _httpServer!.listen(_handleHttpRequest, onError: (err) {
            debugPrint('[RemoteServer] HTTP Server error: $err');
          });
        } catch (_) {}
      }
    }

    // 2. Start HTTPS Server on Port 9293 (with fallback to 8482 / 8082 / 82)
    SecurityContext? secContext;
    try {
      secContext = SecurityContext();
      secContext.useCertificateChainBytes(utf8.encode(SslCerts.certificatePem));
      secContext.usePrivateKeyBytes(utf8.encode(SslCerts.privateKeyPem));
    } catch (e) {
      debugPrint('[RemoteServer] SecurityContext error: $e');
    }

    if (secContext != null) {
      final candidateHttpsPorts = [9293, 8482, 8082, 82];
      for (final portCandidate in candidateHttpsPorts) {
        try {
          _httpsServer = await HttpServer.bindSecure(
            InternetAddress.anyIPv4,
            portCandidate,
            secContext,
          );
          _httpsPort = portCandidate;
          _isRunning = true;
          debugPrint('[RemoteServer] HTTPS running on https://$localIp:$_httpsPort');
          break;
        } catch (e) {
          debugPrint('[RemoteServer] Port $portCandidate bind failed: $e');
        }
      }

      _httpsServer?.listen(_handleHttpRequest, onError: (err) {
        debugPrint('[RemoteServer] HTTPS Server error: $err');
      });
    }
  }

  Future<void> _resolveLocalIp() async {
    try {
      final info = NetworkInfo();
      _localIp = await info.getWifiIP();
    } catch (e) {
      debugPrint('[RemoteServer] NetworkInfo error: $e');
    }

    if (_localIp == null || _localIp == '0.0.0.0' || _localIp == '127.0.0.1') {
      try {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLoopback: false,
        );
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback && addr.address.isNotEmpty) {
              _localIp = addr.address;
              return;
            }
          }
        }
      } catch (e) {
        debugPrint('[RemoteServer] Interface discovery error: $e');
      }
    }
  }

  void _handleHttpRequest(HttpRequest request) async {
    // Enable CORS for cross-origin or local network web requests
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    // WebSocket Endpoint
    if (request.uri.path == '/ws') {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        try {
          final socket = await WebSocketTransformer.upgrade(request);
          _handleWebSocket(socket);
        } catch (e) {
          debugPrint('[RemoteServer] WebSocket upgrade error: $e');
        }
      } else {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
      }
      return;
    }

    // Live MJPEG Video Stream (Capture Card)
    if (request.uri.path == '/stream.mjpg' || request.uri.path == '/video_feed') {
      _handleMjpegStream(request);
      return;
    }

    // Single Frame Snapshot (Capture Card)
    if (request.uri.path == '/snapshot.jpg') {
      if (_latestFrameBytes != null) {
        request.response.headers.contentType = ContentType('image', 'jpeg');
        request.response.headers.set(HttpHeaders.cacheControlHeader, 'no-cache, no-store, must-revalidate');
        request.response.add(_latestFrameBytes!);
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
      return;
    }

    // TV UI Screen Snapshot (Captures entire Android TV screen system-wide)
    if (request.uri.path == '/tv_screen.jpg') {
      try {
        final screenBytes = await SystemControlService.captureTvScreen();
        final bytesToSend = (screenBytes != null && screenBytes.isNotEmpty)
            ? screenBytes
            : _latestTvScreenBytes ?? _latestFrameBytes;

        if (bytesToSend != null && bytesToSend.isNotEmpty) {
          if (screenBytes != null && screenBytes.isNotEmpty) {
            _latestTvScreenBytes = screenBytes;
          }
          request.response.headers.contentType = ContentType('image', 'jpeg');
          request.response.headers.set(HttpHeaders.cacheControlHeader, 'no-cache, no-store, must-revalidate');
          request.response.headers.set('Pragma', 'no-cache');
          request.response.add(bytesToSend);
        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
      } catch (e) {
        if (_latestTvScreenBytes != null) {
          request.response.headers.contentType = ContentType('image', 'jpeg');
          request.response.add(_latestTvScreenBytes!);
        } else {
          request.response.statusCode = HttpStatus.internalServerError;
        }
      }
      await request.response.close();
      return;
    }

    // Web Controller Interface
    if (request.uri.path == '/' || request.uri.path == '/index.html') {
      final isHttps = request.requestedUri.scheme == 'https';
      final activePort = request.connectionInfo?.localPort ?? (isHttps ? _httpsPort : _httpPort);
      final html = WebControllerHtml.getHtml(
        tvName: 'Android TV',
        serverIp: localIp,
        port: activePort,
        isHttps: isHttps,
        httpsPort: _httpsPort,
      );
      request.response.headers.contentType = ContentType.html;
      request.response.write(html);
      await request.response.close();
      return;
    }

    // Status API
    if (request.uri.path == '/api/status') {
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'status': 'online',
        'clients': clientCount,
        'ip': localIp,
        'httpPort': _httpPort,
        'httpsPort': _httpsPort,
        'hasVideo': _latestFrameBytes != null,
        'accessibilityActive': await SystemControlService.isAccessibilityActive(),
      }));
      await request.response.close();
      return;
    }

    // 404
    request.response.statusCode = HttpStatus.notFound;
    request.response.write('Not Found');
    await request.response.close();
  }

  void _handleMjpegStream(HttpRequest request) {
    request.response.headers.set(
      HttpHeaders.contentTypeHeader,
      'multipart/x-mixed-replace; boundary=--frame',
    );
    request.response.headers.set(HttpHeaders.cacheControlHeader, 'no-cache, no-store, must-revalidate');
    request.response.headers.set(HttpHeaders.connectionHeader, 'close');
    request.response.headers.set('Pragma', 'no-cache');

    _mjpegClients.add(request.response);
    debugPrint('[RemoteServer] New MJPEG stream client. Total: ${_mjpegClients.length}');

    if (_latestFrameBytes != null) {
      _sendFrameToClient(request.response, _latestFrameBytes!);
    }

    request.response.done.then((_) {
      _mjpegClients.remove(request.response);
      debugPrint('[RemoteServer] MJPEG client disconnected. Total: ${_mjpegClients.length}');
    }).catchError((_) {
      _mjpegClients.remove(request.response);
    });
  }

  void _sendFrameToClient(HttpResponse client, Uint8List frameBytes) {
    try {
      client.add(ascii.encode('--frame\r\nContent-Type: image/jpeg\r\nContent-Length: ${frameBytes.length}\r\n\r\n'));
      client.add(frameBytes);
      client.add(ascii.encode('\r\n'));
    } catch (_) {
      _mjpegClients.remove(client);
    }
  }

  void broadcastFrame(Uint8List frameBytes) {
    _latestFrameBytes = frameBytes;

    if (_mjpegClients.isNotEmpty) {
      final dead = <HttpResponse>[];
      for (final client in _mjpegClients) {
        try {
          _sendFrameToClient(client, frameBytes);
        } catch (_) {
          dead.add(client);
        }
      }
      _mjpegClients.removeAll(dead);
    }

    if (_clients.isNotEmpty) {
      for (final client in _clients) {
        if (client.readyState == WebSocket.open) {
          try {
            client.add(frameBytes);
          } catch (_) {}
        }
      }
    }
  }

  void _handleWebSocket(WebSocket socket) {
    _clients.add(socket);
    debugPrint('[RemoteServer] WS Client connected. Total: ${_clients.length}');
    broadcastClientCount();

    if (_latestFrameBytes != null) {
      try {
        socket.add(_latestFrameBytes!);
      } catch (_) {}
    }

    socket.listen(
      (data) {
        if (data is String) {
          try {
            final jsonMap = jsonDecode(data) as Map<String, dynamic>;
            final action = jsonMap['action'] as String? ?? 'UNKNOWN';
            final payload = (jsonMap['payload'] as Map<String, dynamic>?) ?? {};

            final cmd = RemoteCommand(
              action: action,
              payload: payload,
              timestamp: DateTime.now(),
            );

            // Execute system-level commands directly so they work EVERYWHERE on the TV
            _dispatchSystemCommand(cmd);

            // Also broadcast to any in-app listeners (TvHomeScreen, TvBrowserScreen)
            _commandController.add(cmd);
          } catch (e) {
            debugPrint('[RemoteServer] Invalid WS payload: $data ($e)');
          }
        }
      },
      onDone: () {
        _clients.remove(socket);
        debugPrint('[RemoteServer] WS Client disconnected. Total: ${_clients.length}');
        broadcastClientCount();
      },
      onError: (err) {
        _clients.remove(socket);
        debugPrint('[RemoteServer] WS Client error: $err');
        broadcastClientCount();
      },
    );
  }

  void _dispatchSystemCommand(RemoteCommand cmd) {
    switch (cmd.action) {
      case 'SYS_TAP':
        final x = (cmd.payload['x'] as num?)?.toDouble() ?? _currentCursorX;
        final y = (cmd.payload['y'] as num?)?.toDouble() ?? _currentCursorY;
        _currentCursorX = x;
        _currentCursorY = y;
        SystemControlService.sendTap(x, y);
        break;
      case 'MOVE_CURSOR':
        final x = (cmd.payload['x'] as num?)?.toDouble() ?? _currentCursorX;
        final y = (cmd.payload['y'] as num?)?.toDouble() ?? _currentCursorY;
        _currentCursorX = x;
        _currentCursorY = y;
        SystemControlService.moveCursor(x, y);
        break;
      case 'MOUSE_MOVE':
        final dx = (cmd.payload['dx'] as num?)?.toDouble() ?? 0.0;
        final dy = (cmd.payload['dy'] as num?)?.toDouble() ?? 0.0;
        _currentCursorX = (_currentCursorX + dx * 2.2).clamp(0.0, 1920.0);
        _currentCursorY = (_currentCursorY + dy * 2.2).clamp(0.0, 1080.0);
        SystemControlService.moveCursor(_currentCursorX, _currentCursorY);
        break;
      case 'SWIPE':
        final startX = (cmd.payload['startX'] as num?)?.toDouble() ?? _currentCursorX;
        final startY = (cmd.payload['startY'] as num?)?.toDouble() ?? _currentCursorY;
        final endX = (cmd.payload['endX'] as num?)?.toDouble() ?? _currentCursorX;
        final endY = (cmd.payload['endY'] as num?)?.toDouble() ?? _currentCursorY;
        final duration = (cmd.payload['duration'] as num?)?.toInt() ?? 200;
        SystemControlService.swipe(startX, startY, endX, endY, duration: duration);
        break;
      case 'SYS_HOME':
      case 'HOME':
        SystemControlService.sendGlobalAction('HOME');
        break;
      case 'SYS_BACK':
      case 'BACK':
        SystemControlService.sendGlobalAction('BACK');
        break;
      case 'SYS_RECENTS':
      case 'RECENTS':
        SystemControlService.sendGlobalAction('RECENTS');
        break;
      case 'SYS_NOTIF':
        SystemControlService.sendGlobalAction('NOTIFICATIONS');
        break;
      case 'SYS_POWER':
        SystemControlService.sendGlobalAction('POWER');
        break;
      case 'SYS_UP':
      case 'UP':
        SystemControlService.sendKeyevent(SystemControlService.keyDpadUp);
        break;
      case 'SYS_DOWN':
      case 'DOWN':
        SystemControlService.sendKeyevent(SystemControlService.keyDpadDown);
        break;
      case 'SYS_LEFT':
      case 'LEFT':
        SystemControlService.sendKeyevent(SystemControlService.keyDpadLeft);
        break;
      case 'SYS_RIGHT':
      case 'RIGHT':
        SystemControlService.sendKeyevent(SystemControlService.keyDpadRight);
        break;
      case 'SYS_SELECT':
      case 'SELECT':
        SystemControlService.sendKeyevent(SystemControlService.keyDpadCenter);
        break;
      case 'VOL_UP':
        SystemControlService.sendKeyevent(SystemControlService.keyVolumeUp);
        break;
      case 'VOL_DOWN':
        SystemControlService.sendKeyevent(SystemControlService.keyVolumeDown);
        break;
      case 'MUTE':
        SystemControlService.sendKeyevent(SystemControlService.keyVolumeMute);
        break;
      case 'PLAY_PAUSE':
        SystemControlService.sendKeyevent(SystemControlService.keyMediaPlayPause);
        break;
      case 'TYPE_TEXT':
        final text = cmd.payload['text']?.toString() ?? '';
        if (text.isNotEmpty) {
          SystemControlService.sendInputText(text);
        }
        break;
    }
  }

  void broadcastState(Map<String, dynamic> state) {
    state['clientCount'] = clientCount;
    final payload = jsonEncode(state);
    for (final client in _clients) {
      if (client.readyState == WebSocket.open) {
        try {
          client.add(payload);
        } catch (e) {
          debugPrint('[RemoteServer] Failed to send state to client: $e');
        }
      }
    }
  }

  void broadcastClientCount() {
    broadcastState({'clientCount': clientCount});
  }

  Future<void> stop() async {
    for (final client in _clients) {
      try {
        await client.close();
      } catch (_) {}
    }
    _clients.clear();

    for (final client in _mjpegClients) {
      try {
        await client.close();
      } catch (_) {}
    }
    _mjpegClients.clear();

    await _httpServer?.close(force: true);
    await _httpsServer?.close(force: true);
    _httpServer = null;
    _httpsServer = null;
    _isRunning = false;
    debugPrint('[RemoteServer] Stopped');
  }

  void dispose() {
    stop();
    _commandController.close();
  }
}
