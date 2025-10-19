import 'package:flutter/material.dart';
import '../../models/business_network_models.dart';
import '../../utils/time_utils.dart';

class PostCommentsPreview extends StatelessWidget {
  final BusinessNetworkPost post;
  final VoidCallback onViewAll;
  final Function(BusinessNetworkComment)? onReply;

  const PostCommentsPreview({
    super.key,
    required this.post,
    required this.onViewAll,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    if (post.comments.isEmpty) return const SizedBox.shrink();

    // Show the last 2 comments (most recent) in reverse order (newest first)
    final previewComments = post.comments.length <= 2
        ? post.comments.reversed.toList()
        : post.comments.sublist(post.comments.length - 2).reversed.toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comments
          ...previewComments.asMap().entries.map((entry) {
            final index = entry.key;
            final comment = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: index < previewComments.length - 1 ? 12 : 0),
              child: _CommentItem(
                comment: comment,
                onReply: onReply != null ? () => onReply!(comment) : null,
              ),
            );
          }),
          // View all comments button
          if (post.commentsCount > 2) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: onViewAll,
              child: Row(
                children: [
                  Text(
                    'View all ${post.commentsCount} comments',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.blue.shade700,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final BusinessNetworkComment comment;
  final VoidCallback? onReply;

  const _CommentItem({
    required this.comment,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User Avatar
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: comment.user.image != null || comment.user.avatar != null
                ? Image.network(
                    comment.user.image ?? comment.user.avatar!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade100,
                        child: Icon(
                          Icons.person,
                          color: Colors.grey.shade400,
                          size: 18,
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey.shade100,
                    child: Icon(
                      Icons.person,
                      color: Colors.grey.shade400,
                      size: 18,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        // Comment Content
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              comment.user.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (comment.user.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              size: 13,
                              color: Color(0xFF3B82F6),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeAgo(comment.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
                // Reply button
                if (onReply != null) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: onReply,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(String dateString) {
    return formatTimeAgo(dateString);
  }
}
