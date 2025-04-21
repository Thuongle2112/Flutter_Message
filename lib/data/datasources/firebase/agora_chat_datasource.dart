import 'dart:async';

abstract class AgoraChatDataSource {
  // Stream for receiving messages
  Stream<Map<String, dynamic>> get messageStream;

  // Check if user is logged in
  bool get isLoggedIn;

  // Initialize the chat client
  Future<void> initialize();

  // Login to chat service
  Future<void> login(String userId, String? token);

  // Logout from chat service
  Future<void> logout();

  // Get current user ID
  Future<String?> getCurrentUserId();

  // Send text message
  Future<void> sendMessage(String peerId, String content, {String? conversationId});

  // Send voice message
  Future<void> sendVoiceMessage(String peerId, String filePath, int duration, {String? conversationId});

  // Mark conversation as read
  Future<void> markConversationRead(String conversationId);

  // Start a new chat
  Future<String> startChat(String userId);

  // Get all conversations
  Stream<List<Map<String, dynamic>>> getConversations();

  // Get messages for a specific conversation
  Stream<List<Map<String, dynamic>>> getMessages(String conversationId, {int limit = 20});
}