import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import 'user_avatar.dart';

class ConversationItem extends StatelessWidget {
  final Conversation conversation;
  final String currentUserId;
  final VoidCallback onTap;

  const ConversationItem({
    Key? key,
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the other participant
    final otherId = conversation.participants.firstWhere(
          (id) => id != currentUserId,
      orElse: () => 'Unknown',
    );

    // For simplicity, we're showing the ID as name here
    // In a real app, you would fetch the user details
    final displayName = otherId;

    return ListTile(
      leading: UserAvatar(
        photoUrl: null, // Would need to fetch from a user repository
        username: displayName,
      ),
      title: Text(
        displayName,
        style: TextStyle(
          fontWeight: conversation.unreadCount > 0
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      subtitle: _buildLastMessageText(conversation.lastMessage),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(conversation.lastMessageTime),
            style: TextStyle(
              color: conversation.unreadCount > 0
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
              fontSize: 12.0,
            ),
          ),
          const SizedBox(height: 4.0),
          if (conversation.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildLastMessageText(Message? message) {
    if (message == null) {
      return const Text('No messages yet');
    }

    if (message.type == MessageType.text) {
      return Text(
        message.content,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else if (message.type == MessageType.voice) {
      return const Row(
        children: [
          Icon(Icons.mic, size: 16),
          SizedBox(width: 4),
          Text('Voice message'),
        ],
      );
    } else if (message.type == MessageType.image) {
      return const Row(
        children: [
          Icon(Icons.image, size: 16),
          SizedBox(width: 4),
          Text('Image'),
        ],
      );
    }

    return const Text('New message');
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    if (now.difference(time).inDays > 7) {
      return '${time.day}/${time.month}/${time.year}';
    }

    return timeago.format(time, locale: 'en_short');
  }
}