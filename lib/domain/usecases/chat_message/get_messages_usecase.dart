import '../../entities/message.dart';
import '../../repositories/message_repository.dart';

class GetMessagesUseCase {
  final MessageRepository repository;

  GetMessagesUseCase(this.repository);

  Stream<List<Message>> call(String conversationId, String currentUserId) {
    return repository.getMessages(conversationId, currentUserId);
  }
}