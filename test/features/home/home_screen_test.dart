import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/app/router/app_router.dart';
import 'package:mi_app/core/services/admob_pip_service.dart';
import 'package:mi_app/features/Acercade/acercade_screen.dart';
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

/// Mock controlado de [AdmobPipService] para verificar el ciclo de vida y RouteAware.
class MockAdmobPipService extends ChangeNotifier implements AdmobPipService {
  int initializeCalls = 0;
  int loadCalls = 0;
  int showCalls = 0;
  int hideCalls = 0;
  int disposeAdCalls = 0;
  bool isLoadedValue = true;
  bool isShowingValue = false;

  @override
  bool get isAdLoaded => isLoadedValue;

  @override
  bool get isAdShowing => isShowingValue;

  @override
  AdmobPipState get state => isShowingValue
      ? AdmobPipState.showing
      : (isLoadedValue ? AdmobPipState.loaded : AdmobPipState.idle);

  @override
  String? get errorMessage => null;

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<void> loadAd() async {
    loadCalls++;
    isLoadedValue = true;
  }

  @override
  Future<void> showAd() async {
    showCalls++;
    isShowingValue = true;
  }

  @override
  Future<void> hideAd() async {
    hideCalls++;
    isShowingValue = false;
  }

  @override
  void disposeAd() {
    disposeAdCalls++;
    isLoadedValue = false;
    isShowingValue = false;
  }
}

void main() {
  Widget buildTestApp({
    required AuthController controller,
    AdmobPipService? pipService,
  }) {
    return MaterialApp(
      initialRoute: AppRouter.home,
      navigatorObservers: [AppRouter.routeObserver],
      routes: {
        AppRouter.home: (_) => HomeScreen(
              authController: controller,
              pipService: pipService,
            ),
        AppRouter.acercaDe: (_) => AcercaDeScreen(authController: controller),
        AppRouter.profile: (_) => Scaffold(
              appBar: AppBar(title: const Text('Mi Perfil')),
              body: const Center(child: Text('Vista de Perfil de Prueba')),
            ),
        AppRouter.login: (_) => LoginScreen(authController: controller),
      },
    );
  }

  group('HomeScreen - UI y Navegación Básica', () {
    testWidgets('Muestra la página de bienvenida y el menú inferior con Inicio, Acerca de y Salir',
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

    testWidgets('Acerca de en el menú inferior navega a AcercaDeScreen y permite regresar a Inicio',
        (WidgetTester tester) async {
      final mockController = MockHomeAuthController();

      await tester.pumpWidget(buildTestApp(controller: mockController));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Acerca de'));
      await tester.pumpAndSettle();

      expect(mockController.logoutCalled, isFalse);
      expect(find.text('Universidad Tecnológica de la Selva'), findsOneWidget);

      // Regresar a Inicio desde el menú inferior de Acerca de
      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();

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
  });

  group('HomeScreen - Ciclo de Vida y RouteAware del Anuncio PiP', () {
    testWidgets('Carga y muestra el anuncio PiP al iniciar HomeScreen',
        (WidgetTester tester) async {
      final mockController = MockHomeAuthController();
      final mockPipService = MockAdmobPipService();

      await tester.pumpWidget(buildTestApp(
        controller: mockController,
        pipService: mockPipService,
      ));
      await tester.pumpAndSettle();

      expect(mockPipService.initializeCalls, equals(1));
      expect(mockPipService.loadCalls, equals(1));
      expect(mockPipService.showCalls, equals(1));
      expect(mockPipService.hideCalls, equals(0));
    });

    testWidgets('Oculta el anuncio al navegar a Acerca de y lo restaura sin recargar al volver',
        (WidgetTester tester) async {
      final mockController = MockHomeAuthController();
      final mockPipService = MockAdmobPipService();

      await tester.pumpWidget(buildTestApp(
        controller: mockController,
        pipService: mockPipService,
      ));
      await tester.pumpAndSettle();

      expect(mockPipService.showCalls, equals(1));
      expect(mockPipService.hideCalls, equals(0));

      // Navegar a Acerca de (didPushNext)
      await tester.tap(find.text('Acerca de'));
      await tester.pumpAndSettle();

      expect(mockPipService.hideCalls, equals(1),
          reason: 'El anuncio debe ocultarse al cubrir HomeScreen con AcercaDeScreen');
      expect(mockPipService.loadCalls, equals(1),
          reason: 'No debe recargar el anuncio de la red');

      // Regresar a Inicio (didPopNext)
      await tester.tap(find.text('Inicio'));
      await tester.pumpAndSettle();

      expect(mockPipService.showCalls, equals(2),
          reason: 'El anuncio debe volver a mostrarse al regresar a HomeScreen');
      expect(mockPipService.loadCalls, equals(1),
          reason: 'Sigue sin recargar el anuncio');
    });

    testWidgets('Oculta el anuncio al navegar a Perfil y lo restaura al volver atrás',
        (WidgetTester tester) async {
      final mockController = MockHomeAuthController();
      final mockPipService = MockAdmobPipService();

      await tester.pumpWidget(buildTestApp(
        controller: mockController,
        pipService: mockPipService,
      ));
      await tester.pumpAndSettle();

      // Navegar a Perfil mediante el botón "Ver mi Perfil"
      await tester.tap(find.text('Ver mi Perfil'));
      await tester.pumpAndSettle();

      expect(find.text('Vista de Perfil de Prueba'), findsOneWidget);
      expect(mockPipService.hideCalls, equals(1),
          reason: 'El anuncio debe ocultarse al navegar a Perfil');

      // Regresar presionando el botón back del AppBar
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Bienvenido a BroDevs'), findsOneWidget);
      expect(mockPipService.showCalls, equals(2),
          reason: 'El anuncio debe restaurarse al volver de Perfil');
      expect(mockPipService.loadCalls, equals(1));
    });

    testWidgets('Libera el anuncio completamente al cerrar sesión (Salir)',
        (WidgetTester tester) async {
      final mockController = MockHomeAuthController();
      final mockPipService = MockAdmobPipService();

      await tester.pumpWidget(buildTestApp(
        controller: mockController,
        pipService: mockPipService,
      ));
      await tester.pumpAndSettle();

      expect(mockPipService.disposeAdCalls, equals(0));

      await tester.tap(find.text('Salir'));
      await tester.pumpAndSettle();

      expect(mockPipService.disposeAdCalls, greaterThanOrEqualTo(1),
          reason: 'El anuncio debe destruirse al cerrar sesión');
    });
  });
}
