import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/app/app.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our home screen loads.
    expect(find.text('Inicio'), findsOneWidget);
  });
}
