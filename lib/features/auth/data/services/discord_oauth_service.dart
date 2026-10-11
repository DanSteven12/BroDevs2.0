import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/deep_link_service.dart';
import '../models/auth_tokens.dart';
import '../models/discord_user.dart';

/// Servicio responsable de ejecutar el flujo OAuth 2.0 con PKCE frente a la API de Discord.
class DiscordOAuthService {
  final http.Client _httpClient;
  final DeepLinkService _deepLinkService;

  DiscordOAuthService({
    http.Client? httpClient,
    DeepLinkService? deepLinkService,
  })  : _httpClient = httpClient ?? http.Client(),
        _deepLinkService = deepLinkService ?? DeepLinkService();

  /// Genera un [code_verifier] criptográficamente seguro cumpliendo con RFC 7636.
  String generateCodeVerifier([int length = 64]) {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Calcula el [code_challenge] usando S256 (SHA-256 en Base64Url sin padding).
  String generateCodeChallenge(String verifier) {
    final bytes = ascii.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Genera un valor aleatorio de [state] para mitigar CSRF.
  String generateState([int length = 32]) {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Inicia el flujo completo de autorización interactiva con PKCE.
  ///
  /// Abre el navegador del sistema / app de Discord y espera la redirección deep link.
  Future<AuthTokens> authenticate({
    String? redirectUri,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final selectedRedirectUri = redirectUri ?? AppConfig.discordRedirectUri;
    final verifier = generateCodeVerifier();
    final challenge = generateCodeChallenge(verifier);
    final state = generateState();

    // Construcción de la URL de autorización
    final authorizeUri = Uri.parse(AppConfig.discordAuthorizeUrl).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': AppConfig.discordClientId,
        'scope': AppConfig.discordScopes.join(' '),
        'state': state,
        'redirect_uri': selectedRedirectUri,
        'prompt': 'consent',
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
      },
    );

    // Preparar el completer para capturar el retorno desde el deep link
    final completer = Completer<Uri>();
    StreamSubscription<Uri>? subscription;

    try {
      subscription = _deepLinkService.uriLinkStream.listen(
        (uri) {
          if (_isMatchingCallbackUri(uri, selectedRedirectUri)) {
            if (!completer.isCompleted) {
              completer.complete(uri);
            }
          }
        },
        onError: (err) {
          if (!completer.isCompleted) {
            completer.completeError(OAuthException('Error al recibir enlace de retorno: $err'));
          }
        },
      );

      // Lanzar el navegador o cliente externo (sin WebViews embebidos)
      final launched = await launchUrl(
        authorizeUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw const OAuthException('No se pudo abrir el navegador para la autenticación.');
      }

      // Esperar el callback dentro del tiempo límite
      final callbackUri = await completer.future.timeout(
        timeout,
        onTimeout: () {
          throw const OAuthCancelledException('La autenticación expiró o fue cancelada por el usuario.');
        },
      );

      // Validar si el usuario canceló en Discord
      final error = callbackUri.queryParameters['error'];
      if (error != null) {
        final errorDesc = callbackUri.queryParameters['error_description'] ?? error;
        if (error == 'access_denied') {
          throw const OAuthCancelledException('Inicio de sesión cancelado por el usuario.');
        }
        throw OAuthException('Error devuelto por Discord: $errorDesc', errorCode: error);
      }

      // Validar state
      final returnedState = callbackUri.queryParameters['state'];
      if (returnedState != state) {
        throw const OAuthException('Error de validación de seguridad (state no coincide).');
      }

      // Recuperar código de autorización
      final code = callbackUri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        throw const OAuthException('No se recibió el código de autorización de Discord.');
      }

      // Intercambiar código por tokens
      return await exchangeCodeForTokens(
        code: code,
        verifier: verifier,
        redirectUri: selectedRedirectUri,
      );
    } finally {
      await subscription?.cancel();
    }
  }

  /// Verifica si la URI recibida corresponde al callback de autenticación esperado.
  bool _isMatchingCallbackUri(Uri incoming, String expectedRedirectUri) {
    final expected = Uri.parse(expectedRedirectUri);

    final sameScheme = incoming.scheme.toLowerCase() == expected.scheme.toLowerCase() ||
        incoming.scheme.toLowerCase() == 'miapp' ||
        incoming.scheme.toLowerCase().startsWith('discord-');
    final hasCodeOrError = incoming.queryParameters.containsKey('code') ||
        incoming.queryParameters.containsKey('error');

    return sameScheme && hasCodeOrError;
  }

  /// Intercambia el código de autorización por tokens utilizando PKCE (sin client_secret).
  Future<AuthTokens> exchangeCodeForTokens({
    required String code,
    required String verifier,
    required String redirectUri,
  }) async {
    final tokenUri = Uri.parse(AppConfig.discordTokenUrl);

    final response = await _httpClient.post(
      tokenUri,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'client_id': AppConfig.discordClientId,
        'grant_type': 'authorization_code',
        'code': code,
        'code_verifier': verifier,
        'redirect_uri': redirectUri,
      },
    );

    debugPrint('[OAuth] Discord token status: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthTokens.fromJson(json);
    }

    _handleOAuthHttpError(response);
    throw const OAuthException('Error desconocido al intercambiar tokens.');
  }

  /// Renueva los tokens utilizando el refresh token almacenado (sin client_secret para Public Client).
  Future<AuthTokens> refreshTokens(String refreshToken) async {
    final tokenUri = Uri.parse(AppConfig.discordTokenUrl);

    final response = await _httpClient.post(
      tokenUri,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'client_id': AppConfig.discordClientId,
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthTokens.fromJson(json);
    }

    _handleOAuthHttpError(response);
    throw const OAuthException('Error al renovar tokens.');
  }

  /// Obtiene los datos del perfil del usuario autenticado (/users/@me).
  Future<DiscordUser> fetchUserProfile(String accessToken) async {
    final userUri = Uri.parse(AppConfig.discordCurrentUserUrl);

    final response = await _httpClient.get(
      userUri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return DiscordUser.fromJson(json);
    } else if (response.statusCode == 401) {
      throw const SessionExpiredException('El token de acceso no es válido o fue revocado.');
    }

    throw OAuthException('Error al obtener perfil del usuario (${response.statusCode}).');
  }

  /// Revoca el token de acceso o refresh token.
  Future<void> revokeToken(String token, {bool isRefreshToken = false}) async {
    try {
      final revokeUri = Uri.parse(AppConfig.discordTokenRevokeUrl);
      await _httpClient.post(
        revokeUri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': AppConfig.discordClientId,
          'token': token,
          'token_type_hint': isRefreshToken ? 'refresh_token' : 'access_token',
        },
      );
    } catch (_) {
      // La revocación no debe bloquear el cierre de sesión local
    }
  }

  void _handleOAuthHttpError(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final error = json['error'] as String?;
      final description = json['error_description'] as String?;

      if (error == 'invalid_grant') {
        throw SessionExpiredException(description ?? 'El código o refresh token ha expirado.');
      } else if (error != null) {
        throw OAuthException(description ?? 'Error en la autorización ($error)', errorCode: error);
      }
    } catch (e) {
      if (e is Exception) rethrow;
    }

    throw OAuthException('Error del servidor de Discord (${response.statusCode}): ${response.reasonPhrase}');
  }
}

