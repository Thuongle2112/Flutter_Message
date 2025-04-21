import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/firebase/agora_chat_datasource.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';

class MessageRepositoryImpl implements MessageRepository {
  final AgoraChatDataSource chatDataSource;
  final Uuid _uuid = const Uuid();

  // BehaviorSubjects để lưu giữ và quản lý conversations
  final BehaviorSubject<Map<String, Conversation>> _conversationsSubject =
  BehaviorSubject<Map<String, Conversation>>.seeded({});

  // Subscription để lắng nghe messageStream
  StreamSubscription? _messageSubscription;

  // Caching user ID
  String? _currentUserId;

  MessageRepositoryImpl({
    required this.chatDataSource,
  });

  // Khởi tạo và theo dõi tin nhắn
  void _initialize(String userId) {
    _currentUserId = userId;

    // Hủy subscription cũ nếu có
    _messageSubscription?.cancel();

    // Đăng ký theo dõi tin nhắn mới
    _messageSubscription = chatDataSource.messageStream.listen(
            (messageData) => _handleNewMessage(messageData, userId),
        onError: (error) => print('Error in message stream: $error')
    );
  }

  // Xử lý tin nhắn mới
  void _handleNewMessage(Map<String, dynamic> messageData, String userId) {
    try {
      // Bỏ qua tin nhắn không có conversationId
      if (messageData['conversationId'] == null) return;

      // Bỏ qua tin nhắn read_receipt (xử lý riêng)
      final isReadReceipt = messageData['type'] == 'read_receipt';
      if (isReadReceipt) {
        _handleReadReceipt(messageData);
        return;
      }

      final conversationId = messageData['conversationId'];

      // Xác định loại tin nhắn
      MessageType msgType = MessageType.text;
      if (messageData['type'] == 'voice') {
        msgType = MessageType.voice;
      } else if (messageData['type'] == 'image') {
        msgType = MessageType.image;
      }

      // Xác định người nhận từ conversationId nếu không có
      String receiverId = messageData['receiverId'] ?? '';
      if (receiverId.isEmpty) {
        final parts = conversationId.split(':');
        if (parts.length == 2) {
          receiverId = parts[0] == userId ? parts[1] : parts[0];
        }
      }

      // Tạo đối tượng tin nhắn
      final message = MessageModel(
        id: messageData['id'] ?? _uuid.v4(),
        senderId: messageData['senderId'] ?? '',
        receiverId: receiverId,
        content: messageData['content'] ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(messageData['timestamp']),
        isRead: messageData['isRead'] ?? false,
        type: msgType,
        conversationId: conversationId,
        duration: messageData['duration'],
      );

      // Lấy bản sao hiện tại của conversations
      final conversations = Map<String, Conversation>.from(_conversationsSubject.value);

      // Tìm hoặc tạo conversation
      if (conversations.containsKey(conversationId)) {
        // Cập nhật conversation hiện có
        final existingConv = conversations[conversationId]!;
        conversations[conversationId] = existingConv.addMessage(message);
      } else {
        // Xác định người tham gia
        final parts = conversationId.split(':');
        List<String> participants = [];

        if (parts.length == 2) {
          participants = [userId, parts[0] == userId ? parts[1] : parts[0]];
        } else {
          participants = [userId, message.senderId == userId ? message.receiverId : message.senderId];
        }

        // Tạo conversation mới
        final newConversation = ConversationModel(
          id: conversationId,
          participants: participants,
          lastMessage: message,
          lastMessageTime: message.timestamp,
          unreadCount: message.senderId != userId ? 1 : 0,
          messages: [message],
        );

        conversations[conversationId] = newConversation;
      }

      // Cập nhật subject
      _conversationsSubject.add(conversations);
    } catch (e) {
      print('Error handling new message: $e');
    }
  }

