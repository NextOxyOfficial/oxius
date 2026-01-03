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
            iconPath: post.isLiked ? 'assets/icons/like.png' : 'assets/icons/unlike.png',
            label: _formatCount(post.likesCount),
            onTap: onLike,
          ),
          const SizedBox(width: 16),
          // Comment Button
          _ActionButton(
            iconPath: 'assets/icons/comments.png',
            label: _formatCount(post.commentsCount),
            onTap: onComment,
          ),
          const SizedBox(width: 16),
          // Share Button
          _ActionButton(
            iconPath: 'assets/icons/share.png',
            label: 'Share',
            onTap: onShare,
          ),
          const Spacer(),
          // Save Button
          if (onSave != null)
            InkWell(
              onTap: onSave,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  post.isSaved ? 'assets/icons/saved.png' : 'assets/icons/save.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                ),
              ),
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
  final String iconPath;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.iconPath,
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
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Image.asset(
                iconPath,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
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
