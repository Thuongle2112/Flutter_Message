import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import 'message_model.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required String id,
    required List<String> participants,
    required Message lastMessage,
    required DateTime lastMessageTime,
    int unreadCount = 0,
    List<Message> messages = const [],
  }) : super(
    id: id,
    participants: participants,
    lastMessage: lastMessage,
    lastMessageTime: lastMessageTime,
    unreadCount: unreadCount,
    messages: messages,
  );

  factory ConversationModel.fromMap(Map<String, dynamic> map, String currentUserId) {
    // Xử lý danh sách tin nhắn trước
    List<Message> messages = [];
    if (map['messages'] is List) {
      messages = (map['messages'] as List).map((msgMap) =>
          MessageModel(
            id: msgMap['id'] ?? '',
            senderId: msgMap['senderId'] ?? '',
            receiverId: msgMap['receiverId'] ?? '',
            content: msgMap['content'] ?? '',
            timestamp: DateTime.fromMillisecondsSinceEpoch(msgMap['timestamp'] ?? 0),
            isRead: msgMap['isRead'] ?? false,
            type: _getMessageTypeFromString(msgMap['type'] ?? 'text'),
            conversationId: map['id'] ?? '',
            duration: msgMap['duration'],
          )
      ).toList();

      // Sắp xếp theo thời gian tăng dần (cũ nhất lên đầu)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    // Tìm tin nhắn cuối cùng từ danh sách hoặc sử dụng lastMessage từ map
    Message lastMessage;

    if (messages.isNotEmpty) {
      // Lấy tin nhắn gần đây nhất từ danh sách đã sắp xếp
      lastMessage = messages.last;
    } else {
      // Sử dụng lastMessage từ map nếu không có messages
      lastMessage = MessageModel(
        id: map['lastMessage']?['id'] ?? '',
        senderId: map['lastMessage']?['senderId'] ?? '',
        receiverId: map['lastMessage']?['receiverId'] ?? '',
        content: map['lastMessage']?['content'] ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['lastMessage']?['timestamp'] ?? 0),
        isRead: map['lastMessage']?['isRead'] ?? false,
        type: _getMessageTypeFromString(map['lastMessage']?['type'] ?? 'text'),
        conversationId: map['id'] ?? '',
        duration: map['lastMessage']?['duration'],
      );

      // Nếu lastMessage hợp lệ và chưa có trong danh sách, thêm vào
      if (lastMessage.id.isNotEmpty && messages.isEmpty) {
        messages = [lastMessage];
      }
    }

    // Xác định participants
    List<String> participants = [];
    if (map['participants'] is List) {
      participants = List<String>.from(map['participants']);
    } else {
      // Xác định người tham gia từ tin nhắn hoặc id
      String otherUserId = '';

      // Thử lấy từ conversationId (nếu có format userId1:userId2)
      final String convId = map['id'] ?? '';
      if (convId.contains(':')) {
        final parts = convId.split(':');
        otherUserId = parts[0] == currentUserId ? parts[1] : parts[0];
      } else {
        // Lấy từ lastMessage
        otherUserId = lastMessage.senderId == currentUserId
            ? lastMessage.receiverId
            : lastMessage.senderId;
      }

      participants = [currentUserId, otherUserId];
    }

    // Tính số tin nhắn chưa đọc
    int unreadCount = map['unreadCount'] ?? 0;

    // Nếu không có unreadCount từ map, tính từ messages
    if (map['unreadCount'] == null && messages.isNotEmpty) {
      unreadCount = messages.where((msg) =>
      msg.senderId != currentUserId && !msg.isRead
      ).length;
    }

    return ConversationModel(
      id: map['id'] ?? '',
      participants: participants,
      lastMessage: lastMessage,
      lastMessageTime: lastMessage.timestamp,
      unreadCount: unreadCount,
      messages: messages,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage is MessageModel
          ? (lastMessage as MessageModel).toMap()
          : {
        'id': lastMessage.id,
        'senderId': lastMessage.senderId,
        'receiverId': lastMessage.receiverId,
        'content': lastMessage.content,
        'timestamp': lastMessage.timestamp.millisecondsSinceEpoch,
        'isRead': lastMessage.isRead,
        'type': _getStringFromMessageType(lastMessage.type),
        'conversationId': lastMessage.conversationId,
        'duration': lastMessage.duration,
      },
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'timestamp': lastMessageTime.millisecondsSinceEpoch, // Thêm timestamp để tương thích
      'unreadCount': unreadCount,
      'messages': messages.map((message) {
        if (message is MessageModel) {
          return (message as MessageModel).toMap();
        }
        return {
          'id': message.id,
          'senderId': message.senderId,
          'receiverId': message.receiverId,
          'content': message.content,
          'timestamp': message.timestamp.millisecondsSinceEpoch,
          'isRead': message.isRead,
          'type': _getStringFromMessageType(message.type),
          'conversationId': message.conversationId,
          'duration': message.duration,
        };
      }).toList(),
    };
  }

  // Helper method để chuyển đổi MessageType sang String
  static String _getStringFromMessageType(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'text';
      case MessageType.voice:
        return 'voice';
      case MessageType.image:
        return 'image';
      case MessageType.read_receipt:
        return 'read_receipt';
      default:
        return 'text';
    }
  }

  // Helper method để chuyển đổi String sang MessageType
  static MessageType _getMessageTypeFromString(String type) {
    switch (type) {
      case 'voice':
        return MessageType.voice;
      case 'image':
        return MessageType.image;
      case 'read_receipt':
        return MessageType.read_receipt;
      default:
        return MessageType.text;
    }
  }

  // Thêm một tin nhắn mới và cập nhật lastMessage nếu cần
  @override
  Conversation addMessage(Message newMessage) {
    final List<Message> updatedMessages = List<Message>.from(messages);

    // Kiểm tra xem tin nhắn đã tồn tại chưa
    bool exists = updatedMessages.any((msg) => msg.id == newMessage.id);
    if (!exists) {
      updatedMessages.add(newMessage);
    }

    // Sắp xếp lại theo thời gian
    updatedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Kiểm tra xem cần cập nhật lastMessage không
    Message latestMessage = lastMessage;
    DateTime latestTime = lastMessageTime;
    if (newMessage.timestamp.isAfter(lastMessageTime)) {
      latestMessage = newMessage;
      latestTime = newMessage.timestamp;
    }

    // Cập nhật unreadCount nếu tin nhắn từ người khác và chưa đọc
    int updatedUnreadCount = unreadCount;
    if (newMessage.senderId != participants[0] && !newMessage.isRead && !exists) {
      updatedUnreadCount += 1;
    }

    return ConversationModel(
      id: id,
      participants: participants,
      lastMessage: latestMessage,
      lastMessageTime: latestTime,
      unreadCount: updatedUnreadCount,
      messages: updatedMessages,
    );
  }

  // Đánh dấu tất cả tin nhắn đã đọc
  @override
  Conversation markAllAsRead() {
    if (unreadCount == 0) return this;

    final List<Message> updatedMessages = messages.map((message) {
      if (!message.isRead && message.senderId != participants[0]) {
        if (message is MessageModel) {
          return (message as MessageModel).copyWith(isRead: true);
        } else {
          // Fallback nếu không phải MessageModel
          return MessageModel(
            id: message.id,
            senderId: message.senderId,
            receiverId: message.receiverId,
            content: message.content,
            timestamp: message.timestamp,
            isRead: true,
            type: message.type,
            conversationId: message.conversationId,
            duration: message.duration,
          );
        }
      }
      return message;
    }).toList();

    return ConversationModel(
      id: id,
      participants: participants,
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
      unreadCount: 0, // Đánh dấu tất cả đã đọc
      messages: updatedMessages,
    );
  }

  // Cập nhật danh sách tin nhắn hoàn toàn mới
  ConversationModel updateMessages(List<Message> newMessages) {
    if (newMessages.isEmpty) return this;

    // Sắp xếp theo thời gian
    newMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Tìm tin nhắn mới nhất để cập nhật lastMessage
    final latestMessage = newMessages.last;

    // Tính số tin nhắn chưa đọc
    final newUnreadCount = newMessages.where((msg) =>
    msg.senderId != participants[0] && !msg.isRead
    ).length;

    return ConversationModel(
      id: id,
      participants: participants,
      lastMessage: latestMessage,
      lastMessageTime: latestMessage.timestamp,
      unreadCount: newUnreadCount,
      messages: newMessages,
    );
  }

  // Thêm nhiều tin nhắn vào cuộc trò chuyện (ví dụ: khi tải lịch sử)
  ConversationModel addMessages(List<Message> newMessages) {
    if (newMessages.isEmpty) return this;

    // Gộp tin nhắn mới và cũ, loại bỏ trùng lặp
    Map<String, Message> messageMap = {};

    // Thêm tin nhắn hiện tại
    for (var msg in messages) {
      messageMap[msg.id] = msg;
    }

    // Thêm tin nhắn mới
    for (var msg in newMessages) {
      messageMap[msg.id] = msg;
    }

    // Chuyển đổi lại thành danh sách và sắp xếp
    List<Message> combinedMessages = messageMap.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Tìm tin nhắn mới nhất
    Message latestMessage = lastMessage;
    DateTime latestTime = lastMessageTime;

    if (combinedMessages.isNotEmpty) {
      final newestMessage = combinedMessages.last;
      if (newestMessage.timestamp.isAfter(lastMessageTime)) {
        latestMessage = newestMessage;
        latestTime = newestMessage.timestamp;
      }
    }

    // Tính số tin nhắn chưa đọc
    int updatedUnreadCount = combinedMessages.where((msg) =>
    msg.senderId != participants[0] && !msg.isRead
    ).length;

    return ConversationModel(
      id: id,
      participants: participants,
      lastMessage: latestMessage,
      lastMessageTime: latestTime,
      unreadCount: updatedUnreadCount,
      messages: combinedMessages,
    );
  }
}