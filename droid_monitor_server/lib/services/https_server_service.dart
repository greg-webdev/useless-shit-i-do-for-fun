import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'file_storage_service.dart';
import 'ssl_certs.dart';
import 'system_telemetry_service.dart';
import 'web_dashboard.dart';

class HttpsServerService {
  static final HttpsServerService _instance = HttpsServerService._internal();
  factory HttpsServerService() => _instance;
  HttpsServerService._internal();

  HttpServer? _server;
  bool _isRunning = false;
  int _port = 1212;
  final List<String> _serverUrls = [];

  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get statusStream => _statusController.stream;

  bool get isRunning => _isRunning;
  int get port => _port;
  List<String> get serverUrls => List.unmodifiable(_serverUrls);

  Future<bool> start({int port = 1212}) async {
    if (_isRunning) return true;
    _port = port;

    SecurityContext? secContext;
    try {
      secContext = SecurityContext();
      secContext.useCertificateChainBytes(utf8.encode(SslCerts.certificatePem));
      secContext.usePrivateKeyBytes(utf8.encode(SslCerts.privateKeyPem));
    } catch (e) {
      debugPrint('[HttpsServer] SecurityContext creation error: $e');
      return false;
    }

    try {
      _server = await HttpServer.bindSecure(
        InternetAddress.anyIPv4,
        _port,
        secContext,
      );
      _isRunning = true;
      _statusController.add(true);
      await _resolveUrls();

      try {
        await SystemTelemetryService.startForegroundService();
      } catch (_) {}

      debugPrint('[HttpsServer] Secure HTTPS server listening on port $_port');
      _server!.listen(_handleRequest, onError: (err) {
        debugPrint('[HttpsServer] Server error: $err');
      });
      return true;
    } catch (e) {
      debugPrint('[HttpsServer] Failed to bind port $_port: $e');
      _isRunning = false;
      _statusController.add(false);
      return false;
    }
  }

  static final Map<String, Set<WebSocket>> _demoRooms = {};

  Future<void> stop() async {
    try {
      await SystemTelemetryService.stopForegroundService();
    } catch (_) {}

    for (final clients in _demoRooms.values) {
      for (final ws in clients) {
        try {
          await ws.close();
        } catch (_) {}
      }
    }
    _demoRooms.clear();

    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
    _isRunning = false;
    _serverUrls.clear();
    _statusController.add(false);
    debugPrint('[HttpsServer] Stopped');
  }

