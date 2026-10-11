import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/discord_user.dart';
import '../services/auth_check_service.dart';
import '../services/discord_oauth_service.dart';
import '../services/secure_token_storage.dart';

/// Repositorio central para la gestión del ciclo de vida de la sesión y autenticación.
class AuthRepository {
  final DiscordOAuthService _oauthService;
  final SecureTokenStorage _tokenStorage;

  // Estado reactivo del usuario actual
  final ValueNotifier<DiscordUser?> _currentUserNotifier = ValueNotifier<DiscordUser?>(null);
  ValueListenable<DiscordUser?> get userListenable => _currentUserNotifier;
  DiscordUser? get currentUser => _currentUserNotifier.value;

  AuthRepository({
    DiscordOAuthService? oauthService,
    SecureTokenStorage? tokenStorage,
  })  : _oauthService = oauthService ?? DiscordOAuthService(),
        _tokenStorage = tokenStorage ?? SecureTokenStorage();

  /// Comprueba la sesión guardada y la restaura o renueva según sea necesario.
  Future<AuthStatus> checkAndRestoreSession() async {
    try {
      final tokens = await _tokenStorage.getTokens();
      if (tokens == null) {
        _currentUserNotifier.value = null;
        return AuthStatus.unauthenticated;
      }

      // Si el token aún es válido
      if (!tokens.isExpired && !tokens.willExpireSoon()) {
        try {
          final user = await _oauthService.fetchUserProfile(tokens.accessToken);
          await _tokenStorage.saveUser(user);
          _currentUserNotifier.value = user;
          return AuthStatus.authenticated;
        } on NetworkException {
          // Si no hay red pero el token es localmente válido, restaura desde caché segura
          final cachedUser = await _tokenStorage.getUser();
          if (cachedUser != null) {
            _currentUserNotifier.value = cachedUser;
            return AuthStatus.authenticated;
          }
          return AuthStatus.unauthenticated;
        } on SessionExpiredException {
          // Si Discord rechaza el token (revocado), intenta renovar si hay refresh_token
          if (tokens.refreshToken != null) {
            return await _tryRefreshToken(tokens.refreshToken!);
          }
          await _tokenStorage.clearSession();
          _currentUserNotifier.value = null;
          return AuthStatus.sessionExpired;
        } catch (_) {
          // Si ocurrió otro error pero hay refresh token, intenta renovar
          if (tokens.refreshToken != null) {
            return await _tryRefreshToken(tokens.refreshToken!);
          }
          return AuthStatus.unauthenticated;
        }
      }

      // Si el token expiró pero tenemos un refresh_token
      if (tokens.refreshToken != null) {
        return await _tryRefreshToken(tokens.refreshToken!);
      }

      // Expirado y sin refresh token
      await _tokenStorage.clearSession();
      _currentUserNotifier.value = null;
      return AuthStatus.sessionExpired;
    } catch (_) {
      _currentUserNotifier.value = null;
      return AuthStatus.unauthenticated;
    }
  }

  /// Intenta renovar el token de forma segura sin exponer credenciales.
  Future<AuthStatus> _tryRefreshToken(String refreshToken) async {
    try {
      final newTokens = await _oauthService.refreshTokens(refreshToken);
      await _tokenStorage.saveTokens(newTokens);

      final user = await _oauthService.fetchUserProfile(newTokens.accessToken);
      await _tokenStorage.saveUser(user);
      _currentUserNotifier.value = user;
      return AuthStatus.authenticated;
    } on SessionExpiredException {
      await _tokenStorage.clearSession();
      _currentUserNotifier.value = null;
      return AuthStatus.sessionExpired;
    } catch (_) {
      // Si falla la renovación por fallo de red, verifica si hay usuario en caché
      final cachedUser = await _tokenStorage.getUser();
      if (cachedUser != null) {
        _currentUserNotifier.value = cachedUser;
        return AuthStatus.authenticated;
      }
      return AuthStatus.unauthenticated;
    }
  }

  /// Inicia el flujo de autenticación con Discord mediante PKCE.
  Future<DiscordUser> loginWithDiscord({String? redirectUri}) async {
    final tokens = await _oauthService.authenticate(redirectUri: redirectUri);
    await _tokenStorage.saveTokens(tokens);

    final user = await _oauthService.fetchUserProfile(tokens.accessToken);
    await _tokenStorage.saveUser(user);

    _currentUserNotifier.value = user;
    return user;
  }

  /// Cierra la sesión activa, revoca los tokens y purga los datos locales seguros.
  Future<void> logout() async {
    final tokens = await _tokenStorage.getTokens();
    if (tokens != null) {
      // Revoca el token de forma asíncrona sin bloquear
      unawaited(_oauthService.revokeToken(tokens.accessToken));
      if (tokens.refreshToken != null) {
        unawaited(_oauthService.revokeToken(tokens.refreshToken!, isRefreshToken: true));
      }
    }

    await _tokenStorage.clearSession();
    _currentUserNotifier.value = null;
  }
}

