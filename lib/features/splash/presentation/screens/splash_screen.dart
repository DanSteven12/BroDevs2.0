import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/router/app_router.dart';
import '../../../auth/data/services/auth_check_service.dart';
import '../widgets/splash_logo.dart';

/// Pantalla Splash Screen animada, profesional y optimizada.
///
/// Ejecuta una secuencia coordinada de 4 fases de animación:
/// 1. Fade In + Scale del logotipo (aparición).
/// 2. Slide vertical controlado del logotipo (movimiento).
/// 3. Fade In + Slide ascendente del nombre de la aplicación (aparición del nombre).
/// 4. Transición fluida hacia la pantalla destino según el estado de autenticación.
class SplashScreen extends StatefulWidget {
  /// Servicio para verificar el estado de autenticación (extensible para Fase 2).
  final AuthCheckService authCheckService;

  /// Tiempo máximo de seguridad antes de forzar navegación en caso de bloqueo.
  final Duration timeoutDuration;

  /// Pausa visual tras finalizar las animaciones para que el diseño se aprecie con calma.
  final Duration settleDuration;

  const SplashScreen({
    super.key,
    this.authCheckService = const InitialAuthCheckService(),
    this.timeoutDuration = const Duration(seconds: 4),
    this.settleDuration = const Duration(milliseconds: 600),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Animación 1: Aparición y escala del logotipo
  late final Animation<double> _logoFadeAnimation;
  late final Animation<double> _logoScaleAnimation;

  // Animación 2: Movimiento vertical del logotipo
  late final Animation<Offset> _logoSlideAnimation;

  // Animación 3: Aparición y desplazamiento ascendente del nombre
  late final Animation<double> _titleFadeAnimation;
  late final Animation<Offset> _titleSlideAnimation;

  // Indicador de carga discreto
  late final Animation<double> _loadingFadeAnimation;

  // Control para evitar navegación duplicada o fugas
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _runInitializationSequence();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Animación 1 — Fade In y Scale del logotipo
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.50, curve: Curves.easeOutCubic),
      ),
    );

    // Animación 2 — Movimiento / desplazamiento vertical suave del logotipo
    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.20, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // Animación 3 — Aparición del nombre (Fade In + ligero desplazamiento ascendente)
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // Indicador discreto al final del proceso
    _loadingFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  /// Ejecuta en paralelo la animación visual y la preparación de recursos/sesión,
  /// garantizando que la animación se aprecie fluidamente y con un timeout de seguridad.
  Future<void> _runInitializationSequence() async {
    try {
      // Inicia la animación
      final animationFuture = _controller.forward();

      // Prepara recursos iniciales y consulta el estado de sesión
      final authFuture = _initializeAndCheckAuth();

      // Espera a que termine la animación estética y la comprobación
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        animationFuture,
        authFuture,
      ]).timeout(widget.timeoutDuration);

      // Breve pausa para apreciar la identidad visual antes de transicionar
      if (widget.settleDuration > Duration.zero) {
        await Future<void>.delayed(widget.settleDuration);
      }

      final authStatus = results[1] as AuthStatus;
      _navigateToNextScreen(authStatus);
    } catch (_) {
      // Si ocurre un timeout o error no previsto, navega de forma segura a Login
      if (mounted && !_hasNavigated) {
        _navigateToNextScreen(AuthStatus.unauthenticated);
      }
    }
  }

  /// Inicialización de recursos y consulta de sesión (Fase 1: stub, extensible en Fase 2)
  Future<AuthStatus> _initializeAndCheckAuth() async {
    try {
      return await widget.authCheckService.checkAuthStatus();
    } catch (_) {
      return AuthStatus.unauthenticated;
    }
  }

  /// Animación 4 — Finalización: Transición suave hacia la siguiente pantalla
  void _navigateToNextScreen(AuthStatus status) {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    final String targetRoute;
    switch (status) {
      case AuthStatus.authenticated:
        targetRoute = AppRouter.home;
        break;
      case AuthStatus.unauthenticated:
      case AuthStatus.sessionExpired:
        targetRoute = AppRouter.login;
        break;
    }

    // Navega reemplazando la ruta para que el Splash no permanezca en la pila
    Navigator.of(context).pushReplacementNamed(targetRoute);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Paleta coherente con la identidad visual
    final backgroundGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? const [
              Color(0xFF140C28),
              Color(0xFF0B0616),
            ]
          : [
              theme.colorScheme.surface,
              theme.colorScheme.primaryContainer.withAlpha(80),
            ],
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Animación 1 y 2: Logotipo con Fade, Scale y Slide
                        FadeTransition(
                          opacity: _logoFadeAnimation,
                          child: ScaleTransition(
                            scale: _logoScaleAnimation,
                            child: SlideTransition(
                              position: _logoSlideAnimation,
                              child: const SplashLogo(size: 110.0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24.0),

                        // Animación 3: Aparición del nombre de la aplicación
                        FadeTransition(
                          opacity: _titleFadeAnimation,
                          child: SlideTransition(
                            position: _titleSlideAnimation,
                            child: Column(
                              children: [
                                Text(
                                  'Mi App',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6.0),
                                Text(
                                  'Tu plataforma inteligente',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    letterSpacing: 0.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 48.0),

                        // Indicador de carga discreto
                        FadeTransition(
                          opacity: _loadingFadeAnimation,
                          child: SizedBox(
                            width: 22.0,
                            height: 22.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary.withAlpha(200),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
