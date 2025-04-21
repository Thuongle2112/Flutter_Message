import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String username;
  final double size;

  const UserAvatar({
    Key? key,
    this.photoUrl,
    required this.username,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(photoUrl!),
      );
    } else {
      // Use first letter of username for avatar
      final firstLetter = username.isNotEmpty
          ? username[0].toUpperCase()
          : '?';

      return CircleAvatar(
        radius: size / 2,
        backgroundColor: _getAvatarColor(username),
        child: Text(
          firstLetter,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  // Generate a color based on the username
  Color _getAvatarColor(String text) {
    if (text.isEmpty) return Colors.blueGrey;

    final colorIndex = text.codeUnitAt(0) % _avatarColors.length;
    return _avatarColors[colorIndex];
  }

  // List of colors for avatars
  static const List<Color> _avatarColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];
}