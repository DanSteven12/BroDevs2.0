import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/features/auth/data/models/auth_tokens.dart';
import 'package:mi_app/features/auth/data/models/discord_user.dart';
import 'package:mi_app/features/auth/data/services/discord_oauth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthTokens Model Tests', () {
    test('Calcula correctamente si el token está expirado', () {
      final expiredTokens = AuthTokens(
        accessToken: 'expired_token',
        tokenType: 'Bearer',
        expiresAt: DateTime.now().subtract(const Duration(seconds: 10)),
      );
      expect(expiredTokens.isExpired, isTrue);

      final validTokens = AuthTokens(
        accessToken: 'valid_token',
        tokenType: 'Bearer',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(validTokens.isExpired, isFalse);
    });

    test('Serialización y deserialización JSON mantiene los datos intactos', () {
      final expiry = DateTime.now().add(const Duration(days: 7));
      final original = AuthTokens(
        accessToken: 'tok_123',
        tokenType: 'Bearer',
        expiresAt: expiry,
        refreshToken: 'ref_456',
        scope: 'identify email',
      );

      final json = original.toJson();
      final restored = AuthTokens.fromJson(json);

      expect(restored.accessToken, 'tok_123');
      expect(restored.refreshToken, 'ref_456');
      expect(restored.scope, 'identify email');
      expect(restored.expiresAt.toIso8601String(), expiry.toIso8601String());
    });

    test('toString() no filtra credenciales sensibles en logs', () {
      final tokens = AuthTokens(
        accessToken: 'secret_access_token_12345',
        tokenType: 'Bearer',
        expiresAt: DateTime.now(),
        refreshToken: 'secret_refresh_token_67890',
      );

      final stringRep = tokens.toString();
      expect(stringRep.contains('secret_access_token_12345'), isFalse);
      expect(stringRep.contains('secret_refresh_token_67890'), isFalse);
    });
  });

  group('DiscordUser Model Tests', () {
    test('Parsea correctamente JSON de la API de Discord', () {
      final json = {
        'id': '1558663883747627010',
        'username': 'steven_user',
        'global_name': 'Steven Dev',
        'avatar': 'a1b2c3d4e5f6',
        'email': 'steven@example.com',
        'verified': true,
      };

      final user = DiscordUser.fromJson(json);

      expect(user.id, '1558663883747627010');
      expect(user.username, 'steven_user');
      expect(user.displayName, 'Steven Dev');
      expect(user.email, 'steven@example.com');
      expect(user.verified, isTrue);
      expect(user.avatarUrl, contains('1558663883747627010/a1b2c3d4e5f6.png'));
    });

    test('Usa username cuando global_name es null o vacío', () {
      final user = const DiscordUser(
        id: '123',
        username: 'solousuario',
      );
      expect(user.displayName, 'solousuario');
    });

    test('Genera URL de avatar por defecto cuando avatar es null', () {
      final user = const DiscordUser(
        id: '1558663883747627010',
        username: 'noavatar',
      );
      expect(user.avatarUrl, contains('/embed/avatars/'));
    });
  });

  group('DiscordOAuthService PKCE Tests', () {
    late DiscordOAuthService oauthService;

    setUp(() {
      oauthService = DiscordOAuthService();
    });

    test('generateCodeVerifier produce cadenas de longitud y entropía correctas', () {
      final verifier1 = oauthService.generateCodeVerifier(64);
      final verifier2 = oauthService.generateCodeVerifier(64);

      expect(verifier1.length, 64);
      expect(verifier2.length, 64);
      expect(verifier1, isNot(equals(verifier2)));
      // Caracteres permitidos por RFC 7636
      expect(RegExp(r'^[A-Za-z0-9\-._~]+$').hasMatch(verifier1), isTrue);
    });

    test('generateCodeChallenge implementa S256 (SHA-256 en Base64Url sin padding)', () {
      // Valor de prueba de vector estándar RFC 7636
      const verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
      final challenge = oauthService.generateCodeChallenge(verifier);

      // Esperado por RFC 7636 ejemplo
      const expectedChallenge = 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM';
      expect(challenge, expectedChallenge);
      expect(challenge.contains('='), isFalse);
    });

    test('generateState produce cadenas aleatorias únicas', () {
      final state1 = oauthService.generateState();
      final state2 = oauthService.generateState();

      expect(state1.length, 32);
      expect(state1, isNot(equals(state2)));
    });

    test('Parsea y valida URI de callback con esquema discord', () {
      final incoming = Uri.parse('discord-1558663883747627010:/authorize/callback?code=zzulJC8OiFOpHBajO667YiHHtInUcF&state=hV7iBrAmU106F8OLs7GFQFPnhhppXfaM&iss=https://discord.com');
      final expected = Uri.parse('discord-1558663883747627010:/authorize/callback');

      expect(incoming.scheme, equals(expected.scheme));
      expect(incoming.queryParameters['code'], equals('zzulJC8OiFOpHBajO667YiHHtInUcF'));
      expect(incoming.queryParameters['state'], equals('hV7iBrAmU106F8OLs7GFQFPnhhppXfaM'));
    });
  });
}

