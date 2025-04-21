import '../../repositories/message_repository.dart';

class StartChatWithFriendUseCase {
  final MessageRepository repository;

  StartChatWithFriendUseCase(this.repository);

  Future<String> call(String currentUserId, String friendId) async {
    // Tạo ID cuộc hội thoại từ ID người dùng hiện tại và ID người bạn
    List<String> userIds = [currentUserId, friendId];
    userIds.sort(); // Sắp xếp để đảm bảo ID cuộc hội thoại nhất quán
    String conversationId = '${userIds[0]}:${userIds[1]}';

    // Đăng nhập vào dịch vụ chat nếu chưa đăng nhập
    if (!(await repository.isLoggedIn())) {
      await repository.loginChat(currentUserId);
    }

    return conversationId;
  }
}