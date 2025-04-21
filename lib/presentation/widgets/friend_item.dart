import 'dart:convert';
import 'package:flutter/material.dart';
import '../../domain/entities/app_user.dart';

class FriendItem extends StatelessWidget {
  final AppUser user;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FriendItem({
    Key? key,
    required this.user,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildAvatar(),
      title: Text(user.name),
      subtitle: Text(user.email),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.grey[200],
      backgroundImage: _getAvatarImage(),
      child: _shouldShowInitial()
          ? Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      )
          : null,
    );
  }

  // Phương thức để lấy ImageProvider phù hợp
  ImageProvider? _getAvatarImage() {
    if (user.photoUrl == null || user.photoUrl!.isEmpty) {
      return null;
    }

    // Trường hợp ảnh là base64
    if (user.photoUrl!.startsWith('data:image')) {
      try {
        // Trích xuất phần base64 từ data URI
        final base64String = user.photoUrl!.split(',')[1];
        // Decode và hiển thị
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        print('Error displaying base64 image for user ${user.id}: $e');
        return null;
      }
    }
    // Trường hợp là URL ảnh thông thường (http/https)
    else if (user.photoUrl!.startsWith('http')) {
      return NetworkImage(user.photoUrl!);
    }

    return null;
  }

  // Phương thức để quyết định có hiển thị chữ cái đầu hay không
  bool _shouldShowInitial() {
    if (user.photoUrl == null || user.photoUrl!.isEmpty) {
      return true;
    }

    // Nếu là base64 nhưng xảy ra lỗi khi hiển thị
    if (user.photoUrl!.startsWith('data:image')) {
      try {
        final base64String = user.photoUrl!.split(',')[1];
        base64Decode(base64String); // Thử decode để kiểm tra
        return false; // Nếu không có lỗi, không hiển thị chữ cái đầu
      } catch (e) {
        return true; // Nếu có lỗi, hiển thị chữ cái đầu
      }
    }

    // Nếu là URL hình ảnh
    return false;
  }
}