import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> login(String email, String password);
  Future<AppUser> register(String name, String email, String password);
  Future<void> logout();
  Future<AppUser?> getCurrentUser();
  Stream<firebase.User?> authStateChanges();
}
