import 'package:flutter/material.dart';
import '../../models/business_network_models.dart';

class PostActions extends StatelessWidget {
  final BusinessNetworkPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback? onSave;

  const PostActions({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          // Like Button
          _ActionButton(
            icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
            iconColor: post.isLiked ? Colors.red : Colors.grey.shade600,
            label: _formatCount(post.likesCount),
            onTap: onLike,
          ),
          const SizedBox(width: 16),
          // Comment Button
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            iconColor: Colors.grey.shade600,
            label: _formatCount(post.commentsCount),
            onTap: onComment,
          ),
          const SizedBox(width: 16),
          // Share Button
          _ActionButton(
            icon: Icons.share_outlined,
            iconColor: Colors.grey.shade600,
            label: 'Share',
            onTap: onShare,
          ),
          const Spacer(),
          // Save Button
          if (onSave != null)
            IconButton(
              onPressed: onSave,
              icon: Icon(
                post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: post.isSaved ? const Color(0xFF3B82F6) : Colors.grey.shade600,
                size: 22,
              ),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
