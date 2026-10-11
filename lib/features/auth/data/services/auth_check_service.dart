import '../repositories/auth_repository.dart';

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
abstract class AuthCheckService {
  /// Consulta el estado actual de la sesión del usuario.
  Future<AuthStatus> checkAuthStatus();
}

/// Implementación real de [AuthCheckService] que verifica y restaura la sesión de Discord.
class DiscordAuthCheckService implements AuthCheckService {
  final AuthRepository _repository;

  const DiscordAuthCheckService(this._repository);

  @override
  Future<AuthStatus> checkAuthStatus() async {
    return await _repository.checkAndRestoreSession();
  }
}

/// Implementación stub para testing o modo desconectado.
class InitialAuthCheckService implements AuthCheckService {
  const InitialAuthCheckService();

  @override
  Future<AuthStatus> checkAuthStatus() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return AuthStatus.unauthenticated;
  }
}
