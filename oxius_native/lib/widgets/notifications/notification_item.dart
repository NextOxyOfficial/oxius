import 'package:flutter/material.dart';
import '../../models/notification_models.dart';
import '../../utils/time_utils.dart';
import '../../utils/html_content_utils.dart';
import '../app_network_image.dart';

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
        // Unread rows carry a wash of blue; read rows are plain. That is the
        // whole separator system — the hairline under every row made a list of
        // faces look like a spreadsheet.
        color: notification.read ? Colors.white : const Color(0xFFEBF3FF),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                            ? AppNetworkImage(
                                notification.actor!.image!,
                                fit: BoxFit.cover,
                                width: 52,
                                height: 52,
                                errorWidget: _buildAvatarFallback(),
                              )
                            : _buildAvatarFallback(),
                      ),
                    ),

                    // Type icon badge
                    Positioned(
                      bottom: -1,
                      right: -1,
                      child: Container(
                        padding: const EdgeInsets.all(4.5),
                        decoration: BoxDecoration(
                          color: _getTypeColor(),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
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
                            fontSize: 15,
                            color: Colors.grey.shade800,
                            height: 1.35,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.3,
                          ),
                          children: [
                            TextSpan(
                              text: actorDisplayName,
                              style: TextStyle(
                                fontWeight: notification.read
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                                color: const Color(0xFF050505),
                              ),
                            ),
                            TextSpan(
                              text: ' ${_getNotificationText()}',
                            ),
                          ],
                        ),
                      ),
                      // Only show the body when it ADDS something. For a like
                      // the API sends "Liked your post", which is what the
                      // sentence above already says — so the row read
                      // "Anisur Rahman liked your post / Liked your post".
                      // A comment's body is the comment itself and does earn
                      // its line.
                      if (_hasDistinctBody())
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            HtmlContentUtils.toPlainText(
                                notification.content!),
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.25,
                              color: Colors.grey.shade700,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 3),
                      Text(
                        _shortTimeAgo(),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          // Unread timestamps take the accent, which is how
                          // Facebook marks recency without another badge.
                          color: notification.read
                              ? Colors.grey.shade500
                              : const Color(0xFF1877F2),
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

  /// True when [notification.content] says something the headline does not.
  bool _hasDistinctBody() {
    final body = (notification.content ?? '').trim();
    if (body.isEmpty) return false;
    final plain = HtmlContentUtils.toPlainText(body).trim();
    if (plain.isEmpty) return false;
    final headline = _getNotificationText().trim();
    // Compare loosely: the API's casing and trailing punctuation vary.
    String norm(String s) => s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9ঀ-৿ ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final a = norm(plain);
    final b = norm(headline);
    if (a.isEmpty) return false;
    return a != b && !b.contains(a) && !a.contains(b);
  }

  /// "8h", "3d", "2w" — the long form ("8 Hours") pushed the row taller than
  /// it needed to be and read as a sentence rather than a timestamp.
  String _shortTimeAgo() {
    final long = TimeUtils.formatTimeAgo(notification.createdAt);
    final m = RegExp(r'^(\d+)\s*(\w)', caseSensitive: false).firstMatch(long);
    if (m == null) return long;
    final n = m.group(1)!;
    switch (m.group(2)!.toLowerCase()) {
      case 'y':
        return '${n}y';
      case 'm':
        // Month vs Minute both start with M — disambiguate on the full word.
        return long.toLowerCase().contains('mo') ? '${n}mo' : '${n}m';
      case 'w':
        return '${n}w';
      case 'd':
        return '${n}d';
      case 'h':
        return '${n}h';
      case 's':
        return '${n}s';
      default:
        return long;
    }
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Text(
          _getInitials(),
          style: TextStyle(
            color: Colors.grey.shade800,
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

    final parts =
        name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();

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
      case NotificationType.share:
        return const Color(0xFF10B981); // Emerald
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
      case NotificationType.share:
        return Icons.repeat_rounded;
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
      case NotificationType.share:
        return 'আপনার পোস্ট শেয়ার করেছেন';
      default:
        return 'interacted with your content';
    }
  }
}
