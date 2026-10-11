import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Modelo ligero para una partícula luminosa flotante.
class _ParticleData {
  final double relX;
  final double relY;
  final double radius;
  final double speed;
  final double phase;
  final Color color;

  const _ParticleData({
    required this.relX,
    required this.relY,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.color,
  });
}

/// Widget optimizado que renderiza partículas cibernéticas sutiles alrededor del centro.
class CyberParticles extends StatelessWidget {
  final double progress;
  final double opacity;

  const CyberParticles({
    super.key,
    required this.progress,
    required this.opacity,
  });

  // Conjunto predefinido y determinista de partículas (sin alocaciones dinámicas en cada frame)
  static const List<_ParticleData> _particles = [
    _ParticleData(relX: -0.38, relY: -0.22, radius: 2.2, speed: 1.2, phase: 0.2, color: Color(0xFF00F0FF)),
    _ParticleData(relX: 0.32, relY: -0.28, radius: 1.8, speed: 0.9, phase: 1.4, color: Color(0xFF38BDF8)),
    _ParticleData(relX: -0.25, relY: 0.26, radius: 2.4, speed: 1.4, phase: 2.1, color: Color(0xFF0284C7)),
    _ParticleData(relX: 0.40, relY: 0.18, radius: 1.6, speed: 1.1, phase: 3.5, color: Color(0xFFE2E8F0)),
    _ParticleData(relX: -0.15, relY: -0.35, radius: 1.4, speed: 1.3, phase: 4.2, color: Color(0xFF00F0FF)),
    _ParticleData(relX: 0.18, relY: 0.32, radius: 2.0, speed: 0.8, phase: 0.9, color: Color(0xFF38BDF8)),
    _ParticleData(relX: -0.42, relY: 0.05, radius: 1.5, speed: 1.5, phase: 5.1, color: Color(0xFF00E5FF)),
    _ParticleData(relX: 0.44, relY: -0.10, radius: 2.1, speed: 1.0, phase: 2.7, color: Color(0xFFBAE6FD)),
    _ParticleData(relX: -0.05, relY: -0.22, radius: 1.9, speed: 1.1, phase: 1.8, color: Color(0xFF38BDF8)),
    _ParticleData(relX: 0.08, relY: 0.24, radius: 1.7, speed: 1.3, phase: 3.1, color: Color(0xFF00F0FF)),
    _ParticleData(relX: -0.32, relY: -0.14, radius: 2.0, speed: 0.9, phase: 4.8, color: Color(0xFFE2E8F0)),
    _ParticleData(relX: 0.26, relY: -0.18, radius: 1.6, speed: 1.2, phase: 0.5, color: Color(0xFF0284C7)),
    _ParticleData(relX: -0.20, relY: 0.15, radius: 2.5, speed: 1.0, phase: 2.9, color: Color(0xFF00F0FF)),
    _ParticleData(relX: 0.35, relY: 0.28, radius: 1.5, speed: 1.4, phase: 1.2, color: Color(0xFF38BDF8)),
    _ParticleData(relX: -0.48, relY: -0.30, radius: 1.3, speed: 0.8, phase: 3.7, color: Color(0xFF00F0FF)),
    _ParticleData(relX: 0.46, relY: 0.34, radius: 1.8, speed: 1.2, phase: 5.4, color: Color(0xFFBAE6FD)),
  ];

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0.001) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: CustomPaint(
        painter: _CyberParticlesPainter(
          progress: progress,
          opacity: opacity,
          particles: _particles,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _CyberParticlesPainter extends CustomPainter {
  final double progress;
  final double opacity;
  final List<_ParticleData> particles;

  final Paint _particlePaint = Paint()..isAntiAlias = true;

  _CyberParticlesPainter({
    required this.progress,
    required this.opacity,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.001) return;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = math.min(size.width, size.height) * 0.55;

    for (final p in particles) {
      // Movimiento ondulatorio sutil y natural
      final cycle = progress * 2 * math.pi * p.speed + p.phase;
      final driftX = math.cos(cycle) * 12.0;
      final driftY = math.sin(cycle) * 14.0;

      final posX = centerX + (p.relX * maxRadius) + driftX;
      final posY = centerY + (p.relY * maxRadius) + driftY;

      // Pulso sutil de brillo en la partícula
      final pulse = (0.5 + 0.5 * math.sin(cycle * 1.5)).clamp(0.0, 1.0);
      final alpha = (p.color.a * opacity * pulse).clamp(0.0, 1.0);

      _particlePaint.color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(posX, posY), p.radius, _particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CyberParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.opacity != opacity;
  }
}

