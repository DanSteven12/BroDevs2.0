import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/app/router/app_router.dart';
import 'package:mi_app/features/auth/data/models/discord_user.dart';
import 'package:mi_app/features/auth/presentation/screens/login_screen.dart';
import 'package:mi_app/features/auth/presentation/viewmodels/auth_controller.dart';
import 'package:mi_app/features/home/presentation/screens/home_screen.dart';

class MockHomeAuthController extends ChangeNotifier implements AuthController {
  final DiscordUser? user;
  bool logoutCalled = false;

  MockHomeAuthController({this.user});

  @override
  bool get isLoading => false;

  @override
  DiscordUser? get currentUser => user;

  @override
  ValueNotifier<DiscordUser?> get userListenable => ValueNotifier<DiscordUser?>(user);

  @override
  String? get errorMessage => null;

  @override
  Future<bool> login({String? redirectUri}) async => false;

  @override
  Future<void> logout() async {
    logoutCalled = true;
    notifyListeners();
  }

  @override
  void clearError() {}
}

void main() {
  Widget buildTestApp({required AuthController controller}) {
    return MaterialApp(
      initialRoute: AppRouter.home,
      routes: {
        AppRouter.home: (_) => HomeScreen(authController: controller),
        AppRouter.login: (_) => LoginScreen(authController: controller),
      },
    );
  }

  testWidgets('HomeScreen muestra la página de bienvenida y el menú inferior con Inicio, Acerca de y Salir',
      (WidgetTester tester) async {
    final mockController = MockHomeAuthController();

    await tester.pumpWidget(buildTestApp(controller: mockController));
    await tester.pumpAndSettle();

    // Página de bienvenida
    expect(find.text('BroDevs'), findsOneWidget);
    expect(find.text('¡Bienvenido!'), findsOneWidget);
    expect(find.text('Bienvenido a BroDevs'), findsOneWidget);

    // Menú inferior (NavigationBar)
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Acerca de'), findsOneWidget);
    expect(find.text('Salir'), findsOneWidget);
  });

  testWidgets('Acerca de en el menú inferior no tiene funcionalidad y mantiene la pantalla de bienvenida',
      (WidgetTester tester) async {
    final mockController = MockHomeAuthController();

    await tester.pumpWidget(buildTestApp(controller: mockController));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Acerca de'));
    await tester.pumpAndSettle();

    expect(mockController.logoutCalled, isFalse);
    expect(find.text('Bienvenido a BroDevs'), findsOneWidget);
  });

  testWidgets('Salir en el menú inferior ejecuta cerrar sesión y redirige a LoginScreen',
      (WidgetTester tester) async {
    final mockController = MockHomeAuthController();

    await tester.pumpWidget(buildTestApp(controller: mockController));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();

    expect(mockController.logoutCalled, isTrue);
    expect(find.text('Continuar con Discord'), findsOneWidget);
  });
}

