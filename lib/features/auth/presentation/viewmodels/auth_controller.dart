import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../data/models/discord_user.dart';
import '../../data/repositories/auth_repository.dart';

/// Controlador de presentación para la autenticación con Discord.
class AuthController extends ChangeNotifier {
  final AuthRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DiscordUser? get currentUser => _repository.currentUser;
  ValueListenable<DiscordUser?> get userListenable => _repository.userListenable;

  AuthController({AuthRepository? repository})
      : _repository = repository ?? AuthRepository() {
    _repository.userListenable.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _repository.userListenable.removeListener(notifyListeners);
    super.dispose();
  }

  /// Limpia mensajes de error previos.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Inicia sesión con Discord OAuth 2.0 y PKCE.
  Future<bool> login({String? redirectUri}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.loginWithDiscord(redirectUri: redirectUri);
      _isLoading = false;
      notifyListeners();
      return true;
    } on OAuthCancelledException {
      // El usuario canceló; no es un error fatal pero se informa sutilmente
      _errorMessage = 'Inicio de sesión cancelado.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on SessionExpiredException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } on NetworkException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } on OAuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Ocurrió un error inesperado al iniciar sesión con Discord.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cierra la sesión activa y purga las credenciales.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.logout();
    } finally {
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }
  }
}

