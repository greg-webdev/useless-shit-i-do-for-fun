import 'package:flutter_test/flutter_test.dart';
import 'package:droid_monitor_server/main.dart';

void main() {
  testWidgets('DroidMonitorApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DroidMonitorApp());

    // Verify title and port header are displayed
    expect(find.text('DroidMonitor'), findsOneWidget);
    expect(find.text('HTTPS Port 1212'), findsOneWidget);
  });
}
