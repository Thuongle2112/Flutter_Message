import 'package:equatable/equatable.dart';
import '../../../domain/entities/app_user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

class RegisterEvent extends AuthEvent {
  final String name;
  final String email;
  final String password;

  const RegisterEvent(this.name, this.email, this.password);

  @override
  List<Object> get props => [name, email, password];
}

class LogoutEvent extends AuthEvent {}

class CheckAuthStatusEvent extends AuthEvent {}

// Add this new event
class AuthStateChangedEvent extends AuthEvent {
  final AppUser? user;

  const AuthStateChangedEvent(this.user);

  @override
  List<Object?> get props => [user];
}
