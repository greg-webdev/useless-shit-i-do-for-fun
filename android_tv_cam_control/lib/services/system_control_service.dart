import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SystemControlService {
  static const MethodChannel _channel =
      MethodChannel('com.antigravity.tvcapture/system_control');

  static Future<bool> isAccessibilityActive() async {
    try {
      return await _channel.invokeMethod<bool>('isAccessibilityActive') ?? false;
    } catch (e) {
      debugPrint('[SystemControl] isAccessibilityActive error: $e');
      return false;
    }
  }

  static Future<void> sendGlobalAction(String action) async {
    try {
      await _channel.invokeMethod('globalAction', {'action': action});
    } catch (e) {
      debugPrint('[SystemControl] sendGlobalAction error: $e');
    }
  }

  static Future<void> sendKeyevent(int keyCode) async {
    try {
      await _channel.invokeMethod('keyevent', {'keyCode': keyCode});
    } catch (e) {
      debugPrint('[SystemControl] sendKeyevent error: $e');
    }
  }

  static Future<void> sendTap(double x, double y) async {
    try {
      await _channel.invokeMethod('tap', {'x': x, 'y': y});
    } catch (e) {
      debugPrint('[SystemControl] sendTap error: $e');
    }
  }

  static Future<void> sendInputText(String text) async {
    try {
      await _channel.invokeMethod('inputText', {'text': text});
    } catch (e) {
      debugPrint('[SystemControl] sendInputText error: $e');
    }
  }

  static Future<void> moveCursor(double x, double y) async {
    try {
      await _channel.invokeMethod('moveCursor', {'x': x, 'y': y});
    } catch (e) {
      debugPrint('[SystemControl] moveCursor error: $e');
    }
  }

  static Future<void> swipe(double startX, double startY, double endX, double endY, {int duration = 200}) async {
    try {
      await _channel.invokeMethod('swipe', {
        'startX': startX,
        'startY': startY,
        'endX': endX,
        'endY': endY,
        'duration': duration,
      });
    } catch (e) {
      debugPrint('[SystemControl] swipe error: $e');
    }
  }

  static Future<Uint8List?> captureTvScreen() async {
    try {
      final res = await _channel.invokeMethod<Uint8List>('captureTvScreen');
      return res;
    } catch (e) {
      debugPrint('[SystemControl] captureTvScreen error: $e');
      return null;
    }
  }

  // Standard Android KeyCodes
  static const int keyDpadUp = 19;
  static const int keyDpadDown = 20;
  static const int keyDpadLeft = 21;
  static const int keyDpadRight = 22;
  static const int keyDpadCenter = 23;
  static const int keyVolumeUp = 24;
  static const int keyVolumeDown = 25;
  static const int keyVolumeMute = 164;
  static const int keyMediaPlayPause = 85;
  static const int keyHome = 3;
  static const int keyBack = 4;
  static const int keyMenu = 82;
}
