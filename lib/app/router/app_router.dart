import 'package:flutter/material.dart';
import '../app_dependencies.dart';
import '../../core/config/app_config.dart';
import '../../core/network/deep_link_service.dart';
import '../../features/Acercade/acercade_screen.dart';
import '../../features/auth/data/services/auth_check_service.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

/// Administrador central de rutas y transiciones de la aplicación.
class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String acercaDe = '/acerca-de';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';

    // Si Flutter intercepta el deep link de retorno de OAuth (/authorize/callback o /discord/callback)
    if (routeName.startsWith('/authorize/callback') ||
        routeName.startsWith('/discord/callback') ||
        routeName.contains('code=') ||
        routeName.contains('error=')) {
      final scheme = AppConfig.discordClientId;
      final fullUriString = (routeName.contains('://') || routeName.contains(':/'))
          ? routeName
          : 'discord-$scheme:$routeName';
      try {
        final uri = Uri.parse(fullUriString);
        DeepLinkService().handleIncomingUri(uri);
      } catch (_) {}

      // Muestra un estado de transición limpio mientras se procesa la autenticación
      return PageRouteBuilder<dynamic>(
        settings: settings,
        opaque: false,
        transitionDuration: Duration.zero,
        pageBuilder: (context, _, _) => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    switch (settings.name) {
      case splash:
        return _buildFadeRoute(
          builder: (_) => SplashScreen(
            authCheckService: DiscordAuthCheckService(AppDependencies.authRepository),
          ),
          settings: settings,
        );

      case login:
        return _buildFadeRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case home:
        return _buildFadeRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );

      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );

      case acercaDe:
        return _buildFadeRoute(
          builder: (_) => const AcercaDeScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No se encontró la ruta: ${settings.name}'),
            ),
          ),
        );
    }
  }

  /// Construye una transición Fade suave que evita parpadeos y pantallas negras.
  static PageRouteBuilder<T> _buildFadeRoute<T>({
    required WidgetBuilder builder,
    required RouteSettings settings,
    Duration duration = const Duration(milliseconds: 350),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
    );
  }
}
