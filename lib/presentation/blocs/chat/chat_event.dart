import 'package:equatable/equatable.dart';
import '../../../domain/entities/message.dart';
import 'dart:io';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadMessagesEvent extends ChatEvent {
  final String conversationId;

  const LoadMessagesEvent(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SendMessageEvent extends ChatEvent {
  final Message message;

  const SendMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class SendVoiceMessageEvent extends ChatEvent {
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String filePath; // Thay vì File
  final int duration;

  const SendVoiceMessageEvent({
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.filePath,
    required this.duration,
  });

  @override
  List<Object> get props =>
      [conversationId, senderId, receiverId, filePath, duration];
}

class LoadConversationsEvent extends ChatEvent {
  final String userId;

  const LoadConversationsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class MarkConversationReadEvent extends ChatEvent {
  final String conversationId;

  const MarkConversationReadEvent(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}
