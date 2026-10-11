import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_tokens.dart';
import '../models/discord_user.dart';

/// Servicio de almacenamiento protegido mediante cifrado nativo
/// (Android Keystore + EncryptedSharedPreferences).
class SecureTokenStorage {
  static const String _tokensKey = 'discord_oauth_tokens';
  static const String _userKey = 'discord_oauth_user';

  final FlutterSecureStorage _storage;

  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  /// Guarda los tokens de sesión de forma segura.
  Future<void> saveTokens(AuthTokens tokens) async {
    final serialized = jsonEncode(tokens.toJson());
    await _storage.write(key: _tokensKey, value: serialized);
  }

  /// Recupera los tokens guardados o retorna null si no existen o están corruptos.
  Future<AuthTokens?> getTokens() async {
    try {
      final data = await _storage.read(key: _tokensKey);
      if (data == null || data.isEmpty) return null;
      final json = jsonDecode(data) as Map<String, dynamic>;
      return AuthTokens.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Guarda la información del usuario en caché cifrada para restauración instantánea.
  Future<void> saveUser(DiscordUser user) async {
    final serialized = jsonEncode(user.toJson());
    await _storage.write(key: _userKey, value: serialized);
  }

  /// Recupera el usuario guardado.
  Future<DiscordUser?> getUser() async {
    try {
      final data = await _storage.read(key: _userKey);
      if (data == null || data.isEmpty) return null;
      final json = jsonDecode(data) as Map<String, dynamic>;
      return DiscordUser.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Elimina por completo las credenciales y datos de sesión al cerrar sesión.
  Future<void> clearSession() async {
    await _storage.delete(key: _tokensKey);
    await _storage.delete(key: _userKey);
  }
}

