import 'package:flutter/material.dart';
import '../../../../app/app_dependencies.dart';
import '../../../../app/router/app_router.dart';
import '../../../auth/presentation/viewmodels/auth_controller.dart';

/// Pantalla principal que da la bienvenida al usuario con sesión activa.
class HomeScreen extends StatefulWidget {
  final AuthController? authController;

  const HomeScreen({
    super.key,
    this.authController,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AuthController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.authController ?? AppDependencies.authController;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final user = _controller.currentUser;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Inicio'),
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
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(80),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.discord,
                      size: 54,
                      color: const Color(0xFF5865F2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    user != null ? '¡Hola, ${user.displayName}!' : '¡Bienvenido!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user != null
                        ? 'Sesión activa verificada mediante Discord OAuth 2.0.'
                        : 'Bienvenido a Mi App',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRouter.profile);
                    },
                    icon: const Icon(Icons.person_rounded),
                    label: const Text('Ver mi Perfil'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
