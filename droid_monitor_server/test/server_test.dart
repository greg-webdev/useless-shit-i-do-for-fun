import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:droid_monitor_server/services/https_server_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  test('HTTPS Server Full End-to-End Verification on Port 1213', () async {
    final server = HttpsServerService();
    final started = await server.start(port: 1213);
    expect(started, isTrue, reason: 'Server must start on port 1213');
    expect(server.isRunning, isTrue);

    // Create HttpClient that accepts self-signed certificates
    final client = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;

    try {
      // 1. GET / (Web Dashboard)
      final reqHome = await client.getUrl(Uri.parse('https://127.0.0.1:1213/'));
      final resHome = await reqHome.close();
      expect(resHome.statusCode, equals(HttpStatus.ok));
      final homeHtml = await utf8.decoder.bind(resHome).join();
      expect(homeHtml.contains('DroidMonitor'), isTrue);
      expect(homeHtml.contains('Task Manager'), isTrue);
      expect(homeHtml.contains('CPU Utilization'), isTrue);
      expect(homeHtml.contains('File Hosting & Serving'), isTrue);

      // 2. GET /api/stats (Telemetry JSON)
      final reqStats = await client.getUrl(Uri.parse('https://127.0.0.1:1213/api/stats'));
      final resStats = await reqStats.close();
      expect(resStats.statusCode, equals(HttpStatus.ok));
      final statsJson = jsonDecode(await utf8.decoder.bind(resStats).join());
      expect(statsJson['cpu'], isNotNull);
      expect(statsJson['memory'], isNotNull);
      expect(statsJson['thermal'], isNotNull);

      // 3. GET /api/tasks (Process / Task Manager list)
      final reqTasks = await client.getUrl(Uri.parse('https://127.0.0.1:1213/api/tasks'));
      final resTasks = await reqTasks.close();
      expect(resTasks.statusCode, equals(HttpStatus.ok));
      final tasksJson = jsonDecode(await utf8.decoder.bind(resTasks).join());
      expect(tasksJson is List, isTrue);

      // 4. POST /api/upload (File upload)
      final testContent = 'Hello Antigravity DroidMonitor File Server 1213!';
      final reqUpload = await client.postUrl(Uri.parse('https://127.0.0.1:1213/api/upload?filename=hello_world.txt'));
      reqUpload.headers.contentType = ContentType.text;
      reqUpload.add(utf8.encode(testContent));
      final resUpload = await reqUpload.close();
      expect(resUpload.statusCode, equals(HttpStatus.created));

      // 5. GET /api/files (File list contains uploaded file)
      final reqFiles = await client.getUrl(Uri.parse('https://127.0.0.1:1213/api/files'));
      final resFiles = await reqFiles.close();
      expect(resFiles.statusCode, equals(HttpStatus.ok));
      final filesJson = jsonDecode(await utf8.decoder.bind(resFiles).join()) as List;
      expect(filesJson.any((f) => f['name'] == 'hello_world.txt'), isTrue);

      // 6. GET /files/hello_world.txt (Download served file)
      final reqDownload = await client.getUrl(Uri.parse('https://127.0.0.1:1213/files/hello_world.txt'));
      final resDownload = await reqDownload.close();
      expect(resDownload.statusCode, equals(HttpStatus.ok));
      final downloadedText = await utf8.decoder.bind(resDownload).join();
      expect(downloadedText, equals(testContent));

      // 7. DELETE /api/files/hello_world.txt (Clean up uploaded test file)
      final reqDelete = await client.deleteUrl(Uri.parse('https://127.0.0.1:1213/api/files/hello_world.txt'));
      final resDelete = await reqDelete.close();
      expect(resDelete.statusCode, equals(HttpStatus.ok));

      // 8. Verify Demo Files Auto-Seeded and Protected
      expect(filesJson.any((f) => f['name'] == 'canvasdemo.html' && f['isProtected'] == true), isTrue);
      expect(filesJson.any((f) => f['name'] == 'sanddemo.html' && f['isProtected'] == true), isTrue);
      expect(filesJson.any((f) => f['name'] == 'particledemo.html' && f['isProtected'] == true), isTrue);

      // 9. Verify Protected File Deletion is Forbidden (403)
      final reqDeleteProtected = await client.deleteUrl(Uri.parse('https://127.0.0.1:1213/api/files/canvasdemo.html'));
      final resDeleteProtected = await reqDeleteProtected.close();
      expect(resDeleteProtected.statusCode, equals(HttpStatus.forbidden));

      // 10. Verify Serving Demo HTML files
      final reqCanvasDemo = await client.getUrl(Uri.parse('https://127.0.0.1:1213/files/canvasdemo.html'));
      final resCanvasDemo = await reqCanvasDemo.close();
      expect(resCanvasDemo.statusCode, equals(HttpStatus.ok));
      final canvasHtml = await utf8.decoder.bind(resCanvasDemo).join();
      expect(canvasHtml.contains('DroidCanvas'), isTrue);

      final reqSandDemo = await client.getUrl(Uri.parse('https://127.0.0.1:1213/files/sanddemo.html'));
      final resSandDemo = await reqSandDemo.close();
      expect(resSandDemo.statusCode, equals(HttpStatus.ok));
      final sandHtml = await utf8.decoder.bind(resSandDemo).join();
      expect(sandHtml.contains('DroidSand'), isTrue);

      final reqParticleDemo = await client.getUrl(Uri.parse('https://127.0.0.1:1213/files/particledemo.html'));
      final resParticleDemo = await reqParticleDemo.close();
      expect(resParticleDemo.statusCode, equals(HttpStatus.ok));
      final particleHtml = await utf8.decoder.bind(resParticleDemo).join();
      expect(particleHtml.contains('DroidVortex'), isTrue);

      // 11. WebSocket Connection to /ws/canvas
      final wsCanvas = await WebSocket.connect(
        'wss://127.0.0.1:1213/ws/canvas',
        customClient: client,
      );
      expect(wsCanvas.readyState, equals(WebSocket.open));
      final canvasMsgCompleter = Completer<Map<String, dynamic>>();
      wsCanvas.listen((data) {
        if (!canvasMsgCompleter.isCompleted) {
          canvasMsgCompleter.complete(jsonDecode(data.toString()) as Map<String, dynamic>);
        }
      });
      final canvasInitial = await canvasMsgCompleter.future.timeout(const Duration(seconds: 3));
      expect(canvasInitial['type'], equals('presence'));
      expect(canvasInitial['room'], equals('canvas'));
      expect(canvasInitial['count'], greaterThanOrEqualTo(1));
      await wsCanvas.close();

      // 12. WebSocket Connection to /ws/sand (Multiplayer Sandbox)
      final wsSand = await WebSocket.connect(
        'wss://127.0.0.1:1213/ws/sand',
        customClient: client,
      );
      expect(wsSand.readyState, equals(WebSocket.open));
      final sandMsgCompleter = Completer<Map<String, dynamic>>();
      wsSand.listen((data) {
        if (!sandMsgCompleter.isCompleted) {
          sandMsgCompleter.complete(jsonDecode(data.toString()) as Map<String, dynamic>);
        }
      });
      final sandInitial = await sandMsgCompleter.future.timeout(const Duration(seconds: 3));
      expect(sandInitial['type'], equals('presence'));
      expect(sandInitial['room'], equals('sand'));
      expect(sandInitial['count'], greaterThanOrEqualTo(1));
      await wsSand.close();

      // 13. WebSocket Connection to /ws/particles (Multiplayer Vortex)
      final wsParticles = await WebSocket.connect(
        'wss://127.0.0.1:1213/ws/particles',
        customClient: client,
      );
      expect(wsParticles.readyState, equals(WebSocket.open));
      final particlesMsgCompleter = Completer<Map<String, dynamic>>();
      wsParticles.listen((data) {
        if (!particlesMsgCompleter.isCompleted) {
          particlesMsgCompleter.complete(jsonDecode(data.toString()) as Map<String, dynamic>);
        }
      });
      final particlesInitial = await particlesMsgCompleter.future.timeout(const Duration(seconds: 3));
      expect(particlesInitial['type'], equals('presence'));
      expect(particlesInitial['room'], equals('particles'));
      expect(particlesInitial['count'], greaterThanOrEqualTo(1));
      await wsParticles.close();

      // 14. Verify Optional Demos Auto-Seeded & Marked as Optional
      expect(filesJson.any((f) => f['name'] == 'spacedemo.html' && f['isOptional'] == true && f['isProtected'] == false), isTrue);
      expect(filesJson.any((f) => f['name'] == 'synthdemo.html' && f['isOptional'] == true && f['isProtected'] == false), isTrue);
      expect(filesJson.any((f) => f['name'] == 'mazedemo.html' && f['isOptional'] == true && f['isProtected'] == false), isTrue);

      // 15. Verify Serving Optional Demo HTML files
      final reqSpace = await client.getUrl(Uri.parse('https://127.0.0.1:1213/files/spacedemo.html'));
      final resSpace = await reqSpace.close();
      expect(resSpace.statusCode, equals(HttpStatus.ok));
      final spaceHtml = await utf8.decoder.bind(resSpace).join();
      expect(spaceHtml.contains('DroidSpace'), isTrue);

      final reqSynth = await client.getUrl(Uri.parse('https://127.0.0.1:1213/files/synthdemo.html'));
      final resSynth = await reqSynth.close();
      expect(resSynth.statusCode, equals(HttpStatus.ok));
      final synthHtml = await utf8.decoder.bind(resSynth).join();
      expect(synthHtml.contains('DroidSynth'), isTrue);

      final reqMaze = await client.getUrl(Uri.parse('https://127.0.0.1:1213/files/mazedemo.html'));
      final resMaze = await reqMaze.close();
      expect(resMaze.statusCode, equals(HttpStatus.ok));
      final mazeHtml = await utf8.decoder.bind(resMaze).join();
      expect(mazeHtml.contains('DroidMaze'), isTrue);

      // 16. Verify Optional Demos WebSocket Connections
      final wsSpace = await WebSocket.connect(
        'wss://127.0.0.1:1213/ws/space',
        customClient: client,
      );
      expect(wsSpace.readyState, equals(WebSocket.open));
      await wsSpace.close();

      final wsSynth = await WebSocket.connect(
        'wss://127.0.0.1:1213/ws/synth',
        customClient: client,
      );
      expect(wsSynth.readyState, equals(WebSocket.open));
      await wsSynth.close();

      final wsMaze = await WebSocket.connect(
        'wss://127.0.0.1:1213/ws/maze',
        customClient: client,
      );
      expect(wsMaze.readyState, equals(WebSocket.open));
      await wsMaze.close();

      // 17. Verify Optional Demo can be deleted and then restored
      final reqDelOptional = await client.deleteUrl(Uri.parse('https://127.0.0.1:1213/api/files/spacedemo.html'));
      final resDelOptional = await reqDelOptional.close();
      expect(resDelOptional.statusCode, equals(HttpStatus.ok));

      final reqRestore = await client.postUrl(Uri.parse('https://127.0.0.1:1213/api/demos/restore'));
      final resRestore = await reqRestore.close();
      expect(resRestore.statusCode, equals(HttpStatus.ok));

      final reqCheckRestored = await client.getUrl(Uri.parse('https://127.0.0.1:1213/files/spacedemo.html'));
      final resCheckRestored = await reqCheckRestored.close();
      expect(resCheckRestored.statusCode, equals(HttpStatus.ok));
    } finally {
      client.close(force: true);
      await server.stop();
    }
  });
}
