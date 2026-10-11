import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/app/app.dart';

void main() {
  testWidgets('App inicia en SplashScreen y transiciona a LoginScreen',
      (WidgetTester tester) async {
    // Construir la aplicación
    await tester.pumpWidget(const MyApp());

    // Verificar que inicialmente se muestra el SplashScreen con el título BRODEVS
    expect(find.text('BRODEVS'), findsOneWidget);

    // Avanzar el tiempo para completar las animaciones y la inicialización
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verificar que tras el splash navega a la pantalla de Login con Discord
    expect(find.text('¡Bienvenido!'), findsOneWidget);
    expect(find.text('Continuar con Discord'), findsOneWidget);
  });
}
