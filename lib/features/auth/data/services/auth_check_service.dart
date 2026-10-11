/// Estados posibles de autenticación para la navegación inicial.
enum AuthStatus {
  /// El usuario cuenta con una sesión activa y válida.
  authenticated,

  /// No existe sesión activa en el dispositivo.
  unauthenticated,

  /// La sesión ha expirado y requiere renovación o nuevo inicio de sesión.
  sessionExpired,
}

/// Contrato abstracto para la verificación del estado de autenticación.
///
/// Preparado para la integración con Discord OAuth 2.0 en la Fase 2.
abstract class AuthCheckService {
  /// Consulta el estado actual de la sesión del usuario.
  Future<AuthStatus> checkAuthStatus();
}

/// Implementación inicial de [AuthCheckService] para la Fase 1.
///
/// No simula sesiones válidas; devuelve [AuthStatus.unauthenticated]
/// dejando el punto de conexión listo para implementar la lectura segura
/// de tokens de Discord en la Fase 2.
class InitialAuthCheckService implements AuthCheckService {
  const InitialAuthCheckService();

  @override
  Future<AuthStatus> checkAuthStatus() async {
    // Simula una comprobación ultraligera no bloqueante de almacenamiento local
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return AuthStatus.unauthenticated;
  }
}

