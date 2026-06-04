import 'package:flutter_test/flutter_test.dart';
import 'package:whatsapp_clone/main.dart';

void main() {
  testWidgets('App displays login screen when not authenticated', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('WhatsApp Clone'), findsOneWidget);
  });
}
