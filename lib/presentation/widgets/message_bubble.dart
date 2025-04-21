import 'package:flutter/material.dart';
import '../../domain/entities/message.dart';
import 'voice_player.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String? senderName;
  final bool showAvatar;
  final String? senderAvatar;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.senderName,
    this.showAvatar = true,
    this.senderAvatar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            _buildAvatar()
          else if (!isMe)
            const SizedBox(width: 40),

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: _getBubblePadding(),
              decoration: BoxDecoration(
                color: _getBubbleColor(context),
                borderRadius: _getBubbleBorderRadius(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && senderName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        senderName!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isMe ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  _buildMessageContent(context),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      if (isMe)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 12,
                            color: message.isRead ? Colors.white70 : Colors.white54,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isMe && showAvatar)
            _buildAvatar()
          else if (isMe)
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: CircleAvatar(
        radius: 16,
        backgroundImage: senderAvatar != null ? NetworkImage(senderAvatar!) : null,
        child: senderAvatar == null
            ? senderName != null
            ? Text(
          senderName![0].toUpperCase(),
          style: const TextStyle(fontSize: 14),
        )
            : const Icon(Icons.person, size: 16)
            : null,
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.voice:
        return VoicePlayer(
          audioPath: message.content,
          isMe: isMe,
        );
      case MessageType.image:
        return _buildImageMessage();
      case MessageType.text:
      default:
        return _buildTextMessage();
    }
  }

  Widget _buildTextMessage() {
    return Text(
      message.content,
      style: TextStyle(
        color: isMe ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildImageMessage() {
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: message.content.startsWith('http')
            ? Image.network(
          message.content,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: 200,
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, size: 48);
          },
        )
            : Image.file(
          File(message.content),
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, size: 48);
          },
        ),
      );
    } catch (e) {
      return Text('Could not load image: $e');
    }
  }

  EdgeInsetsGeometry _getBubblePadding() {
    return message.type == MessageType.text
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
        : const EdgeInsets.all(8);
  }

  Color _getBubbleColor(BuildContext context) {
    return isMe
        ? Theme.of(context).primaryColor
        : Colors.grey[200]!;
  }

  BorderRadius _getBubbleBorderRadius() {
    const radius = Radius.circular(16);

    return isMe
        ? const BorderRadius.only(
      topLeft: radius,
      bottomLeft: radius,
      bottomRight: Radius.circular(4),
      topRight: radius,
    )
        : const BorderRadius.only(
      topRight: radius,
      bottomRight: radius,
      bottomLeft: Radius.circular(4),
      topLeft: radius,
    );
  }
}