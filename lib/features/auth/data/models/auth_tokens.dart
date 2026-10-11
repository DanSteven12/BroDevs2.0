/// Modelo inmutable para almacenar los tokens OAuth 2.0 y su vigencia.
class AuthTokens {
  final String accessToken;
  final String tokenType;
  final DateTime expiresAt;
  final String? refreshToken;
  final String? scope;

  const AuthTokens({
    required this.accessToken,
    required this.tokenType,
    required this.expiresAt,
    this.refreshToken,
    this.scope,
  });

  /// Determina si el token de acceso ya expiró.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Determina si el token expirará dentro del margen de seguridad indicado.
  bool willExpireSoon([Duration threshold = const Duration(minutes: 5)]) {
    return DateTime.now().isAfter(expiresAt.subtract(threshold));
  }

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    DateTime calculatedExpiry;
    if (json['expires_at'] != null) {
      calculatedExpiry = DateTime.parse(json['expires_at'] as String);
    } else if (json['expires_in'] != null) {
      final seconds = (json['expires_in'] as num).toInt();
      calculatedExpiry = DateTime.now().add(Duration(seconds: seconds));
    } else {
      calculatedExpiry = DateTime.now().add(const Duration(days: 7));
    }

    return AuthTokens(
      accessToken: json['access_token'] as String,
      tokenType: (json['token_type'] as String?) ?? 'Bearer',
      expiresAt: calculatedExpiry,
      refreshToken: json['refresh_token'] as String?,
      scope: json['scope'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'expires_at': expiresAt.toIso8601String(),
      'refresh_token': refreshToken,
      'scope': scope,
    };
  }

  @override
  String toString() {
    // Protección estricta: NO imprimir tokens en logs
    return 'AuthTokens(tokenType: $tokenType, expiresAt: $expiresAt, hasRefresh: ${refreshToken != null})';
  }
}