  Future<void> _resolveUrls() async {
    _serverUrls.clear();
    final ips = <String>{};

    try {
      final wifiIp = await NetworkInfo().getWifiIP();
      if (wifiIp != null && wifiIp.isNotEmpty && wifiIp != '0.0.0.0') {
        ips.add(wifiIp);
      }
    } catch (_) {}

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && addr.address.isNotEmpty) {
            ips.add(addr.address);
          }
        }
      }
    } catch (_) {}

    if (ips.isEmpty) {
      ips.add('127.0.0.1');
    }

    for (final ip in ips) {
      _serverUrls.add('https://$ip:$_port');
    }
  }

  Future<void> _handleRequest(HttpRequest req) async {
    final res = req.response;

    // CORS & Security headers
    res.headers.set('Access-Control-Allow-Origin', '*');
    res.headers.set('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
    res.headers.set('Access-Control-Allow-Headers', 'Content-Type, Range, Authorization');
    res.headers.set('Access-Control-Expose-Headers', 'Content-Range, Content-Length, Accept-Ranges');

    if (req.method == 'OPTIONS') {
      res.statusCode = HttpStatus.ok;
      await res.close();
      return;
    }

    final path = req.uri.path;

    try {
      // WebSocket endpoints for collaborative demos: /ws/:room (canvas, sand, particles)
      if (path.startsWith('/ws/') && WebSocketTransformer.isUpgradeRequest(req)) {
        final room = path.substring(4).split('/')[0].trim().toLowerCase();
        await _handleDemoWebSocket(req, room.isEmpty ? 'canvas' : room);
        return;
      }

      if (path == '/' || path == '/index.html') {
        res.headers.contentType = ContentType.html;
        res.write(WebDashboard.html);
        await res.close();
        return;
      }

      // API: Stats
      if (path == '/api/stats' && req.method == 'GET') {
        final stats = await SystemTelemetryService.getStats();
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode(stats));
        await res.close();
        return;
      }

      // API: Tasks
      if (path == '/api/tasks' && req.method == 'GET') {
        final tasks = await SystemTelemetryService.getTasks();
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode(tasks));
        await res.close();
        return;
      }

      // API: Live Screen Capture (Temporary Screenshot)
      if (path == '/api/screenshot' && req.method == 'GET') {
        final bytes = await SystemTelemetryService.captureScreenshot();
        if (bytes != null && bytes.isNotEmpty) {
          final isPng = bytes.length > 4 &&
              bytes[0] == 0x89 &&
              bytes[1] == 0x50 &&
              bytes[2] == 0x4E &&
              bytes[3] == 0x47;
          res.headers.contentType = isPng ? ContentType('image', 'png') : ContentType('image', 'jpeg');
          res.headers.set('Cache-Control', 'no-cache, no-store, must-revalidate');
          res.headers.set('Pragma', 'no-cache');
          res.headers.set('Expires', '0');

          if (req.uri.queryParameters['download'] == '1') {
            final ext = isPng ? 'png' : 'jpg';
            final filename = 'screenshot_${DateTime.now().millisecondsSinceEpoch}.$ext';
            res.headers.set('Content-Disposition', 'attachment; filename="$filename"');
          }

          res.headers.contentLength = bytes.length;
          res.add(bytes);
          await res.close();
          return;
        } else {
          res.statusCode = HttpStatus.serviceUnavailable;
          res.headers.contentType = ContentType.json;
          res.write(jsonEncode({'error': 'Screenshot capture failed'}));
          await res.close();
          return;
        }
      }

      // API: Kill task
      if (path.startsWith('/api/tasks/') && req.method == 'DELETE') {
        final pidStr = path.replaceFirst('/api/tasks/', '');
        final pid = int.tryParse(pidStr);
        if (pid != null) {
          final ok = await SystemTelemetryService.killTask(pid);
          res.headers.contentType = ContentType.json;
          res.write(jsonEncode({'success': ok, 'pid': pid}));
        } else {
          res.statusCode = HttpStatus.badRequest;
          res.write(jsonEncode({'error': 'Invalid PID'}));
        }
        await res.close();
        return;
      }

      // API: Files list
      if (path == '/api/files' && req.method == 'GET') {
        final files = await FileStorageService.listFiles();
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode(files));
        await res.close();
        return;
      }

      // API: File Upload
      if (path == '/api/upload' && req.method == 'POST') {
        final rawFilename = req.uri.queryParameters['filename'] ??
            'upload_${DateTime.now().millisecondsSinceEpoch}';

        final file = await FileStorageService.saveFileFromStream(rawFilename, req);
        if (file != null) {
          res.statusCode = HttpStatus.created;
          res.headers.contentType = ContentType.json;
          res.write(jsonEncode({
            'success': true,
            'filename': file.uri.pathSegments.last,
            'size': await file.length(),
          }));
        } else {
          res.statusCode = HttpStatus.internalServerError;
          res.write(jsonEncode({'error': 'Failed to save file'}));
        }
        await res.close();
        return;
      }

      // API: Delete File
      if (path.startsWith('/api/files/') && req.method == 'DELETE') {
        final rawFilename = Uri.decodeComponent(path.replaceFirst('/api/files/', ''));
        if (FileStorageService.isProtected(rawFilename)) {
          res.statusCode = HttpStatus.forbidden;
          res.headers.contentType = ContentType.json;
          res.write(jsonEncode({'error': 'Protected demo file cannot be deleted', 'filename': rawFilename}));
          await res.close();
          return;
        }
        final ok = await FileStorageService.deleteFile(rawFilename);
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({'success': ok, 'filename': rawFilename}));
        await res.close();
        return;
      }

      // API: Restore/Reinstall Optional Demos
      if (path == '/api/demos/restore' && req.method == 'POST') {
        await FileStorageService.restoreOptionalDemos();
        res.headers.contentType = ContentType.json;
        res.write(jsonEncode({'success': true, 'message': 'Optional demos restored successfully'}));
        await res.close();
        return;
      }

      // Direct File Serving / Streaming
      if (path.startsWith('/files/')) {
        final rawFilename = Uri.decodeComponent(path.replaceFirst('/files/', ''));
        final file = await FileStorageService.getFile(rawFilename);

        if (file == null || !await file.exists()) {
          res.statusCode = HttpStatus.notFound;
          res.headers.contentType = ContentType.text;
          res.write('File not found');
          await res.close();
          return;
        }

        final fileSize = await file.length();
        final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
        res.headers.set('Accept-Ranges', 'bytes');
        res.headers.set('Content-Type', mimeType);

        final rangeHeader = req.headers.value('Range');
        if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
          // HTTP 206 Partial Content for video/audio seeking
          final parts = rangeHeader.replaceFirst('bytes=', '').split('-');
          final start = int.tryParse(parts[0]) ?? 0;
          final end = parts.length > 1 && parts[1].isNotEmpty
              ? (int.tryParse(parts[1]) ?? fileSize - 1)
              : fileSize - 1;

          if (start <= end && end < fileSize) {
            res.statusCode = HttpStatus.partialContent;
            res.headers.set('Content-Range', 'bytes $start-$end/$fileSize');
            res.headers.contentLength = (end - start) + 1;

            final stream = file.openRead(start, end + 1);
            await res.addStream(stream);
            await res.close();
            return;
          }
        }

        // Full file stream
        res.headers.contentLength = fileSize;
        await res.addStream(file.openRead());
        await res.close();
        return;
      }

      // Default 404
      res.statusCode = HttpStatus.notFound;
      res.headers.contentType = ContentType.text;
      res.write('Not found');
      await res.close();
    } catch (e) {
      debugPrint('[HttpsServer] Request handling exception: $e');
      try {
        res.statusCode = HttpStatus.internalServerError;
        res.write('Internal Server Error: $e');
        await res.close();
      } catch (_) {}
    }
  }

  Future<void> _handleDemoWebSocket(HttpRequest req, String room) async {
    try {
      final ws = await WebSocketTransformer.upgrade(req);
      final clients = _demoRooms.putIfAbsent(room, () => <WebSocket>{});
      clients.add(ws);
      debugPrint('[DemoWS] Client connected to room "$room". Active: ${clients.length}');

      // Send initial presence count
      ws.add(jsonEncode({
        'type': 'presence',
        'room': room,
        'count': clients.length,
      }));

      // Broadcast user count update to peers in room
      _broadcastToRoom(room, {
        'type': 'user_count',
        'room': room,
        'count': clients.length,
      }, sender: ws);

      ws.listen((data) {
        // Forward drawing strokes, sandbox elements, particles to other peers in this room
        for (final client in clients) {
          if (client != ws && client.readyState == WebSocket.open) {
            client.add(data);
          }
        }
      }, onDone: () {
        clients.remove(ws);
        if (clients.isEmpty) {
          _demoRooms.remove(room);
        } else {
          _broadcastToRoom(room, {
            'type': 'user_count',
            'room': room,
            'count': clients.length,
          });
        }
        debugPrint('[DemoWS] Client disconnected from room "$room". Active: ${clients.length}');
      }, onError: (err) {
        clients.remove(ws);
        debugPrint('[DemoWS] Error in room "$room": $err');
      });
    } catch (e) {
      debugPrint('[DemoWS] Upgrade error in room "$room": $e');
      try {
        req.response.statusCode = HttpStatus.badRequest;
        await req.response.close();
      } catch (_) {}
    }
  }

  void _broadcastToRoom(String room, Map<String, dynamic> msg, {WebSocket? sender}) {
    final clients = _demoRooms[room];
    if (clients == null || clients.isEmpty) return;
    final payload = jsonEncode(msg);
    for (final client in clients) {
      if (client != sender && client.readyState == WebSocket.open) {
        client.add(payload);
      }
    }
  }
}
