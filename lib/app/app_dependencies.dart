import '../features/auth/data/repositories/auth_repository.dart';
import '../features/auth/presentation/viewmodels/auth_controller.dart';

/// Contenedor de dependencias centralizado y ligero de la aplicación.
class AppDependencies {
  AppDependencies._();

  static final AuthRepository authRepository = AuthRepository();
  static final AuthController authController = AuthController(repository: authRepository);
}

