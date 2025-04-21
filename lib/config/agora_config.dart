class AgoraConfig {
  // Thông tin từ Agora Console của bạn
  static const String appKey = "611299512#1497260";
  static const String orgName = "611299512";
  static const String appName = "1497260";
  static const String restApiUrl = "a61.chat.agora.io";

  // Client credentials - Lấy từ Agora Console
  static const String clientId = "cf9977571fcc40c4a1d2b31e5a011d50";
  static const String clientSecret = "44f0486ae83841f788ecd9e915549973";

  // Các phương thức tiện ích
  static String getConversationId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}:${sortedIds[1]}';
  }

  static String getReceiverIdFromConversation(
      String conversationId, String currentUserId) {
    final parts = conversationId.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid conversation ID format');
    }
    return parts[0] == currentUserId ? parts[1] : parts[0];
  }
}
