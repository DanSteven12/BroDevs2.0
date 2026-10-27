import 'package:flutter/material.dart';
import '../../app/app_dependencies.dart';
import '../../app/router/app_router.dart';
import '../auth/presentation/viewmodels/auth_controller.dart';

class AcercaDeScreen extends StatefulWidget {
  final AuthController? authController;

  const AcercaDeScreen({
    super.key,
    this.authController,
  });

  @override
  State<AcercaDeScreen> createState() => _AcercaDeScreenState();
}

class _AcercaDeScreenState extends State<AcercaDeScreen> {
  late final AuthController _controller;
  bool _isLoggingOut = false;

  static const _students = [
    ('Demeza Hernández Alex Fernando', '092310330'),
    ('Hernández Hernández Carlos Leodan', '092310342'),
    ('May Gordillo Adriana Cristel', '092310161'),
    ('Galvez Coutiño Franco Antonio', '092210365'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = widget.authController ?? AppDependencies.authController;
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);

    try {
      await _controller.logout();
      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.login,
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cerrar sesión. Inténtalo nuevamente.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Acerca de',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _isLoggingOut ? null : _handleLogout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF0F172A), Color(0xFF080D19)]
                : [
                    colors.surface,
                    colors.primaryContainer.withAlpha(70),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colors.onSurface.withAlpha(25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 65 : 18),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: colors.primaryContainer,
                        child: Icon(
                          Icons.school_rounded,
                          size: 44,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Universidad Tecnológica de la Selva',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ingeniería en Desarrollo y Gestión de Software',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      _information(
                        context,
                        'DIVISIÓN',
                        'Tecnologías de la Información y Comunicación.',
                      ),
                      _information(
                        context,
                        'Asignatura',
                        'Desarrollo Móvil Integral',
                      ),
                      _information(
                        context,
                        'Grado y Grupo',
                        '10° “A”',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Alumnos',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._students.map(
                        (student) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer.withAlpha(65),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.$1,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Matrícula: ${student.$2}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      _information(
                        context,
                        'Docente',
                        'DR. Armando Méndez Morales',
                      ),
                      _information(
                        context,
                        'Lugar',
                        'Ocosingo, Chiapas',
                      ),
                      _information(
                        context,
                        'Fecha de entrega',
                        '12/10/2026',
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
          selectedIndex: 1,
          onDestinationSelected: (index) {
            if (index == 0) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed(AppRouter.home);
              }
            } else if (index == 2) {
              _handleLogout();
            }
          },
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
  }

  Widget _information(
    BuildContext context,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}