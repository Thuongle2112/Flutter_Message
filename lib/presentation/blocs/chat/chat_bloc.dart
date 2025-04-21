import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/message.dart';
import '../../../data/models/message_model.dart';
import '../../../domain/repositories/message_repository.dart';
import '../../../domain/usecases/chat_message/get_messages_usecase.dart';
import '../../../domain/usecases/chat_message/send_message_usecase.dart';
import '../../../domain/usecases/chat_message/get_conversations_usecase.dart';
import '../../../domain/usecases/chat_message/mark_conversation_read_usecase.dart';
import '../auth/auth_bloc.dart';
import '../auth/auth_state.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GetMessagesUseCase getMessages;
  final SendMessageUseCase sendMessage;
  final GetConversationsUseCase getConversations;
  final MarkConversationReadUseCase markConversationRead;
  final MessageRepository messageRepository;
  final AuthBloc authBloc;
  final FirebaseAuth _firebaseAuth;

  ChatBloc({
    required this.getMessages,
    required this.sendMessage,
    required this.getConversations,
    required this.markConversationRead,
    required this.messageRepository,
    required this.authBloc,
    FirebaseAuth? firebaseAuth,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        super(ChatInitial()) {
    on<LoadMessagesEvent>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<SendVoiceMessageEvent>(_onSendVoiceMessage);
    on<LoadConversationsEvent>(_onLoadConversations);
    on<MarkConversationReadEvent>(_onMarkConversationRead);
  }

  bool _isUserAuthenticated() {
    // Kiểm tra cả Firebase Auth và AuthBloc để đảm bảo tính đồng bộ
    final isFirebaseAuthenticated = _firebaseAuth.currentUser != null;
    final isAuthBlocAuthenticated = authBloc.state is Authenticated;

    print('Firebase authenticated: $isFirebaseAuthenticated');
    print('AuthBloc authenticated: $isAuthBlocAuthenticated');

    return isFirebaseAuthenticated && isAuthBlocAuthenticated;
  }

  Future<void> _onLoadMessages(
    LoadMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      print('Loading messages for conversation: ${event.conversationId}');

      if (!_isUserAuthenticated()) {
        emit(ChatError('User not logged in. Please log in to view messages.'));
        return;
      }

      // Lấy userId từ AuthBloc
      final userId = (authBloc.state as Authenticated).user.id;

      // Mark conversation as read when opening it
      await markConversationRead(event.conversationId);

      // Thêm userId vào tham số cuối cùng
      await emit.forEach(
        getMessages(event.conversationId, userId),
        onData: (List<Message> messages) => ChatMessagesLoaded(messages),
        onError: (error, stackTrace) => ChatError(error.toString()),
      );
    } catch (e) {
      emit(ChatError('Failed to load messages: ${e.toString()}'));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      // Kiểm tra đăng nhập trước khi gửi tin nhắn
      if (!_isUserAuthenticated()) {
        emit(ChatError('User not logged in. Please log in to send messages.'));
        return;
      }

      await sendMessage(event.message);
      emit(ChatMessageSent());
    } catch (e) {
      emit(ChatError('Failed to send message: ${e.toString()}'));
    }
  }

  Future<void> _onSendVoiceMessage(
      SendVoiceMessageEvent event, Emitter<ChatState> emit) async {
    try {
      emit(ChatLoading());

      // Tạo message model với đầy đủ thông tin
      final message = MessageModel(
        id: const Uuid().v4(),
        senderId: event.senderId,
        receiverId: event.receiverId,
        content: event.filePath, // Sử dụng filePath trực tiếp
        timestamp: DateTime.now(),
        type: MessageType.voice,
        conversationId: event.conversationId,
        duration: event.duration,
      );

      // Gửi tin nhắn
      await messageRepository.sendMessage(message);

      emit(ChatMessageSent());
    } catch (e) {
      print('Error in ChatBloc._onSendVoiceMessage: $e');
      emit(ChatError('Failed to send voice message: $e'));
    }
  }

  // Helper method để lấy thời gian (duration) của file audio
  Future<int> _getAudioFileDuration(File audioFile) async {
    try {
      // Đây là một phương pháp đơn giản
      // Trong thực tế bạn cần sử dụng một plugin để lấy chính xác thời lượng
      // Ví dụ: flutter_sound hoặc just_audio
      return 0; // Trả về 0 tạm thời, bạn cần thay thế bằng code thật
    } catch (e) {
      print('Error getting audio duration: $e');
      return 0;
    }
  }

  Future<void> _onLoadConversations(
    LoadConversationsEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      // Kiểm tra đăng nhập trước khi tải conversations
      if (!_isUserAuthenticated()) {
        print('Current Firebase user: ${_firebaseAuth.currentUser?.uid}');
        print('Current AuthBloc state: ${authBloc.state}');
        emit(ChatError(
            'User not logged in. Please log in to view conversations.'));
        return;
      }

      // Lấy ID người dùng từ event hoặc từ AuthBloc
      final userId = event.userId ?? (authBloc.state as Authenticated).user.id;

      await emit.forEach(getConversations(userId),
          onData: (conversations) => ChatConversationsLoaded(conversations),
          onError: (error, stackTrace) {
            print('Error loading conversations: $error');
            print('Stack trace: $stackTrace');
            return ChatError(
                'Failed to load conversations: ${error.toString()}');
          });
    } catch (e) {
      print('Exception in _onLoadConversations: $e');
      emit(ChatError('Failed to load conversations: ${e.toString()}'));
    }
  }

  Future<void> _onMarkConversationRead(
    MarkConversationReadEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      // Kiểm tra đăng nhập trước khi đánh dấu đã đọc
      if (!_isUserAuthenticated()) {
        emit(ChatError(
            'User not logged in. Please log in to mark conversations as read.'));
        return;
      }

      await markConversationRead(event.conversationId);
    } catch (e) {
      emit(ChatError('Failed to mark conversation as read: ${e.toString()}'));
    }
  }
}
