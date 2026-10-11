import '../../../../core/config/app_config.dart';

/// Modelo fuertemente tipado que representa un usuario de Discord autenticado.
class DiscordUser {
  /// Identificador único y permanente del usuario en Discord.
  final String id;

  /// Nombre de usuario único (handle, e.g. "steven_dev").
  final String username;

  /// Nombre visible configurable (Global Display Name), si existe.
  final String? globalName;

  /// Hash del avatar del usuario.
  final String? avatar;

  /// Correo electrónico verificado, cuando el scope 'email' está disponible.
  final String? email;

  /// Si el correo electrónico ha sido verificado en Discord.
  final bool? verified;

  const DiscordUser({
    required this.id,
    required this.username,
    this.globalName,
    this.avatar,
    this.email,
    this.verified,
  });

  /// Nombre preferido para mostrar en pantalla.
  String get displayName => (globalName != null && globalName!.trim().isNotEmpty)
      ? globalName!
      : username;

  /// URL completa y optimizada para el avatar del usuario.
  /// Si el usuario no tiene avatar personalizado, devuelve el avatar predeterminado de Discord.
  String get avatarUrl {
    if (avatar != null && avatar!.isNotEmpty) {
      final isAnimated = avatar!.startsWith('a_');
      final extension = isAnimated ? 'gif' : 'png';
      return '${AppConfig.discordCdnBaseUrl}/avatars/$id/$avatar.$extension?size=256';
    }

    // Avatar predeterminado basado en cálculo de snowflake de Discord
    final parsedId = BigInt.tryParse(id);
    final defaultIndex = parsedId != null ? ((parsedId >> 22).toInt() % 6) : 0;
    return '${AppConfig.discordCdnBaseUrl}/embed/avatars/$defaultIndex.png';
  }

  factory DiscordUser.fromJson(Map<String, dynamic> json) {
    return DiscordUser(
      id: json['id'] as String,
      username: json['username'] as String,
      globalName: json['global_name'] as String?,
      avatar: json['avatar'] as String?,
      email: json['email'] as String?,
      verified: json['verified'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'global_name': globalName,
      'avatar': avatar,
      'email': email,
      'verified': verified,
    };
  }

  @override
  String toString() {
    return 'DiscordUser(id: $id, username: $username, displayName: $displayName, email: ${email != null ? 'present' : 'null'})';
  }
}

