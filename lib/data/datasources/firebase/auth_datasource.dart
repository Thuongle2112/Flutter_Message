import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/entities/app_user.dart';

abstract class AuthDataSource {
  Future<AppUser> login(String email, String password);
  Future<AppUser> register(String name, String email, String password);
  Future<void> logout();
  Future<AppUser?> getCurrentUser();
  Stream<User?> authStateChanges();
  Stream<AppUser?> userDataChanges(); // New method
}
