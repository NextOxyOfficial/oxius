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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.read ? Colors.white : Colors.blue.shade50.withOpacity(0.3),
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with icon badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getTypeColor(),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getTypeIcon(),
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        fontWeight: notification.read 
                            ? FontWeight.normal 
                            : FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: notification.actor?.name ?? 'Someone',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
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
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        notification.content!,
                        style: TextStyle(
                          fontSize: 13,
                          color: notification.read 
                              ? Colors.grey.shade600 
                              : Colors.grey.shade800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Text(
                        TimeUtils.formatTimeAgo(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      
                      if (!notification.read) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade500,
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
              IconButton(
                onPressed: onMarkAsRead,
                icon: Icon(
                  Icons.check,
                  size: 20,
                  color: Colors.blue.shade500,
                ),
                tooltip: 'Mark as read',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade100, Colors.blue.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(),
          style: TextStyle(
            color: Colors.blue.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 18,
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
        return Colors.purple.shade500;
      case NotificationType.likePost:
      case NotificationType.likeComment:
        return Colors.red.shade500;
      case NotificationType.comment:
      case NotificationType.reply:
        return Colors.blue.shade500;
      case NotificationType.mention:
        return Colors.orange.shade500;
      case NotificationType.share:
        return Colors.green.shade500;
      default:
        return Colors.grey.shade500;
    }
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.likePost:
      case NotificationType.likeComment:
        return Icons.favorite;
      case NotificationType.comment:
      case NotificationType.reply:
        return Icons.chat_bubble;
      case NotificationType.mention:
        return Icons.alternate_email;
      case NotificationType.share:
        return Icons.share;
      default:
        return Icons.notifications;
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
        return 'mentioned you';
      case NotificationType.share:
        return 'shared your post';
      default:
        return 'interacted with you';
    }
  }
}
