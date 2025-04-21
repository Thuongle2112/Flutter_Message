import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required String id,
    required String senderId,
    required String receiverId,
    required String content,
    required DateTime timestamp,
    bool isRead = false,
    MessageType type = MessageType.text,
    required String conversationId,
    int? duration,
  }) : super(
    id: id,
    senderId: senderId,
    receiverId: receiverId,
    content: content,
    timestamp: timestamp,
    isRead: isRead,
    type: type,
    conversationId: conversationId,
    duration: duration,
  );

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    // Log for debugging
    print('MessageModel.fromMap: type=${map['type']}, content=${map['content']}');

    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      isRead: map['isRead'] ?? false,
      type: _getMessageTypeFromString(map['type'] ?? 'text'),
      conversationId: map['conversationId'] ?? '',
      duration: map['duration'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'type': _getStringFromMessageType(type),
      'conversationId': conversationId,
      'duration': duration,
    };
  }

  // Copy with method for creating new instances with modified properties
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    MessageType? type,
    String? conversationId,
    int? duration,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      conversationId: conversationId ?? this.conversationId,
      duration: duration ?? this.duration,
    );
  }

  static MessageType _getMessageTypeFromString(String type) {
    // Debug log
    print('Converting string "$type" to MessageType');

    switch (type.toLowerCase()) {
      case 'voice':
        return MessageType.voice;
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'file':
        return MessageType.file;
      case 'read_receipt':
        return MessageType.read_receipt;
      case 'text':
        return MessageType.text;
      default:
        print('Warning: Unknown message type string: "$type", defaulting to text');
        return MessageType.text; // Default to text
    }
  }

  static String _getStringFromMessageType(MessageType type) {
    switch (type) {
      case MessageType.voice:
        return 'voice';
      case MessageType.image:
        return 'image';
      case MessageType.video:
        return 'video';
      case MessageType.file:
        return 'file';
      case MessageType.read_receipt:
        return 'read_receipt';
      case MessageType.text:
        return 'text';
      default:
        return 'unknown';
    }
  }
}