import 'package:flutter/material.dart';
import '../../../../app/router/app_router.dart';

/// Pantalla temporal de bienvenida e inicio de sesión para la Fase 1.
///
/// Deja claramente identificado el punto de integración con Discord OAuth 2.0
/// que se implementará en la Fase 2.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono representativo
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withAlpha(50),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.lock_person_rounded,
                    size: 46,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 28),

                // Título
                Text(
                  '¡Bienvenido!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Descripción informativa
                Text(
                  'Esta es la pantalla temporal de bienvenida.\nEn la Fase 2 se integrará la autenticación con Discord.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Botón representativo de Discord (deshabilitado / badge Fase 2)
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'La autenticación con Discord OAuth 2.0 se activará en la Fase 2.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5865F2), // Discord Blurple
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.discord, size: 22),
                    label: const Text(
                      'Iniciar sesión con Discord',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Badge de Fase 2
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withAlpha(20)
                        : Colors.black.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Punto de integración — Fase 2',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Opción para continuar a Home durante el desarrollo
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(AppRouter.home);
                  },
                  child: const Text('Continuar a Inicio (desarrollo)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
