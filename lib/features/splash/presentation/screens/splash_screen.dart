import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/router/app_router.dart';
import '../../../auth/data/services/auth_check_service.dart';
import '../widgets/brodevs_cyber_text.dart';
import '../widgets/cyber_particles.dart';

/// Splash Screen profesional, cinematográfico y futurista para Brodevs.
///
/// Experiencia visual Cyber Neon 3D ejecutada en 4 fases coordinadas (3000 ms):
/// 1. Fase 1 (0–500 ms): Fondo oscuro #080D19, resplandor central azul y partículas.
/// 2. Fase 2 (0–1500 ms): Entrada 3D directa de BRODEVS con perspectiva sobre el eje Y, escala y opacidad.
/// 3. Fase 3 (1500–2300 ms): Destello horizontal (sheen sweep) y pulso neón.
/// 4. Fase 4 (2300–3000 ms): Zoom cinematográfico sutil, desvanecimiento y transición a destino.
class SplashScreen extends StatefulWidget {
  /// Servicio para verificar el estado de autenticación de la sesión.
  final AuthCheckService authCheckService;

  /// Tiempo máximo de seguridad antes de forzar navegación si la red no responde.
  final Duration timeoutDuration;

  /// Duración total de la secuencia cinemática.
  final Duration animationDuration;

  const SplashScreen({
    super.key,
    this.authCheckService = const InitialAuthCheckService(),
    this.timeoutDuration = const Duration(seconds: 5),
    this.animationDuration = const Duration(milliseconds: 3000),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Fase 1: Fondo y atmósfera (0.0 - 0.167)
  late final Animation<double> _centerGlowOpacity;
  late final Animation<double> _particlesOpacity;

  // Fase 2: Entrada 3D directa del texto (0.0 - 0.500)
  late final Animation<double> _textFadeIn;
  late final Animation<double> _textYRotation;
  late final Animation<double> _textXTilt;
  late final Animation<double> _textEntryScale;

  // Fase 3: Iluminación, barrido de destello y pulso neón (0.500 - 0.767)
  late final Animation<double> _sheenSweep;
  late final Animation<double> _glowPulse;

  // Fase 4: Transición y salida suave (0.767 - 1.000)
  late final Animation<double> _exitScale;
  late final Animation<double> _exitFadeOut;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _runInitializationSequence();
      }
    });
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    // Fase 1 (0–500 ms = 0.0 - 0.167)
    _centerGlowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.167, curve: Curves.easeOut),
      ),
    );

    _particlesOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.20, curve: Curves.easeIn),
      ),
    );

    // Fase 2: Entrada 3D directa de BRODEVS (0–1500 ms = 0.0 - 0.500)
    _textFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.250, curve: Curves.easeOut),
      ),
    );

    // Rotación sobre eje Y: de -0.55 rad (~ -31.5°) a 0.0 rad (de frente)
    _textYRotation = Tween<double>(begin: -0.55, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.450, curve: Curves.easeOutCubic),
      ),
    );

    // Ligera inclinación X cinemática para profundidad natural
    _textXTilt = Tween<double>(begin: 0.08, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.400, curve: Curves.easeOutCubic),
      ),
    );

    _textEntryScale = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.450, curve: Curves.easeOutCubic),
      ),
    );

    // Fase 3 (1500–2300 ms = 0.500 - 0.767)
    _sheenSweep = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.500, 0.767, curve: Curves.easeInOutCubic),
      ),
    );

    // Pulso neón detrás del logo: 1.0 -> 1.45 -> 1.0
    _glowPulse = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.45)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.45, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50.0,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.500, 0.767),
      ),
    );

    // Fase 4 (2300–3000 ms = 0.767 - 1.000)
    _exitScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.767, 1.000, curve: Curves.easeInCubic),
      ),
    );

    _exitFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.850, 1.000, curve: Curves.easeInOut),
      ),
    );
  }

  /// Ejecuta en paralelo la animación cinematográfica y la validación de sesión.
  Future<void> _runInitializationSequence() async {
    try {
      // En entorno de ejecución real de Android, espera a que el frame sea visible
      if (WidgetsBinding.instance is WidgetsFlutterBinding) {
        await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
      }

      if (!mounted) return;

      final animationFuture = _controller.forward(from: 0.0);
      final authFuture = _initializeAndCheckAuth();

      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        animationFuture,
        authFuture,
      ]).timeout(widget.timeoutDuration);

      final authStatus = results[1] as AuthStatus;
      _navigateToNextScreen(authStatus);
    } catch (_) {
      // Navegación segura de contingencia en caso de timeout
      if (mounted && !_hasNavigated) {
        _navigateToNextScreen(AuthStatus.unauthenticated);
      }
    }
  }

  Future<AuthStatus> _initializeAndCheckAuth() async {
    try {
      return await widget.authCheckService.checkAuthStatus();
    } catch (_) {
      return AuthStatus.unauthenticated;
    }
  }

  void _navigateToNextScreen(AuthStatus status) {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    final String targetRoute = (status == AuthStatus.authenticated)
        ? AppRouter.home
        : AppRouter.login;

    Navigator.of(context).pushReplacementNamed(targetRoute);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF080D19), // Fondo negro profundo Cyber Neon
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = _controller.value;

          // Cálculo del progreso de fases
          final glowOpacity = disableAnimations ? 1.0 : _centerGlowOpacity.value;
          final particlesOpacity = disableAnimations ? 0.3 : _particlesOpacity.value;

          // Transformaciones del logo
          final yRot = disableAnimations ? 0.0 : _textYRotation.value;
          final xTilt = disableAnimations ? 0.0 : _textXTilt.value;
          final currentScale = disableAnimations
              ? 1.0
              : (_textEntryScale.value * _exitScale.value);
          final currentOpacity = disableAnimations
              ? 1.0
              : (_textFadeIn.value * _exitFadeOut.value);

          // Sheen sweep y pulso en Fase 3
          final isPhase3 = progress >= 0.500 && progress <= 0.767;
          final sheenVal = (isPhase3 && !disableAnimations) ? _sheenSweep.value : -1.0;
          final pulseVal = (isPhase3 && !disableAnimations) ? _glowPulse.value : 1.0;

          return SizedBox.expand(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Resplandor radial central azul tenue
                Positioned.fill(
                  child: Opacity(
                    opacity: glowOpacity.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.9,
                          colors: [
                            const Color(0xFF00F0FF).withValues(alpha: (0.14 * pulseVal).clamp(0.0, 1.0)),
                            const Color(0xFF0284C7).withValues(alpha: (0.08 * pulseVal).clamp(0.0, 1.0)),
                            const Color(0xFF080D19).withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Partículas luminosas sutiles
                Positioned.fill(
                  child: CyberParticles(
                    progress: progress,
                    opacity: particlesOpacity,
                  ),
                ),

                // 3. Texto protagonista central Cyber Neon 3D: BRODEVS
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: BrodevsCyberText(
                      yRotation: yRot,
                      xTilt: xTilt,
                      scale: currentScale,
                      opacity: currentOpacity,
                      sheenProgress: sheenVal,
                      glowPulse: pulseVal,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
