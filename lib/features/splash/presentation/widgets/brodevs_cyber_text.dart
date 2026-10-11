import 'package:flutter/material.dart';

/// Widget central que renderiza el logo tipográfico "BRODEVS" con apariencia
/// Cyber Neon 3D, profundidad en relieve, reflejos metálicos y barrido de destello.
class BrodevsCyberText extends StatelessWidget {
  /// Rotación tridimensional sobre el eje Y (en radianes).
  final double yRotation;

  /// Inclinación tridimensional sobre el eje X (en radianes).
  final double xTilt;

  /// Escala global del texto.
  final double scale;

  /// Opacidad global del elemento.
  final double opacity;

  /// Progreso del barrido de destello luminoso (0.0 = inicio, 1.0 = fin, -1.0 = inactivo).
  final double sheenProgress;

  /// Multiplicador de intensidad de pulso de iluminación neón.
  final double glowPulse;

  const BrodevsCyberText({
    super.key,
    required this.yRotation,
    required this.xTilt,
    required this.scale,
    required this.opacity,
    this.sheenProgress = -1.0,
    this.glowPulse = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // Matriz de transformación tridimensional simulada con perspectiva
    final transformMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0015) // Perspectiva de cámara
      ..rotateY(yRotation)
      ..rotateX(xTilt)
      ..scaleByDouble(scale, scale, 1.0, 1.0);

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform(
        alignment: Alignment.center,
        transform: transformMatrix,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Resplandor Neón de fondo (Backlight Glow)
            _buildNeonBacklight(),

            // 2. Texto en relieve 3D con sombras multicapa y shaders metálicos
            _build3DText(),

            // 3. Destello cinemático horizontal (Sheen Sweep)
            if (sheenProgress >= 0.0 && sheenProgress <= 1.0)
              _buildSheenSweep(),
          ],
        ),
      ),
    );
  }

  /// Construye el resplandor difuso neón detrás del texto.
  Widget _buildNeonBacklight() {
    final effectivePulse = glowPulse.clamp(0.5, 2.0);

    return Container(
      width: 320,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          // Resplandor cian vibrante
          BoxShadow(
            color: const Color(0xFF00F0FF).withValues(alpha: (0.35 * effectivePulse).clamp(0.0, 1.0)),
            blurRadius: 55 * effectivePulse,
            spreadRadius: 8 * effectivePulse,
          ),
          // Resplandor azul eléctrico profundo
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: (0.30 * effectivePulse).clamp(0.0, 1.0)),
            blurRadius: 90 * effectivePulse,
            spreadRadius: 18 * effectivePulse,
          ),
        ],
      ),
    );
  }

  /// Construye el texto con relieve 3D y degradado metálico.
  Widget _build3DText() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) {
          // Degradado metálico entre plateado, azul eléctrico y cian
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF), // Reflejo plateado superior
              Color(0xFFE2E8F0), // Titanio pulido
              Color(0xFF7DD3FC), // Azul eléctrico claro
              Color(0xFF00F0FF), // Cian neón central
              Color(0xFF0284C7), // Azul eléctrico de contraste
              Color(0xFF38BDF8), // Borde reflectante inferior
            ],
            stops: [0.0, 0.22, 0.45, 0.68, 0.88, 1.0],
          ).createShader(bounds);
        },
        child: Text(
          'BRODEVS',
          style: TextStyle(
            fontSize: 44.0,
            fontWeight: FontWeight.w900,
            letterSpacing: 11.0,
            fontFamily: 'monospace',
            // Sombras en capas que construyen el biselado y profundidad 3D
            shadows: [
              // Reflejo superior especular (rim light)
              Shadow(
                color: Colors.white.withValues(alpha: 0.9),
                offset: const Offset(0.0, -1.2),
                blurRadius: 1.0,
              ),
              // Capas de extrusión 3D descendente (cian y azul cobalto)
              const Shadow(
                color: Color(0xFF38BDF8),
                offset: Offset(0.0, 1.2),
                blurRadius: 0.0,
              ),
              const Shadow(
                color: Color(0xFF0284C7),
                offset: Offset(0.0, 2.4),
                blurRadius: 0.0,
              ),
              const Shadow(
                color: Color(0xFF0369A1),
                offset: Offset(0.0, 3.6),
                blurRadius: 0.0,
              ),
              const Shadow(
                color: Color(0xFF075985),
                offset: Offset(0.0, 4.8),
                blurRadius: 1.0,
              ),
              const Shadow(
                color: Color(0xFF082F49),
                offset: Offset(0.0, 6.0),
                blurRadius: 1.5,
              ),
              // Sombra oscura de oclusión ambiental y halo neón
              Shadow(
                color: const Color(0xFF00F0FF).withValues(alpha: (0.75 * glowPulse).clamp(0.0, 1.0)),
                offset: const Offset(0.0, 0.0),
                blurRadius: 28.0,
              ),
              Shadow(
                color: Colors.black.withValues(alpha: 0.95),
                offset: const Offset(0.0, 9.0),
                blurRadius: 16.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el destello luminoso (sheen) que recorre las letras de izquierda a derecha.
  Widget _buildSheenSweep() {
    final progress = sheenProgress.clamp(0.0, 1.0);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) {
          // El destello se desplaza a lo largo del ancho del texto
          final sweepCenter = -0.3 + (progress * 1.6);
          final stop1 = (sweepCenter - 0.22).clamp(0.0, 1.0);
          final stop2 = (sweepCenter - 0.06).clamp(0.0, 1.0);
          final stop3 = sweepCenter.clamp(0.0, 1.0);
          final stop4 = (sweepCenter + 0.06).clamp(0.0, 1.0);
          final stop5 = (sweepCenter + 0.22).clamp(0.0, 1.0);

          return LinearGradient(
            begin: const Alignment(-1.0, -0.6),
            end: const Alignment(1.0, 0.6),
            stops: [stop1, stop2, stop3, stop4, stop5],
            colors: const [
              Colors.transparent,
              Color(0x55FFFFFF),
              Color(0xFFFFFFFF), // Núcleo brillante blanco puro
              Color(0x9900F0FF), // Halo de luz cian neón
              Colors.transparent,
            ],
          ).createShader(bounds);
        },
        child: const Text(
          'BRODEVS',
          style: TextStyle(
            fontSize: 44.0,
            fontWeight: FontWeight.w900,
            letterSpacing: 11.0,
            fontFamily: 'monospace',
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
