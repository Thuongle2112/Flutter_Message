import '../../entities/conversation.dart';
import '../../repositories/message_repository.dart';

class GetConversationsUseCase {
  final MessageRepository repository;

  GetConversationsUseCase(this.repository);

  Stream<List<Conversation>> call(String userId) {
    return repository.getConversations(userId);
  }
}