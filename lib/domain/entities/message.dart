import 'package:equatable/equatable.dart';

enum MessageType {
  text,
  voice,
  image,
  video,
  file,
  read_receipt,
  unknown
}

class Message extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final String conversationId;
  final int? duration; // For voice messages

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
    required this.conversationId,
    this.duration,
  });

  @override
  List<Object?> get props => [
    id,
    senderId,
    receiverId,
    content,
    timestamp,
    isRead,
    type,
    conversationId,
    duration,
  ];

  // Helper method to check if this is a text message
  bool get isTextMessage => type == MessageType.text;

  // Helper method to check if this is a voice message
  bool get isVoiceMessage => type == MessageType.voice;

  // Helper method to check if this is an image message
  bool get isImageMessage => type == MessageType.image;
}