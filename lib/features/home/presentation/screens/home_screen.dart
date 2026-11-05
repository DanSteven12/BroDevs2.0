import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import '../../../../app/app_dependencies.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/services/admob_pip_service.dart';
import '../../../auth/presentation/viewmodels/auth_controller.dart';

/// Pantalla principal que contiene la página de bienvenida (Inicio)
/// y el menú de navegación inferior con Inicio, Acerca de (solo diseño) y Salir (cerrar sesión).
class HomeScreen extends StatefulWidget {
  final AuthController? authController;
  final AdmobPipService? pipService;

  const HomeScreen({
    super.key,
    this.authController,
    this.pipService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  late final AuthController _controller;
  int _selectedIndex = 0;

  // ── AdMob PiP ────────────────────────────────────────────────────────────
  /// Servicio que gestiona el ciclo de vida del anuncio Picture-in-Picture.
  AdmobPipService? _pipService;

  /// Indica si HomeScreen es actualmente la ruta visible en primer plano.
  bool _isCurrentRoute = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.authController ?? AppDependencies.authController;
    _initAdmob();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      AppRouter.routeObserver.subscribe(this, modalRoute);
    }
  }

  /// Inicializa AdMob y carga el anuncio PiP (en Android o si se inyecta en tests).
  Future<void> _initAdmob() async {
    if (widget.pipService == null && defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    final service = widget.pipService ?? AdmobPipService();
    _pipService = service;
    await service.initialize();
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await service.loadAd();
      if (mounted && _isCurrentRoute && service.isAdLoaded) {
        await service.showAd();
      }
    });
  }

  // ── RouteAware Callbacks ──────────────────────────────────────────────────

  @override
  void didPush() {
    _isCurrentRoute = true;
  }

  @override
  void didPushNext() {
    // Se navegó a otra pantalla (ej. Perfil o Acerca de) sobre HomeScreen.
    // Ocultamos el anuncio para que no flote sobre la nueva vista.
    _isCurrentRoute = false;
    _pipService?.hideAd();
  }

  @override
  void didPopNext() {
    // Se regresó a HomeScreen desde otra pantalla.
    // Restauramos la visibilidad del anuncio sin recargarlo.
    _isCurrentRoute = true;
    if (_pipService != null && _pipService!.isAdLoaded) {
      _pipService!.showAd();
    }
  }

  @override
  void didPop() {
    _isCurrentRoute = false;
    _pipService?.disposeAd();
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    // Libera el anuncio PiP para que no persista en otras pantallas.
    _pipService?.disposeAd();
    _pipService?.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    _pipService?.disposeAd();
    await _controller.logout();
    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.login,
      (route) => false,
    );
  }

  void _onDestinationSelected(int index) {
    if (index == 0) {
      // Inicio (Página de bienvenida)
      setState(() {
        _selectedIndex = 0;
      });
    } else if (index == 1) {
      // Acerca de: navegar a la vista AcercaDeScreen
      Navigator.of(context).pushNamed(AppRouter.acercaDe);
    } else if (index == 2) {
      // Salir: cerrar sesión y volver al Login
      _handleLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? const [
              Color(0xFF0F172A),
              Color(0xFF080D19),
            ]
          : [
              theme.colorScheme.surface,
              theme.colorScheme.primaryContainer.withAlpha(45),
            ],
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final user = _controller.currentUser;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'BroDevs',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Mi Perfil',
                icon: user != null && user.avatar != null
                    ? CircleAvatar(
                        radius: 14,
                        backgroundImage: NetworkImage(user.avatarUrl),
                      )
                    : const Icon(Icons.account_circle_rounded),
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.profile);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(gradient: backgroundGradient),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF131B2E).withAlpha(220)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withAlpha(22)
                              : Colors.black.withAlpha(15),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 90 : 18),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Avatar o icono principal de bienvenida
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5865F2).withAlpha(28),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.discord,
                              size: 54,
                              color: Color(0xFF5865F2),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Saludo principal
                          Text(
                            user != null ? '¡Hola, ${user.displayName}!' : '¡Bienvenido!',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // Subtítulo de bienvenida
                          Text(
                            'Bienvenido a BroDevs',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          Text(
                            user != null
                                ? 'Sesión activa verificada mediante Discord OAuth 2.0.'
                                : 'Has ingresado a la página principal de inicio.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),

                          // Botón para ver el perfil detallado
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushNamed(AppRouter.profile);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.person_rounded),
                              label: const Text(
                                'Ver mi Perfil',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withAlpha(20)
                      : Colors.black.withAlpha(15),
                  width: 1,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Inicio',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.info_outline_rounded),
                  selectedIcon: Icon(Icons.info_rounded),
                  label: 'Acerca de',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.logout_rounded,
                    color: theme.colorScheme.error,
                  ),
                  label: 'Salir',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
