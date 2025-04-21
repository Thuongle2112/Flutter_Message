import '../../entities/app_user.dart';
import '../../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<AppUser> call(String name, String email, String password) async {
    return await repository.register(name, email, password);
  }
}
