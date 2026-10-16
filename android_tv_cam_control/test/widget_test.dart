import 'package:flutter_test/flutter_test.dart';
import 'package:android_tv_cam_control/services/remote_server.dart';
import 'package:android_tv_cam_control/services/web_controller_html.dart';

void main() {
  group('RemoteServer & WebController Tests', () {
    test('RemoteCommand serializes and stores action correctly', () {
      final now = DateTime.now();
      final cmd = RemoteCommand(
        action: 'UP',
        payload: {'intensity': 1},
        timestamp: now,
      );

      expect(cmd.action, equals('UP'));
      expect(cmd.payload['intensity'], equals(1));
      expect(cmd.timestamp, equals(now));
      expect(cmd.toString(), contains('RemoteCommand(UP'));
    });

    test('WebControllerHtml produces valid offline web app with viewport and script', () {
      final html = WebControllerHtml.getHtml(
        tvName: 'Living Room TV',
        serverIp: '192.168.1.100',
        port: 8080,
      );

      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('Living Room TV'));
      expect(html, contains('data-cmd="UP"'));
      expect(html, contains('data-cmd="DOWN"'));
      expect(html, contains('data-cmd="SELECT"'));
      expect(html, contains('localVideo'));
      expect(html, contains('getUserMedia'));
      expect(html, contains('videoSourceSelect'));
      expect(html, contains('WebSocket'));
      expect(html, contains('/ws'));
    });

    test('RemoteServer default state before start', () {
      final server = RemoteServer();
      expect(server.isRunning, isFalse);
      expect(server.clientCount, equals(0));
      expect(server.port, equals(8080));
    });
  });
}
