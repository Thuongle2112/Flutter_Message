import '../../repositories/message_repository.dart';

class MarkConversationReadUseCase {
  final MessageRepository repository;

  MarkConversationReadUseCase(this.repository);

  Future<void> call(String conversationId) async {
    await repository.markConversationAsRead(conversationId);
  }
}