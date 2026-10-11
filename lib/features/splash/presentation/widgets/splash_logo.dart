import 'package:flutter/material.dart';

/// Widget reutilizable que renderiza el logotipo centrado de la aplicación.
///
/// Diseñado con un estilo moderno, minimalista y elegante sin requerir
/// dependencias externas de assets.
class SplashLogo extends StatelessWidget {
  /// Tamaño del logotipo en píxeles.
  final double size;

  const SplashLogo({
    super.key,
    this.size = 110.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.tertiary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            Color.lerp(primaryColor, secondaryColor, 0.7) ?? primaryColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(90),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anillo interior sutil con opacidad para efecto de profundidad
          Container(
            width: size * 0.74,
            height: size * 0.74,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.2),
              border: Border.all(
                color: Colors.white.withAlpha(45),
                width: 2.0,
              ),
            ),
          ),
          // Icono principal estilizado
          Icon(
            Icons.auto_awesome_rounded,
            size: size * 0.48,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

