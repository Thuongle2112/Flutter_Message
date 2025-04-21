import 'dart:io';

import '../entities/conversation.dart';
import '../entities/message.dart';

abstract class MessageRepository {
  Stream<List<Message>> getMessages(
      String conversationId, String currentUserId);
  Future<void> sendMessage(Message message);
  Future<void> sendVoiceMessage(Message message, int duration);
  Future<String> uploadVoiceMessage(File audioFile, String userId);
  Stream<List<Conversation>> getConversations(String userId);
  Future<void> markConversationAsRead(String conversationId);
  Future<void> loginChat(String userId);
  Future<void> logoutChat();
  Future<bool> isLoggedIn();
}
