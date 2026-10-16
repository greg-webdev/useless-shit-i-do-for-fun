import 'package:flutter_test/flutter_test.dart';
import 'package:simple_camera_app/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SimpleCameraApp());
    expect(find.text('Select Camera'), findsOneWidget);
  });
}
