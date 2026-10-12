import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/features/auth/data/models/discord_user.dart';
import 'package:mi_app/features/auth/presentation/screens/login_screen.dart';
import 'package:mi_app/features/auth/presentation/viewmodels/auth_controller.dart';

class MockAuthController extends ChangeNotifier implements AuthController {
  final bool _isLoading = false;
  String? _errorMessage;
  bool loginCalled = false;

  @override
  bool get isLoading => _isLoading;

  @override
  DiscordUser? get currentUser => null;

  @override
  ValueNotifier<DiscordUser?> get userListenable => ValueNotifier<DiscordUser?>(null);

  @override
  String? get errorMessage => _errorMessage;

  @override
  Future<bool> login({String? redirectUri}) async {
    loginCalled = true;
    return false;
  }

  @override
  Future<void> logout() async {}

  @override
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

void main() {
  Widget buildTestWidget({required AuthController controller}) {
    return MaterialApp(
      home: LoginScreen(authController: controller),
    );
  }

  testWidgets('LoginScreen muestra los componentes de diseño profesional y Discord abajo',
      (WidgetTester tester) async {
    final mockController = MockAuthController();

    await tester.pumpWidget(buildTestWidget(controller: mockController));
    await tester.pumpAndSettle();

    // 1. Encabezado e identidad
    expect(find.text('BroDevs'), findsOneWidget);
    expect(find.text('¡Bienvenido!'), findsOneWidget);

    // 2. Campos del formulario
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    // 3. Opciones y botón principal
    expect(find.text('Recordarme'), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);

    // 4. Divisor y botón de Discord debajo
    expect(find.text('O continúa con'), findsOneWidget);
    expect(find.text('Continuar con Discord'), findsOneWidget);
    expect(find.text('Autenticación segura mediante OAuth 2.0 PKCE'), findsOneWidget);

    // 5. Pie de página
    expect(find.text('Regístrate'), findsOneWidget);
  });

  testWidgets('Permite alternar visibilidad de contraseña y marcar Recordarme',
      (WidgetTester tester) async {
    final mockController = MockAuthController();

    await tester.pumpWidget(buildTestWidget(controller: mockController));
    await tester.pumpAndSettle();

    // Campo de contraseña inicialmente oculto
    final passwordFieldFinder = find.byType(TextField).last;
    TextField passwordField = tester.widget<TextField>(passwordFieldFinder);
    expect(passwordField.obscureText, isTrue);

    // Tocar icono de visibilidad
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pumpAndSettle();

    passwordField = tester.widget<TextField>(passwordFieldFinder);
    expect(passwordField.obscureText, isFalse);

    // Tocar checkbox de Recordarme
    final checkboxFinder = find.byType(Checkbox);
    expect(checkboxFinder, findsOneWidget);
    Checkbox checkbox = tester.widget<Checkbox>(checkboxFinder);
    expect(checkbox.value, isFalse);

    await tester.tap(checkboxFinder);
    await tester.pumpAndSettle();

    checkbox = tester.widget<Checkbox>(checkboxFinder);
    expect(checkbox.value, isTrue);
  });

  testWidgets('Tocar Continuar con Discord ejecuta el flujo de autenticación del controlador',
      (WidgetTester tester) async {
    final mockController = MockAuthController();

    await tester.pumpWidget(buildTestWidget(controller: mockController));
    await tester.pumpAndSettle();

    final discordButton = find.text('Continuar con Discord');
    expect(discordButton, findsOneWidget);

    await tester.ensureVisible(discordButton);
    await tester.tap(discordButton);
    await tester.pump();

    expect(mockController.loginCalled, isTrue);
  });
}
