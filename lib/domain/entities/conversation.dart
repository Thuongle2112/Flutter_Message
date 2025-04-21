import 'package:equatable/equatable.dart';
import '../../data/models/message_model.dart';
import 'message.dart';

class Conversation extends Equatable {
  final String id;
  final List<String> participants;
  final Message lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final List<Message> messages; // Danh sách tin nhắn trong cuộc trò chuyện

  const Conversation({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.messages = const [], // Mặc định là danh sách rỗng
  });

  @override
  List<Object?> get props => [
    id,
    participants,
    lastMessage,
    lastMessageTime,
    unreadCount,
    messages, // Thêm messages vào props
  ];

  Conversation copyWith({
    String? id,
    List<String>? participants,
    Message? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    List<Message>? messages,
  }) {
    return Conversation(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      messages: messages ?? this.messages,
    );
  }

  // Phương thức để thêm tin nhắn mới vào cuộc trò chuyện
  Conversation addMessage(Message newMessage) {
    final updatedMessages = List<Message>.from(messages);

    // Kiểm tra nếu tin nhắn đã tồn tại (tránh trùng lặp)
    bool messageExists = updatedMessages.any((message) => message.id == newMessage.id);

    if (!messageExists) {
      updatedMessages.add(newMessage);
      // Sắp xếp theo thời gian
      updatedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    // Chỉ cập nhật lastMessage nếu tin nhắn mới thực sự mới hơn
    final shouldUpdateLastMessage = newMessage.timestamp.isAfter(lastMessageTime);

    return Conversation(
      id: id,
      participants: participants,
      lastMessage: shouldUpdateLastMessage ? newMessage : lastMessage,
      lastMessageTime: shouldUpdateLastMessage ? newMessage.timestamp : lastMessageTime,
      unreadCount: newMessage.senderId != participants.first && !newMessage.isRead
          ? unreadCount + (messageExists ? 0 : 1)
          : unreadCount,
      messages: updatedMessages,
    );
  }

  // Phương thức để đánh dấu tất cả tin nhắn đã đọc
  Conversation markAllAsRead() {
    final updatedMessages = messages.map((message) {
      if (!message.isRead) {
        // Đánh dấu tin nhắn đã đọc
        if (message is MessageModel) {
          return message.copyWith(isRead: true);
        } else {
          // Nếu không phải MessageModel, tạo một bản sao có isRead = true
          return Message(
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

    return copyWith(
      unreadCount: 0,
      messages: updatedMessages,
    );
  }
}