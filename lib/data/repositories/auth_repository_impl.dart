import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase/auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<AppUser> login(String email, String password) async {
    return await dataSource.login(email, password);
  }

  @override
  Future<AppUser> register(String name, String email, String password) async {
    return await dataSource.register(name, email, password);
  }

  @override
  Future<void> logout() async {
    await dataSource.logout();
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    return await dataSource.getCurrentUser();
  }

  @override
  Stream<firebase.User?> authStateChanges() {
    return dataSource.authStateChanges();
  }
}