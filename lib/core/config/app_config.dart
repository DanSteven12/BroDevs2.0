/// Configuración centralizada de la aplicación y autenticación con Discord.
class AppConfig {
  AppConfig._();

  /// Identificador público de la aplicación registrado en Discord Developer Portal.
  /// Puede ser sobrescrito en compilación mediante --dart-define=DISCORD_CLIENT_ID=...
  static const String discordClientId = String.fromEnvironment(
    'DISCORD_CLIENT_ID',
    defaultValue: '1558663883747627010',
  );

  /// URI de redirección oficial registrada en Discord Developer Portal.
  ///
  /// Por defecto utiliza el esquema oficial requerido por Discord para clientes móviles:
  /// `discord-<APPLICATION_ID>:/authorize/callback`
  /// Puede ser sobrescrita mediante --dart-define=DISCORD_REDIRECT_URI=...
  static const String discordRedirectUri = String.fromEnvironment(
    'DISCORD_REDIRECT_URI',
    defaultValue: 'discord-1558663883747627010:/authorize/callback',
  );

  /// Esquema alternativo personalizado solicitado por el usuario.
  static const String customSchemeRedirectUri = 'miapp://auth/discord/callback';

  /// Scopes autorizados para el acceso a la identidad y correo electrónico.
  static const List<String> discordScopes = ['identify', 'email'];

  // Endpoints oficiales de la API v10 de Discord
  static const String discordAuthorizeUrl = 'https://discord.com/oauth2/authorize';
  static const String discordTokenUrl = 'https://discord.com/api/v10/oauth2/token';
  static const String discordTokenRevokeUrl = 'https://discord.com/api/v10/oauth2/token/revoke';
  static const String discordCurrentUserUrl = 'https://discord.com/api/v10/users/@me';
  static const String discordCdnBaseUrl = 'https://cdn.discordapp.com';
}

