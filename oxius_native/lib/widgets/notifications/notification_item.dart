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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: notification.read 
              ? Colors.grey.shade200 
              : const Color(0xFF3B82F6).withOpacity(0.3),
          width: notification.read ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with icon badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: notification.read 
                              ? Colors.grey.shade200 
                              : Colors.blue.shade500,
                          width: 2,
                        ),
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
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: _getTypeColor(),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getTypeIcon(),
                      size: 12,
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
                        fontWeight: notification.read 
                            ? FontWeight.w500 
                            : FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: notification.actor?.name ?? 'Someone',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
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
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        notification.content!,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: notification.read 
                              ? Colors.grey.shade600 
                              : const Color(0xFF374151),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  
                  const SizedBox(height: 6),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        TimeUtils.formatTimeAgo(notification.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      
                      if (!notification.read) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Mark as read button
            if (!notification.read)
              Container(
                margin: const EdgeInsets.only(left: 4),
                child: IconButton(
                  onPressed: onMarkAsRead,
                  icon: const Icon(
                    Icons.check_circle_rounded,
                    size: 22,
                    color: Color(0xFF3B82F6),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: 'Mark as read',
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF3B82F6).withOpacity(0.15), const Color(0xFF6366F1).withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(),
          style: const TextStyle(
            color: Color(0xFF3B82F6),
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    final name = notification.actor?.name ?? 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
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
