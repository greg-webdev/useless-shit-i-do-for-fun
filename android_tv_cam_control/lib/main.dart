import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'screens/tv_home_screen.dart';
import 'services/camera_service.dart';
import 'services/remote_server.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent TV from sleeping or dimming while displaying capture card feed
  try {
    await WakelockPlus.enable();
  } catch (e) {
    debugPrint('WakelockPlus init error: $e');
  }

  // Set immersive fullscreen mode on TV
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final cameraService = CameraService();
  final remoteServer = RemoteServer();

  // Start embedded HTTP & WebSocket Remote Server
  await remoteServer.start(port: 8080);

  // Pipe capture card frames directly to remote server for mobile display
  cameraService.onFrameAvailable = (frameBytes) {
    remoteServer.broadcastFrame(frameBytes);
  };

  // Initialize camera / capture card engine
  await cameraService.init();

  runApp(TvCaptureApp(
    cameraService: cameraService,
    remoteServer: remoteServer,
  ));
}

class TvCaptureApp extends StatelessWidget {
  final CameraService cameraService;
  final RemoteServer remoteServer;

  const TvCaptureApp({
    super.key,
    required this.cameraService,
    required this.remoteServer,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TV Capture & Remote',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F2FE),
          secondary: Color(0xFF4FACFE),
          surface: Color(0xFF0F172A),
        ),
        focusColor: const Color(0xFF00F2FE).withValues(alpha: 0.3),
        highlightColor: const Color(0xFF00F2FE).withValues(alpha: 0.2),
        useMaterial3: true,
      ),
      home: TvHomeScreen(
        cameraService: cameraService,
        remoteServer: remoteServer,
      ),
    );
  }
}
