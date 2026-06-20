import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../../auth/models/user_model.dart';
import '../../../shared/utils/avatar_helper.dart';

class ChatTile extends StatelessWidget {
  final Chat chat;
  final ChatUser? otherUser;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int unreadCount;

  const ChatTile({
    super.key,
    required this.chat,
    required this.otherUser,
    required this.onTap,
    this.onLongPress,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final name = chat.isGroup
        ? (chat.groupName ?? 'Group')
        : (otherUser?.name ?? 'User');
    final photo = chat.isGroup ? chat.groupPhoto : otherUser?.photoUrl;

    return GestureDetector(
      onLongPress: onLongPress,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            children: [
              if (chat.isGroup)
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      const Color(0xFFE65100).withValues(alpha: 0.2),
                  child: Icon(Icons.group_rounded,
                      color: const Color(0xFFE65100), size: 28),
                )
              else
                avatarWidget(radius: 26, photoUrl: photo, name: name),
              if (!chat.isGroup && (otherUser?.online ?? false))
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: Row(
          children: [
            if (chat.isGroup)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.group_rounded,
                    size: 16, color: Colors.grey[500]),
              ),
            Text(name,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            chat.lastMessage.isNotEmpty
                ? (chat.isGroup
                    ? chat.lastMessage
                    : (chat.lastMessageSender == otherUser?.uid
                            ? ''
                            : 'You: ') +
                        chat.lastMessage)
                : 'No messages yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: chat.lastMessage.isNotEmpty
                  ? Colors.grey[700]
                  : Colors.grey[400],
              fontStyle: chat.lastMessage.isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
              fontSize: 14,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (chat.lastMessageTime != null)
              Text(
                _formatTime(chat.lastMessageTime!),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 4),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}
