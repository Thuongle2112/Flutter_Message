import 'package:equatable/equatable.dart';
import '../../../domain/entities/app_user.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserEvent extends UserEvent {
  final String userId;

  const LoadUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class SearchUsersEvent extends UserEvent {
  final String query;

  const SearchUsersEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class UpdateUserEvent extends UserEvent {
  final AppUser user;

  const UpdateUserEvent(this.user);

  @override
  List<Object?> get props => [user];
}