  // Xử lý tin nhắn đã đọc
  void _handleReadReceipt(Map<String, dynamic> receiptData) {
    try {
      final conversationId = receiptData['conversationId'];

      // Bỏ qua nếu không có conversationId
      if (conversationId == null) return;

      // Lấy conversations hiện tại
      final conversations = Map<String, Conversation>.from(_conversationsSubject.value);

      // Tìm conversation
      if (conversations.containsKey(conversationId)) {
        final conversation = conversations[conversationId]!;

        // Đánh dấu tất cả tin nhắn là đã đọc
        conversations[conversationId] = conversation.markAllAsRead();

        // Cập nhật subject
        _conversationsSubject.add(conversations);
      }
    } catch (e) {
      print('Error handling read receipt: $e');
    }
  }

  @override
  Stream<List<Message>> getMessages(String conversationId, String currentUserId) {
    // Đảm bảo đã khởi tạo
    if (_currentUserId != currentUserId) {
      _initialize(currentUserId);
    }

    return _conversationsSubject.stream
        .map((conversations) => conversations[conversationId]?.messages ?? []);
  }

  @override
  Stream<List<Conversation>> getConversations(String userId) {
    // Đảm bảo đã khởi tạo
    if (_currentUserId != userId) {
      _initialize(userId);
    }

    // Trả về stream của danh sách conversations, đã sắp xếp theo thời gian mới nhất
    return _conversationsSubject.stream.map((convMap) {
      final List<Conversation> result = convMap.values.toList();
      result.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return result;
    });
  }

  @override
  Future<void> sendMessage(Message message) async {
    try {
      if (message.type == MessageType.voice) {
        await chatDataSource.sendVoiceMessage(
          message.receiverId,
          message.content,
          message.duration ?? 0,
          conversationId: message.conversationId,
        );
      } else {
        await chatDataSource.sendMessage(
          message.receiverId,
          message.content,
          conversationId: message.conversationId,
        );
      }

      // Tin nhắn sẽ được xử lý qua messageStream
    } catch (e) {
      print('Failed to send message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  @override
  Future<String> uploadVoiceMessage(File audioFile, String userId) async {
    try {
      // Convert audio file to base64
      final bytes = await audioFile.readAsBytes();
      final base64Audio = base64Encode(bytes);

      // Prefix to indicate this is a base64 audio
      return "base64audio:$base64Audio";
    } catch (e) {
      print('Failed to process voice message: $e');
      throw Exception('Failed to process voice message: $e');
    }
  }

  @override
  Future<void> sendVoiceMessage(Message message, int duration) async {
    try {
      await chatDataSource.sendVoiceMessage(
        message.receiverId,
        message.content,
        duration,
        conversationId: message.conversationId,
      );
    } catch (e) {
      print('Failed to send voice message: $e');
      throw Exception('Failed to send voice message: $e');
    }
  }

  @override
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      await chatDataSource.markConversationRead(conversationId);

      // Thực hiện cập nhật local
      final conversations = Map<String, Conversation>.from(_conversationsSubject.value);
      if (conversations.containsKey(conversationId)) {
        conversations[conversationId] = conversations[conversationId]!.markAllAsRead();
        _conversationsSubject.add(conversations);
      }
    } catch (e) {
      print('Failed to mark conversation as read: $e');
      throw Exception('Failed to mark conversation as read: $e');
    }
  }

  @override
  Future<void> loginChat(String userId) async {
    try {
      await chatDataSource.initialize();
      await chatDataSource.login(userId, null);

      // Khởi tạo lắng nghe tin nhắn
      _initialize(userId);
    } catch (e) {
      print('Failed to login to chat: $e');
      throw Exception('Failed to login to chat: $e');
    }
  }

  @override
  Future<void> logoutChat() async {
    try {
      await chatDataSource.logout();

      // Dọn dẹp
      _messageSubscription?.cancel();
      _currentUserId = null;
      _conversationsSubject.add({});
    } catch (e) {
      print('Failed to logout from chat: $e');
      throw Exception('Failed to logout from chat: $e');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      return chatDataSource.isLoggedIn;
    } catch (e) {
      print('Failed to check login status: $e');
      throw Exception('Failed to check login status: $e');
    }
  }

  // Đảm bảo giải phóng tài nguyên
  void dispose() {
    _messageSubscription?.cancel();
    _conversationsSubject.close();
  }
}