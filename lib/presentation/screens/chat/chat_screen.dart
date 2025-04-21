import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/message_model.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/message.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/chat/chat_event.dart';
import '../../blocs/chat/chat_state.dart';
import '../../widgets/message_bubble.dart';
import 'voice_message_recorder.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String currentUserId;
  final AppUser? friend;

  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.currentUserId,
    this.friend,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final uuid = const Uuid();
  String _receiverId = '';
  bool _isShowingVoiceRecorder = false;
  bool _isSendingVoiceMessage = false;

  @override
  void initState() {
    super.initState();
    _determineReceiverId();

    // Tải tin nhắn và đánh dấu đã đọc
    context.read<ChatBloc>().add(LoadMessagesEvent(widget.conversationId));
    context
        .read<ChatBloc>()
        .add(MarkConversationReadEvent(widget.conversationId));

    // Debug log
    print(
        'ChatScreen initialized: conversationId=${widget.conversationId}, receiverId=$_receiverId');
  }

  void _determineReceiverId() {
    if (widget.friend != null) {
      setState(() {
        _receiverId = widget.friend!.id;
      });
    } else {
      final participants = widget.conversationId.split('_');
      setState(() {
        _receiverId = participants.firstWhere(
          (id) => id != widget.currentUserId,
          orElse: () => '',
        );
      });
    }

    // Debug log kết quả
    print(
        'Determined receiverId: $_receiverId from conversationId: ${widget.conversationId}');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    print('Sending text message: $text to $_receiverId');

    // Tạo tin nhắn với đầy đủ thông tin
    final message = MessageModel(
      id: uuid.v4(),
      senderId: widget.currentUserId,
      receiverId: _receiverId,
      content: text,
      timestamp: DateTime.now(),
      isRead: false,
      type: MessageType.text,
      conversationId: widget.conversationId, // Thêm conversationId vào đây
    );

    // Debug log chi tiết message object
    print('Message object: ${message.toMap()}');

    // Gửi tin nhắn thông qua ChatBloc
    context.read<ChatBloc>().add(SendMessageEvent(message));

    // Xóa text trong input và cuộn xuống cuối
    _messageController.clear();
    _scrollToBottom();
  }

  void _handleVoiceMessage(File audioFile) async {
    setState(() {
      _isSendingVoiceMessage = true;
      _isShowingVoiceRecorder = false;
    });

    try {
      print('Sending voice message to $_receiverId');

      // Option 1: Gửi trực tiếp file path
      final String filePath = audioFile.path;

      // Option 2: Chuyển đổi file thành base64 nếu cần
      // final bytes = await audioFile.readAsBytes();
      // final base64Audio = base64Encode(bytes);
      // final filePath = "base64audio:$base64Audio";

      // Đo thời lượng của file âm thanh hoặc lấy từ recorder
      final int durationInSeconds = 5; // Thay bằng thời lượng thực tế

      context.read<ChatBloc>().add(
            SendVoiceMessageEvent(
              conversationId: widget.conversationId,
              senderId: widget.currentUserId,
              receiverId: _receiverId,
              filePath: filePath,
              duration: durationInSeconds,
            ),
          );
    } catch (e) {
      print('Error sending voice message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending voice message: $e')),
      );
    } finally {
      setState(() {
        _isSendingVoiceMessage = false;
      });
    }
  }

  void _toggleVoiceRecorder() {
    setState(() {
      _isShowingVoiceRecorder = !_isShowingVoiceRecorder;
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.friend != null
            ? Text(widget.friend!.name)
            : Text('Chat $_receiverId'),
        elevation: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocConsumer<ChatBloc, ChatState>(
                listener: (context, state) {
                  if (state is ChatError) {
                    print('Chat error: ${state.message}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  } else if (state is ChatMessageSent) {
                    print('Message sent successfully, reloading messages');
                    context.read<ChatBloc>().add(
                          LoadMessagesEvent(widget.conversationId),
                        );
                  } else if (state is ChatMessagesLoaded) {
                    // Cuộn xuống dưới khi tin nhắn được tải
                    _scrollToBottom();

                    // Đánh dấu đã đọc khi nhận tin nhắn mới
                    context.read<ChatBloc>().add(
                          MarkConversationReadEvent(widget.conversationId),
                        );
                  }
                },
                builder: (context, state) {
                  if (state is ChatLoading || _isSendingVoiceMessage) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ChatMessagesLoaded) {
                    // Debug logs để kiểm tra tin nhắn đã tải
                    print('Loaded ${state.messages.length} messages');
                    for (var msg in state.messages) {
                      print(
                          'Message: type=${msg.type}, content=${msg.content}, id=${msg.id}');
                    }

                    return state.messages.isEmpty
                        ? const Center(
                            child:
                                Text('No messages yet. Start a conversation!'),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.all(8.0),
                            itemCount: state.messages.length,
                            itemBuilder: (context, index) {
                              final message = state.messages[index];
                              final isCurrentUser =
                                  message.senderId == widget.currentUserId;

                              return MessageBubble(
                                message: message,
                                isMe: isCurrentUser,
                              );
                            },
                          );
                  }

                  return const Center(
                    child: Text('Loading messages...'),
                  );
                },
              ),
            ),
            if (_isShowingVoiceRecorder)
              VoiceMessageRecorder(
                onStop: _handleVoiceMessage,
                onCancel: () => setState(() => _isShowingVoiceRecorder = false),
              ),
            if (!_isShowingVoiceRecorder) _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: const Offset(0, -1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: _toggleVoiceRecorder,
            tooltip: 'Record voice message',
            color: Theme.of(context).primaryColor,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }
}
