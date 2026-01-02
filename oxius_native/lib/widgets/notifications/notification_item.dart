import 'package:flutter/material.dart';
import '../../models/notification_models.dart';
import '../../utils/time_utils.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final actorNameRaw = (notification.actor?.name ?? '').trim();
    final actorDisplayName = actorNameRaw.isNotEmpty ? actorNameRaw : 'Someone';
    return Container(
      decoration: BoxDecoration(
        color: notification.read 
            ? Colors.white 
            : const Color(0xFFEFF6FF),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade100,
            width: 0.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with icon badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: notification.actor?.image != null
                            ? Image.network(
                                notification.actor!.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildAvatarFallback();
                                },
                              )
                            : _buildAvatarFallback(),
                      ),
                    ),
                
                // Type icon badge
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(
                      _getTypeIcon(),
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 10),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        height: 1.3,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.3,
                      ),
                      children: [
                        TextSpan(
                          text: actorDisplayName,
                          style: TextStyle(
                            fontWeight: notification.read ? FontWeight.w600 : FontWeight.w700,
                            color: const Color(0xFF050505),
                          ),
                        ),
                        TextSpan(
                          text: ' ${_getNotificationText()}',
                        ),
                      ],
                    ),
                  ),
                  
                  if (notification.content != null && notification.content!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        notification.content!,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.2,
                          color: Colors.grey.shade600,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  
                  const SizedBox(height: 3),
                  
                  Text(
                    TimeUtils.formatTimeAgo(notification.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            
            // Unread indicator dot
            if (!notification.read)
              Container(
                margin: const EdgeInsets.only(left: 6),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF1877F2),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Text(
          _getInitials(),
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    final name = (notification.actor?.name ?? '').trim();
    if (name.isEmpty) return 'U';

    final parts = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color _getTypeColor() {
    switch (notification.type) {
      case NotificationType.follow:
        return const Color(0xFF3B82F6); // Blue
      case NotificationType.likePost:
      case NotificationType.likeComment:
        return const Color(0xFFEF4444); // Red
      case NotificationType.comment:
      case NotificationType.reply:
        return const Color(0xFF22C55E); // Green
      case NotificationType.mention:
        return const Color(0xFFA855F7); // Purple
      case NotificationType.solution:
        return const Color(0xFFF59E0B); // Amber
      case NotificationType.giftDiamonds:
        return const Color(0xFF14B8A6); // Teal
      default:
        return Colors.grey.shade500;
    }
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case NotificationType.follow:
        return Icons.person_add_rounded;
      case NotificationType.likePost:
      case NotificationType.likeComment:
        return Icons.favorite_rounded;
      case NotificationType.comment:
      case NotificationType.reply:
        return Icons.chat_bubble_rounded;
      case NotificationType.mention:
        return Icons.send_rounded;
      case NotificationType.solution:
        return Icons.star_rounded;
      case NotificationType.giftDiamonds:
        return Icons.card_giftcard_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _getNotificationText() {
    switch (notification.type) {
      case NotificationType.follow:
        return 'started following you';
      case NotificationType.likePost:
        return 'liked your post';
      case NotificationType.likeComment:
        return 'liked your comment';
      case NotificationType.comment:
        return 'commented on your post';
      case NotificationType.reply:
        return 'replied to your comment';
      case NotificationType.mention:
        return 'mentioned you in a post';
      case NotificationType.solution:
        return 'marked your advice as a solution';
      case NotificationType.giftDiamonds:
        return 'sent you gift diamonds';
      default:
        return 'interacted with your content';
    }
  }
}
