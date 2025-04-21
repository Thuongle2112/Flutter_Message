import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../config/agora_config.dart';

class AgoraChatRESTService {
  static const String _baseUrl = 'https://a61.chat.agora.io';
  static const String _orgName = '611299512';
  static const String _appName = '1497260';
  final String? _accessToken =
      "007eJxTYJBOm7vzR3dk7i/Je9azM7w7+urKhWIuBrd38zZfylJ59FWBITnN0tLc3NTcMC052cQg2STRMMUoydgw1TTRwNAwxdRA7DRjRkMgI8M1MS0WRgZWBkYGJgYQn4EBAJwrHRM=";

  // Lấy App Token từ Agora Console
  // Future<void> getAppToken() async {
  //   try {
  //     // Lấy Client ID và Client Secret từ cấu hình
  //     const clientId = AgoraConfig.clientId;
  //     const clientSecret = AgoraConfig.clientSecret;
  //
  //     print('Attempting to get App Token with clientId: $clientId');
  //
  //     final url = Uri.parse('$_baseUrl/$_orgName/$_appName/token');
  //
  //     final response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({
  //         'grant_type': 'client_credentials',
  //         'client_id': clientId,
  //         'client_secret': clientSecret
  //       }),
  //     );
  //
  //     print('Token request response status: ${response.statusCode}');
  //
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       _accessToken = data['access_token'];
  //       print('Successfully obtained App Token');
  //     } else {
  //       print(
  //           'Failed to get App Token: ${response.statusCode}, ${response.body}');
  //       throw Exception('Failed to get App Token');
  //     }
  //   } catch (e) {
  //     print('Error getting App Token: $e');
  //     throw Exception('Error getting App Token: $e');
  //   }
  // }

  Future<void> getAppToken() async {
    // Nếu token đã được cài đặt, không cần gọi API
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      print('Using predefined App Token');
      return;
    }

    // Nếu không có token định sẵn, bạn vẫn có thể giữ code gốc ở đây
    // để cố gắng lấy token qua API trong tương lai
    print('No predefined App Token available');
    throw Exception('App Token not configured');
  }

  // Đăng ký người dùng mới
  Future<bool> registerUser(String userId,
      {String? password, String? nickname}) async {
    if (_accessToken == null) {
      await getAppToken();
    }

    try {
      final url = Uri.parse('$_baseUrl/$_orgName/$_appName/users');
      final actualPassword =
          password ?? userId; // Sử dụng userId làm mật khẩu nếu không cung cấp

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken'
        },
        body: jsonEncode({
          'username': userId,
          'password': actualPassword,
          if (nickname != null) 'nickname': nickname
        }),
      );

      if (response.statusCode == 200) {
        print('User registered successfully: $userId');
        return true;
      } else if (response.statusCode == 400 &&
          response.body.contains('duplicate_unique_property_exists')) {
        print('User already exists: $userId');
        return true; // Trả về true nếu người dùng đã tồn tại
      } else {
        print(
            'Failed to register user. Status: ${response.statusCode}, Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  // Lấy User Token (Có thể sử dụng để đăng nhập)
  Future<String?> getUserToken(String userId) async {
    if (_accessToken == null) {
      await getAppToken();
    }

    try {
      final url =
          Uri.parse('$_baseUrl/$_orgName/$_appName/users/$userId/user_token');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken'
        },
        body: jsonEncode({
          'ttl': 2592000, // Token hợp lệ trong 30 ngày (tính bằng giây)
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        print('Successfully obtained User Token for $userId');
        return token;
      } else {
        print(
            'Failed to get User Token: ${response.statusCode}, ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting User Token: $e');
      return null;
    }
  }

  // Kiểm tra người dùng có tồn tại không
  Future<bool> checkUserExists(String userId) async {
    if (_accessToken == null) {
      await getAppToken();
    }

    try {
      final url = Uri.parse('$_baseUrl/$_orgName/$_appName/users/$userId');

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  // Xóa người dùng
  Future<bool> deleteUser(String userId) async {
    if (_accessToken == null) {
      await getAppToken();
    }

    try {
      final url = Uri.parse('$_baseUrl/$_orgName/$_appName/users/$userId');

      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Gửi tin nhắn từ server thông qua REST API
  Future<bool> sendMessage({
    required String from,
    required String to,
    required String content,
    String msgType = 'txt',
  }) async {
    if (_accessToken == null) {
      await getAppToken();
    }

    try {
      final url = Uri.parse('$_baseUrl/$_orgName/$_appName/messages');

      Map<String, dynamic> msgBody;
      if (msgType == 'txt') {
        msgBody = {
          'msg': content,
        };
      } else if (msgType == 'custom') {
        msgBody = {
          'customEvent': 'voice_message',
          'customParams': {
            'content': content,
            // Thêm các tham số khác nếu cần
          }
        };
      } else {
        throw Exception('Unsupported message type: $msgType');
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken'
        },
        body: jsonEncode({
          'from': from,
          'target_type': 'users',
          'target': [to],
          'type': msgType,
          'body': msgBody,
        }),
      );

      if (response.statusCode == 200) {
        print('Message sent successfully from $from to $to');
        return true;
      } else {
        print(
            'Failed to send message. Status: ${response.statusCode}, Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }
}
