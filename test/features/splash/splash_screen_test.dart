import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/app/router/app_router.dart';
import 'package:mi_app/features/auth/data/services/auth_check_service.dart';
import 'package:mi_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:mi_app/features/splash/presentation/widgets/splash_logo.dart';

class MockAuthCheckService implements AuthCheckService {
  final AuthStatus statusToReturn;
  final bool shouldThrow;

  MockAuthCheckService({
    this.statusToReturn = AuthStatus.unauthenticated,
    this.shouldThrow = false,
  });

  @override
  Future<AuthStatus> checkAuthStatus() async {
    if (shouldThrow) {
      throw Exception('Fallo de red o servicio');
    }
    return statusToReturn;
  }
}

void main() {
  Widget createTestWidget({required AuthCheckService authService}) {
    return MaterialApp(
      initialRoute: AppRouter.splash,
      onGenerateRoute: (settings) {
        if (settings.name == AppRouter.splash) {
          return MaterialPageRoute(
            builder: (_) => SplashScreen(authCheckService: authService),
          );
        }
        return AppRouter.onGenerateRoute(settings);
      },
    );
  }

  testWidgets('SplashScreen muestra SplashLogo y textos principales',
      (WidgetTester tester) async {
    final mockAuth = MockAuthCheckService(statusToReturn: AuthStatus.unauthenticated);

    await tester.pumpWidget(createTestWidget(authService: mockAuth));

    expect(find.byType(SplashLogo), findsOneWidget);
    expect(find.text('Mi App'), findsOneWidget);
    expect(find.text('Tu plataforma inteligente'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('SplashScreen navega a HomeScreen cuando el usuario está autenticado',
      (WidgetTester tester) async {
    final mockAuth = MockAuthCheckService(statusToReturn: AuthStatus.authenticated);

    await tester.pumpWidget(createTestWidget(authService: mockAuth));

    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Bienvenido a Mi App'), findsOneWidget);
  });

  testWidgets('SplashScreen navega a LoginScreen cuando no está autenticado',
      (WidgetTester tester) async {
    final mockAuth = MockAuthCheckService(statusToReturn: AuthStatus.unauthenticated);

    await tester.pumpWidget(createTestWidget(authService: mockAuth));

    await tester.pumpAndSettle();

    expect(find.text('¡Bienvenido!'), findsOneWidget);
    expect(find.text('Iniciar sesión con Discord'), findsOneWidget);
  });

  testWidgets('SplashScreen navega a LoginScreen de forma segura ante un error',
      (WidgetTester tester) async {
    final mockAuth = MockAuthCheckService(shouldThrow: true);

    await tester.pumpWidget(createTestWidget(authService: mockAuth));

    await tester.pumpAndSettle();

    // Comprueba que no se queda bloqueado y navega con fallback a Login
    expect(find.text('¡Bienvenido!'), findsOneWidget);
  });
}

