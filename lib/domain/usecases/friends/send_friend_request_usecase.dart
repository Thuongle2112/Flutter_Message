import '../../repositories/user_repository.dart';

class SendFriendRequestUseCase {
  final UserRepository repository;

  SendFriendRequestUseCase(this.repository);

  Future<void> call(String senderId, String receiverId) async {
    await repository.sendFriendRequest(senderId, receiverId);
  }
}