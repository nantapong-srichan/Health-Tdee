import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/main.dart'; 
import 'package:health_app/session_data.dart'; 
import 'package:provider/provider.dart';

// ลบ import 'package:camera/camera.dart'; ออกแล้ว

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => SessionData(),
        child: const MyApp(),
      ),
    );


    expect(find.text('0'), findsNothing); // แก้ไขตามจริง (แอปเราไม่มีเลข 0)
    // expect(find.text('1'), findsNothing);


    expect(find.text("Let's Get Started"), findsOneWidget);
  });
}