import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/camera_selection_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set default system overlay style for dark background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0F1D),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const SimpleCameraApp());
}

class SimpleCameraApp extends StatelessWidget {
  const SimpleCameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Camera',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0F1D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F2FE),
          secondary: Color(0xFF4FACFE),
          surface: Color(0xFF131C2E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0F1D),
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const CameraSelectionScreen(),
    );
  }
}
