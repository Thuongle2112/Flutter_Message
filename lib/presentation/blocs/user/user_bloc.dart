import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/user_repository.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository userRepository;

  UserBloc({
    required this.userRepository,
  }) : super(UserInitial()) {
    on<LoadUserEvent>(_onLoadUser);
    on<SearchUsersEvent>(_onSearchUsers);
    on<UpdateUserEvent>(_onUpdateUser);
  }

  Future<void> _onLoadUser(
    LoadUserEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      final user = await userRepository.getUserById(event.userId);
      if (user != null) {
        emit(UserLoaded(user));
      } else {
        emit(const UserError('User not found'));
      }
    } catch (e) {
      emit(UserError('Failed to load user: $e'));
    }
  }

  Future<void> _onSearchUsers(
    SearchUsersEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      if (event.query.trim().isEmpty) {
        emit(const UsersSearchResult([]));
        return;
      }

      final users = await userRepository.searchUsers(event.query);
      emit(UsersSearchResult(users));
    } catch (e) {
      emit(UserError('Failed to search users: $e'));
    }
  }

  Future<void> _onUpdateUser(
    UpdateUserEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      await userRepository.updateUser(event.user);
      emit(UserUpdated());
      emit(UserLoaded(event.user));
    } catch (e) {
      emit(UserError('Failed to update user: $e'));
    }
  }
}
