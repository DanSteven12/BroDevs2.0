import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/app/app.dart';

void main() {
  testWidgets('App inicia en SplashScreen y transiciona a LoginScreen',
      (WidgetTester tester) async {
    // Construir la aplicación
    await tester.pumpWidget(const MyApp());

    // Verificar que inicialmente se muestra el SplashScreen con el título de la app
    expect(find.text('Mi App'), findsOneWidget);
    expect(find.text('Tu plataforma inteligente'), findsOneWidget);

    // Avanzar el tiempo para completar las animaciones y la inicialización
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verificar que tras el splash navega a la pantalla de bienvenida / login (Fase 1)
    expect(find.text('¡Bienvenido!'), findsOneWidget);
    expect(find.text('Iniciar sesión con Discord'), findsOneWidget);
  });
}
