class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Error en el servidor']);

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Sin conexión a Internet']);

  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Error en almacenamiento local']);

  @override
  String toString() => message;
}

/// Excepción para errores durante el flujo OAuth 2.0.
class OAuthException implements Exception {
  final String message;
  final String? errorCode;

  const OAuthException(this.message, {this.errorCode});

  @override
  String toString() => message;
}

/// Excepción cuando el usuario cancela la autorización explícitamente.
class OAuthCancelledException implements Exception {
  final String message;
  const OAuthCancelledException([this.message = 'El inicio de sesión fue cancelado']);

  @override
  String toString() => message;
}

/// Excepción cuando la sesión ha expirado y no pudo ser renovada.
class SessionExpiredException implements Exception {
  final String message;
  const SessionExpiredException([this.message = 'Tu sesión ha expirado. Por favor, ingresa nuevamente']);

  @override
  String toString() => message;
}
