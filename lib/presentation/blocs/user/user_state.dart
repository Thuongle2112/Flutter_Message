import 'package:equatable/equatable.dart';
import '../../../domain/entities/app_user.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final AppUser user;

  const UserLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class UsersSearchResult extends UserState {
  final List<AppUser> users;

  const UsersSearchResult(this.users);

  @override
  List<Object?> get props => [users];
}

class UserUpdated extends UserState {}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}