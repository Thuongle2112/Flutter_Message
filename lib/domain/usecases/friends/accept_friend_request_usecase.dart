import '../../repositories/user_repository.dart';

class AcceptFriendRequestUseCase {
  final UserRepository repository;

  AcceptFriendRequestUseCase(this.repository);

  Future<void> call(String userId, String requesterId) async {
    await repository.acceptFriendRequest(userId, requesterId);
  }
}