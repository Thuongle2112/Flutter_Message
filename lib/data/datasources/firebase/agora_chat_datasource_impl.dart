import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:agora_chat_sdk/agora_chat_sdk.dart';
import 'package:path_provider/path_provider.dart';
import '../../../config/agora_config.dart';
import '../../services/agora_chat_rest_service.dart';
import 'agora_chat_datasource.dart';

class AgoraChatDataSourceImpl implements AgoraChatDataSource {
  final String appKey;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  String? _currentUserId;
  bool _isInitialized = false;

  final AgoraChatRESTService restService;

  AgoraChatDataSourceImpl({
    required this.appKey,
    required this.restService,
  });

  @override
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get isLoggedIn => _currentUserId != null;

  @override
  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        return;
      }

      // Khởi tạo Agora Chat SDK với các tùy chọn cần thiết
      ChatOptions options = ChatOptions(
        appKey: appKey,
        autoLogin: false,
        debugMode: true, // Đặt là false trong môi trường sản xuất
      );

      await ChatClient.getInstance.init(options);
      _setupEventHandlers();
      _isInitialized = true;
      print('[AGORA_CHAT] Initialized successfully');
    } catch (e) {
      print('[AGORA_CHAT] Error initializing: $e');
      _isInitialized = false;
      throw Exception('Failed to initialize Agora Chat SDK: $e');
    }
  }

  @override
  Future<void> login(String userId, String? token) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Nếu đã đăng nhập với cùng userId, không cần đăng nhập lại
      if (_currentUserId == userId) {
        print('[AGORA_CHAT] Already logged in as $userId');
        return;
      }

      // Kiểm tra trạng thái đăng nhập hiện tại và logout nếu cần
      try {
        if (_currentUserId != null) {
          print('[AGORA_CHAT] Another user is logged in, logging out...');
          await ChatClient.getInstance.logout();
          _currentUserId = null;
        }
      } catch (e) {
        print('[AGORA_CHAT] Error during logout check: $e');
      }

      print('[AGORA_CHAT] Attempting to login as $userId');

      // Thử đăng nhập
      try {
        if (token != null && token.isNotEmpty) {
          await ChatClient.getInstance.loginWithAgoraToken(userId, token);
          _currentUserId = userId;
          print('[AGORA_CHAT] Logged in successfully with provided token');
          return;
        } else {
          await ChatClient.getInstance.login(userId, userId);
          _currentUserId = userId;
          print(
              '[AGORA_CHAT] Logged in successfully with simple authentication');
          return;
        }
      } catch (e) {
        // Kiểm tra lỗi "user does not exist"
        if (e.toString().contains('User does not exist') ||
            e.toString().contains('code: 204')) {
          print('[AGORA_CHAT] User does not exist. Attempting to register...');

          // Đăng ký người dùng mới
          bool registrationSuccess = await registerUser(userId);

          if (!registrationSuccess) {
            throw Exception('Failed to register new user: $userId');
          }

          print(
              '[AGORA_CHAT] User registered successfully. Attempting login again...');

          // Thử đăng nhập lại sau khi đăng ký
          if (token != null && token.isNotEmpty) {
            await ChatClient.getInstance.loginWithAgoraToken(userId, token);
          } else {
            await ChatClient.getInstance.login(userId, userId);
          }

          _currentUserId = userId;
          print('[AGORA_CHAT] Successfully logged in after registration');
          return;
        } else if (e.toString().contains('already logged in')) {
          _currentUserId = userId;
          print('[AGORA_CHAT] User already logged in');
          return;
        } else {
          print('[AGORA_CHAT] Login failed: $e');
          throw e;
        }
      }
    } catch (e) {
      print('[AGORA_CHAT] Error logging in: $e');
      throw Exception('Failed to login to Agora Chat: $e');
    }
  }

  Future<bool> registerUser(String userId) async {
    try {
      return await restService.registerUser(userId);
    } catch (e) {
      print('[AGORA_CHAT] Error registering user: $e');
      return false;
    }
  }

  @override
  Future<void> logout() async {
    try {
      if (!_isInitialized || _currentUserId == null) {
        return;
      }

      await ChatClient.getInstance.logout(true);
      _currentUserId = null;
      print('[AGORA_CHAT] Logged out successfully');
    } catch (e) {
      print('[AGORA_CHAT] Error logging out: $e');
      throw Exception('Failed to logout from Agora Chat: $e');
    }
  }

  @override
  Future<String?> getCurrentUserId() async {
    return _currentUserId;
  }

  @override
  Future<void> sendMessage(String peerId, String content,
      {String? conversationId}) async {
    if (_currentUserId == null) {
      throw Exception('Agora Chat not logged in');
    }

    try {
      final String actualConversationId = conversationId ??
          AgoraConfig.getConversationId(_currentUserId!, peerId);

      // Mã hóa nội dung đặc biệt nếu cần
      // Đảm bảo content chỉ chứa văn bản thuần túy
      String safeContent = content;

      print('[AGORA_CHAT] Preparing text message: $safeContent');

      // Tạo metadata cho tin nhắn
      final Map<String, dynamic> messageData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'content': safeContent,
        'type': 'text', // Đánh dấu rõ ràng là text
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'senderId': _currentUserId,
        'receiverId': peerId,
        'isRead': false,
        'conversationId': actualConversationId,
      };

      // Tạo tin nhắn văn bản
      ChatMessage message = ChatMessage.createTxtSendMessage(
        targetId: peerId,
        content: safeContent,
      );

      // Thêm metadata vào thuộc tính attributes
      message.attributes = messageData;

      // Gửi tin nhắn
      await ChatClient.getInstance.chatManager.sendMessage(message);

      // Thêm vào stream để cập nhật UI ngay lập tức
      _messageController.add(messageData);

      print('[AGORA_CHAT] Text message sent to $peerId: $safeContent');
    } catch (e) {
      print('[AGORA_CHAT] Error sending text message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  @override
  Future<void> sendVoiceMessage(String peerId, String filePath, int duration,
      {String? conversationId}) async {
    if (_currentUserId == null) {
      throw Exception('Agora Chat not logged in');
    }

    try {
      final String actualConversationId = conversationId ??
          AgoraConfig.getConversationId(_currentUserId!, peerId);

      print('[AGORA_CHAT] Sending voice message, duration: $duration');

      // Kiểm tra nếu là dữ liệu base64
      bool isBase64Data = filePath.startsWith('base64audio:');
      String actualFilePath = filePath;

      // Nếu là dữ liệu base64, lưu vào file tạm thời
      if (isBase64Data) {
        try {
          // Trích xuất chuỗi base64
          String base64Data = filePath.substring('base64audio:'.length);

          // Tạo file tạm
          final tempDir = await getTemporaryDirectory();
          final tempFilePath = '${tempDir.path}/temp_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

          // Giải mã và lưu vào file tạm
          final bytes = base64Decode(base64Data);
          await File(tempFilePath).writeAsBytes(bytes);

          // Cập nhật đường dẫn file
          actualFilePath = tempFilePath;
          print('[AGORA_CHAT] Created temporary file from base64 data: $tempFilePath');
        } catch (e) {
          print('[AGORA_CHAT] Error processing base64 audio: $e');
          throw Exception('Failed to process base64 audio data: $e');
        }
      }
      // Kiểm tra file tồn tại
      else {
        final file = File(actualFilePath);
        if (!await file.exists()) {
          throw Exception('Voice file does not exist: $actualFilePath');
        }
      }

      // Tạo metadata cho tin nhắn
      final Map<String, dynamic> messageData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'content': actualFilePath, // Đường dẫn tới file âm thanh
        'type': 'voice', // Đánh dấu rõ ràng là voice
        'duration': duration,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'senderId': _currentUserId,
        'receiverId': peerId,
        'isRead': false,
        'conversationId': actualConversationId,
      };

      // Tạo tin nhắn voice
      ChatMessage message = ChatMessage.createVoiceSendMessage(
        targetId: peerId,
        filePath: actualFilePath,
        duration: duration,
      );

      // Thêm metadata vào thuộc tính attributes
      message.attributes = messageData;

      // Gửi tin nhắn
      await ChatClient.getInstance.chatManager.sendMessage(message);

      // Thêm vào stream để cập nhật UI ngay lập tức
      _messageController.add(messageData);

      print('[AGORA_CHAT] Voice message sent to $peerId, duration: ${duration}ms');

      // Xóa file tạm nếu cần
      if (isBase64Data) {
        try {
          await File(actualFilePath).delete();
          print('[AGORA_CHAT] Deleted temporary voice file');
        } catch (e) {
          print('[AGORA_CHAT] Warning: Could not delete temporary file: $e');
        }
      }
    } catch (e) {
      print('[AGORA_CHAT] Error sending voice message: $e');
      throw Exception('Failed to send voice message: $e');
    }
  }

  @override
  Future<void> markConversationRead(String conversationId) async {
    if (_currentUserId == null) {
      throw Exception('Agora Chat not logged in');
    }

    try {
      // Parse conversationId để lấy peer ID
      final parts = conversationId.split(':');
      if (parts.length != 2) {
        throw FormatException('Invalid conversation ID format');
      }

      // Xác định ID của người nhận
      final peerId = parts[0] == _currentUserId ? parts[1] : parts[0];

      // Tạo metadata cho tin nhắn read receipt
      final Map<String, dynamic> readReceiptData = {
        'id': 'receipt_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'read_receipt',
        'conversationId': conversationId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'senderId': _currentUserId,
        'receiverId': peerId,
        'isRead': true,
        'content': 'read_receipt',
      };

      // Đánh dấu cuộc trò chuyện là đã đọc
      try {
        final conversation =
            await ChatClient.getInstance.chatManager.getConversation(
          peerId,
          type: ChatConversationType.Chat,
          createIfNeed: true,
        );

        if (conversation != null) {
          await conversation.markAllMessagesAsRead();
          print('[AGORA_CHAT] Marked all messages as read in conversation');

          // Thêm vào stream để cập nhật UI ngay lập tức
          _messageController.add(readReceiptData);
        }
      } catch (e) {
        print('[AGORA_CHAT] Warning: Could not mark conversation as read: $e');
      }

      print('[AGORA_CHAT] Marked conversation $conversationId as read');
    } catch (e) {
      print('[AGORA_CHAT] Error marking conversation as read: $e');
      throw Exception('Failed to mark conversation as read: $e');
    }
  }

  @override
  Future<String> startChat(String userId) async {
    // Đơn giản chỉ tạo conversationId
    final conversationId =
        AgoraConfig.getConversationId(_currentUserId!, userId);
    return conversationId;
  }

  @override
  Stream<List<Map<String, dynamic>>> getConversations() async* {
    if (_currentUserId == null) {
      throw Exception('Agora Chat not logged in');
    }

    try {
      // Lấy danh sách cuộc trò chuyện từ SDK
      final conversations =
          await ChatClient.getInstance.chatManager.loadAllConversations();
      print('[AGORA_CHAT] Loaded ${conversations.length} conversations');

      final List<Map<String, dynamic>> result = [];

      for (var conversation in conversations) {
        final convId = conversation.id;
        final convType = conversation.type;
        final unreadCount = conversation.unreadCount;

        // Xác định người tham gia trong cuộc trò chuyện
        List<String> participants = [];
        if (convType == ChatConversationType.Chat) {
          // 1-1 chat
          final peerId = convId;
          participants = [_currentUserId!, peerId];
        }

        // Lấy tin nhắn cuối cùng
        // Sửa lỗi: conversation.latestMessage có thể trả về Future<ChatMessage?>
        ChatMessage? lastMsg;
        try {
          // Cần phải đợi nếu latestMessage là một Future
          dynamic latestMsg = conversation.latestMessage;
          if (latestMsg is Future) {
            lastMsg = await latestMsg;
          } else {
            lastMsg = latestMsg;
          }
        } catch (e) {
          print('[AGORA_CHAT] Error getting latest message: $e');
          lastMsg = null;
        }

        Map<String, dynamic>? lastMsgData;

        if (lastMsg != null) {
          lastMsgData = _formatMessage(lastMsg);
        } else {
          // Tạo một tin nhắn trống nếu không có tin nhắn cuối cùng
          lastMsgData = {
            'id': '',
            'content': '',
            'type': 'text',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'senderId': '',
            'receiverId': '',
            'isRead': true,
            'conversationId': convId,
          };
        }

        // Tạo dữ liệu cuộc trò chuyện
        final Map<String, dynamic> convData = {
          'id': convId,
          'participants': participants,
          'unreadCount': unreadCount,
          'timestamp':
              lastMsgData['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
          'lastMessage': lastMsgData,
          'messages': [], // Khởi tạo danh sách tin nhắn rỗng
        };

        // Tải các tin nhắn cho cuộc trò chuyện này
        try {
          final messages = await conversation.loadMessages(
            startMsgId: '',
            loadCount: 20,
          );

          final List<Map<String, dynamic>> msgList = [];
          for (var msg in messages) {
            msgList.add(_formatMessage(msg));
          }

          // Sắp xếp theo thời gian
          msgList.sort(
              (a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));

          // Gắn danh sách tin nhắn vào cuộc trò chuyện
          convData['messages'] = msgList;

          print(
              '[AGORA_CHAT] Loaded ${msgList.length} messages for conversation $convId');
        } catch (e) {
          print(
              '[AGORA_CHAT] Error loading messages for conversation $convId: $e');
          convData['messages'] = [];
        }

        result.add(convData);
      }

      // Sắp xếp cuộc trò chuyện theo thời gian tin nhắn cuối cùng (mới nhất lên đầu)
      result
          .sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

      yield result;
    } catch (e) {
      print('[AGORA_CHAT] Error getting conversations: $e');
      yield [];
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getMessages(String conversationId,
      {int limit = 20}) async* {
    if (_currentUserId == null) {
      throw Exception('Agora Chat not logged in');
    }

    try {
      // Xác định peerId từ conversationId
      final parts = conversationId.split(':');
      if (parts.length != 2) {
        throw FormatException('Invalid conversation ID format');
      }

      final peerId = parts[0] == _currentUserId ? parts[1] : parts[0];

      // Lấy cuộc trò chuyện
      final conversation =
          await ChatClient.getInstance.chatManager.getConversation(
        peerId,
        type: ChatConversationType.Chat,
        createIfNeed: true,
      );

      if (conversation == null) {
        yield [];
        return;
      }

      // Lấy tin nhắn từ cuộc trò chuyện
      final messages = await conversation.loadMessages(
        startMsgId: '',
        loadCount: limit,
      );

      final List<Map<String, dynamic>> result = [];

      // Format tin nhắn
      for (var msg in messages) {
        result.add(_formatMessage(msg));
      }

      // Sắp xếp theo thời gian
      result
          .sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));

      print(
          '[AGORA_CHAT] Retrieved ${result.length} messages for conversation $conversationId');

      // Trả về một lần từ lịch sử tin nhắn
      yield result;

      // Tạo một list mới để lưu tất cả tin nhắn (cả cũ và mới)
      final allMessages = List<Map<String, dynamic>>.from(result);

      // Tiếp tục lắng nghe tin nhắn mới
      await for (final msgData in _messageController.stream) {
        if (msgData['conversationId'] == conversationId) {
          // Kiểm tra tin nhắn đã tồn tại chưa để tránh trùng lặp
          final existingIndex =
              allMessages.indexWhere((m) => m['id'] == msgData['id']);

          if (existingIndex >= 0) {
            // Cập nhật tin nhắn hiện có
            allMessages[existingIndex] = msgData;
          } else {
            // Thêm tin nhắn mới
            allMessages.add(msgData);
          }

          // Sắp xếp lại theo thời gian
          allMessages.sort(
              (a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));

          // Trả về danh sách tin nhắn cập nhật
          yield List<Map<String, dynamic>>.from(allMessages);
        }
      }
    } catch (e) {
      print('[AGORA_CHAT] Error getting messages: $e');
      yield [];
    }
  }

  void _setupEventHandlers() {
    // Đăng ký lắng nghe tin nhắn
    ChatClient.getInstance.chatManager.addEventHandler(
      "message_handler_key",
      ChatEventHandler(
        onMessagesReceived: (messages) {
          print('[AGORA_CHAT] Received ${messages.length} new messages');
          for (var message in messages) {
            _processReceivedMessage(message);
          }
        },
        onCmdMessagesReceived: (messages) {
          print('[AGORA_CHAT] Received command messages');
        },
        onMessagesRead: (messages) {
          print('[AGORA_CHAT] Messages read notification received');
          for (var message in messages) {
            // Xử lý tin nhắn đọc nếu cần
            _handleMessageRead(message);
          }
        },
        onMessagesDelivered: (messages) {
          print('[AGORA_CHAT] Messages delivered notification received');
        },
        onMessagesRecalled: (messages) {
          print('[AGORA_CHAT] Messages recalled notification received');
        },
      ),
    );

    // Thiết lập ConnectionListener
    ChatClient.getInstance.addConnectionEventHandler(
      "connection_handler",
      ConnectionEventHandler(
        onConnected: () {
          print('[AGORA_CHAT] Connected to server');
        },
        onDisconnected: () {
          print('[AGORA_CHAT] Disconnected from server');
        },
        onTokenWillExpire: () {
          print('[AGORA_CHAT] Token will expire soon');
          // Triển khai logic gia hạn token nếu cần
        },
        onTokenDidExpire: () {
          print('[AGORA_CHAT] Token has expired');
          // Triển khai logic gia hạn token nếu cần
        },
      ),
    );
  }

  void _processReceivedMessage(ChatMessage message) {
    try {
      // Format tin nhắn
      final formattedMessage = _formatMessage(message);

      // Kiểm tra loại tin nhắn để debug
      print('[AGORA_CHAT] Received message type: ${formattedMessage['type']}');
      if (formattedMessage['type'] == 'text') {
        print('[AGORA_CHAT] Text content: ${formattedMessage['content']}');
      } else if (formattedMessage['type'] == 'voice') {
        print(
            '[AGORA_CHAT] Voice message duration: ${formattedMessage['duration']}');
      }

      // Gửi tin nhắn đến stream
      _messageController.add(formattedMessage);
    } catch (e) {
      print('[AGORA_CHAT] Error processing received message: $e');
    }
  }

  void _handleMessageRead(ChatMessage message) {
    try {
      // Tạo map chứa thông tin tin nhắn đã đọc
      final readReceiptData = {
        'id': 'receipt_${message.msgId}',
        'type': 'read_receipt',
        'conversationId': message.conversationId ?? message.to,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'senderId': message.from,
        'receiverId': message.to,
        'isRead': true,
        'content': 'read_receipt',
        'relatedMessageId': message.msgId,
      };

      // Gửi tin nhắn đến stream
      _messageController.add(readReceiptData);

      print('[AGORA_CHAT] Message read receipt processed');
    } catch (e) {
      print('[AGORA_CHAT] Error processing read receipt: $e');
    }
  }

  // Format message từ ChatMessage thành Map
  Map<String, dynamic> _formatMessage(ChatMessage message) {
    String type = 'unknown';
    String content = '';
    int? duration;

    // Xử lý dựa vào loại tin nhắn
    try {
      // Sử dụng MessageType thay vì ChatMessageBodyType
      if (message.body.type == MessageType.TXT) {
        // Text message
        type = 'text';

        // Trực tiếp lấy nội dung từ TextMessageBody
        try {
          // Ép kiểu trực tiếp sử dụng ChatMessage API
          final textBody = message.body as ChatTextMessageBody;
          content = textBody.content;
        } catch (e) {
          print('[AGORA_CHAT] Error extracting text content: $e');
          // Fallback method nếu không thể ép kiểu
          content = message.body.toString();
        }
      } else if (message.body.type == MessageType.VOICE) {
        // Voice message
        type = 'voice';

        try {
          // Ép kiểu trực tiếp sử dụng ChatMessage API
          final voiceBody = message.body as ChatVoiceMessageBody;
          content = voiceBody.remotePath ?? voiceBody.localPath ?? '';
          duration = voiceBody.duration;
        } catch (e) {
          print('[AGORA_CHAT] Error extracting voice data: $e');
          content = '';
          duration = 0;
        }
      } else if (message.body.type == MessageType.IMAGE) {
        // Image message
        type = 'image';

        try {
          // Ép kiểu trực tiếp sử dụng ChatMessage API
          final imageBody = message.body as ChatImageMessageBody;
          content = imageBody.remotePath ?? imageBody.localPath ?? '';
        } catch (e) {
          print('[AGORA_CHAT] Error extracting image path: $e');
          content = '';
        }
      } else if (message.body.type == MessageType.CUSTOM) {
        // Custom message
        type = 'custom';
        content = 'custom_message';

        try {
          // Ép kiểu trực tiếp sử dụng ChatMessage API
          final customBody = message.body as ChatCustomMessageBody;
          String event = customBody.event;

          if (event == 'voice_message') {
            type = 'voice';
            content = customBody.params?['content'] ?? '';
            String durationStr = customBody.params?['duration'] ?? '0';
            duration = int.tryParse(durationStr);
          } else if (event == 'read_receipt') {
            type = 'read_receipt';
            content = 'read_receipt';
          }
        } catch (e) {
          print('[AGORA_CHAT] Error extracting custom message data: $e');
        }
      } else {
        // Default for other types
        type = 'text';
        content = 'Unsupported message type';
        print('[AGORA_CHAT] Unsupported message type: ${message.body.type}');
      }
    } catch (e) {
      print('[AGORA_CHAT] Error detecting message type: $e');
      type = 'text';
      content = 'Error processing message';
    }

    // Tiếp tục mã hiện có...
    final Map<String, dynamic> messageData = {
      'id': message.msgId,
      'conversationId': message.conversationId ?? message.to,
      'senderId': message.from,
      'receiverId': message.to,
      'timestamp': message.serverTime,
      'isRead': message.hasRead,
      'type': type,
      'content': content,
    };

    // Thêm duration cho voice messages
    if (duration != null) {
      messageData['duration'] = duration;
    }

    // Thêm các thuộc tính tùy chỉnh từ attributes nếu có
    if (message.attributes != null && message.attributes is Map) {
      // Lưu type đã xác định từ body
      final String messageType = messageData['type'];

      // Merge với attributes
      messageData.addAll(Map<String, dynamic>.from(message.attributes!));

      // Đảm bảo giữ type đã xác định từ body
      messageData['type'] = messageType;
    }

    return messageData;
  }
}
