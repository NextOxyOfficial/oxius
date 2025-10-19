import 'package:flutter/material.dart';
import '../../models/business_network_models.dart';
import '../../utils/time_utils.dart';
import '../../screens/business_network/profile_screen.dart';

class PostCommentsPreview extends StatefulWidget {
  final BusinessNetworkPost post;
  final VoidCallback onViewAll;
  final Function(BusinessNetworkComment, String)? onReplySubmit;

  PostCommentsPreview({
    super.key,
    required this.post,
    required this.onViewAll,
    this.onReplySubmit,
  });

  @override
  State<PostCommentsPreview> createState() => _PostCommentsPreviewState();
}

class _PostCommentsPreviewState extends State<PostCommentsPreview> {
  BusinessNetworkComment? _replyingTo;

  @override
  Widget build(BuildContext context) {
    if (widget.post.comments.isEmpty) return const SizedBox.shrink();

    // Debug: Check what we're getting
    print('=== Comment Structure Debug ===');
    for (var c in widget.post.comments) {
      print('Comment ${c.id}: parentComment=${c.parentComment} (type: ${c.parentComment.runtimeType})');
    }

    // Separate parent comments and replies
    final parentComments = widget.post.comments.where((c) => 
      c.parentComment == null || c.parentComment == 0
    ).toList();
    
    final replies = widget.post.comments.where((c) => 
      c.parentComment != null && c.parentComment != 0
    ).toList();
    
    print('Found ${parentComments.length} parent comments and ${replies.length} replies');
    
    // Only show parent comments (never show replies as standalone)
    if (parentComments.isEmpty) {
      return const SizedBox.shrink(); // No parent comments to show
    }
    
    // Get last 2 parent comments (most recent)
    final recentParents = parentComments.length <= 2
        ? parentComments.reversed.toList()
        : parentComments.sublist(parentComments.length - 2).reversed.toList();

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
          // Comments with their replies
          ...recentParents.asMap().entries.expand((entry) {
            final index = entry.key;
            final comment = entry.value;
            final commentReplies = replies
                .where((r) {
                  print('Checking if reply ${r.id} (parent=${r.parentComment}) matches comment ${comment.id}');
                  return r.parentComment == comment.id;
                })
                .toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Sort by time
            final isReplyingToThis = _replyingTo?.id == comment.id;
            
            if (commentReplies.isNotEmpty) {
              print('Comment ${comment.id} has ${commentReplies.length} replies');
            }
            
            return [
              // Parent comment
              _CommentItem(
                comment: comment,
                onReply: widget.onReplySubmit != null ? () {
                  setState(() {
                    _replyingTo = comment;
                  });
                } : null,
              ),
              // Reply input (shown directly under this comment when replying)
              if (isReplyingToThis)
                _ReplyInput(
                  replyingTo: comment,
                  onSubmit: (content) {
                    widget.onReplySubmit?.call(comment, content);
                    setState(() {
                      _replyingTo = null;
                    });
                  },
                  onCancel: () {
                    setState(() {
                      _replyingTo = null;
                    });
                  },
                ),
              // Replies to this comment (child comments)
              if (commentReplies.isNotEmpty) ...[
                const SizedBox(height: 8),
                // Show only last 3 replies
                ...commentReplies.take(3).map((reply) => Container(
                  margin: const EdgeInsets.only(left: 40, bottom: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 8),
                  child: _CommentItem(
                    comment: reply,
                    onReply: null, // Don't allow replying to replies for now
                    isReply: true,
                  ),
                )),
                // "See more replies" button if there are more than 3
                if (commentReplies.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(left: 48, bottom: 8, right: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: widget.onViewAll,
                          child: Text(
                            'See ${commentReplies.length - 3} more ${commentReplies.length - 3 == 1 ? 'reply' : 'replies'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              // Spacing between comment groups
              if (index < recentParents.length - 1)
                const SizedBox(height: 12),
            ];
          }),
          // View all comments button
          if (widget.post.commentsCount > 2) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: widget.onViewAll,
              child: Row(
                children: [
                  Text(
                    'View all ${widget.post.commentsCount} comments',
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

class _ReplyInput extends StatefulWidget {
  final BusinessNetworkComment replyingTo;
  final Function(String) onSubmit;
  final VoidCallback onCancel;

  const _ReplyInput({
    required this.replyingTo,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<_ReplyInput> createState() => _ReplyInputState();
}

class _ReplyInputState extends State<_ReplyInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 40, top: 6, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Icon(Icons.reply, size: 12, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 60, // ~4 lines
              ),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Reply to ${widget.replyingTo.user.name}...',
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 11, height: 1.3),
                maxLines: null,
                minLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: InkWell(
              onTap: () {
                if (_controller.text.trim().isNotEmpty) {
                  widget.onSubmit(_controller.text.trim());
                  _controller.clear();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.send, size: 14, color: Colors.blue.shade700),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: InkWell(
              onTap: widget.onCancel,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 14, color: Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final BusinessNetworkComment comment;
  final VoidCallback? onReply;
  final bool isReply;

  const _CommentItem({
    required this.comment,
    this.onReply,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = isReply ? 28.0 : 32.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar (clickable)
          GestureDetector(
            onTap: () {
              final userId = comment.user.uuid ?? comment.user.id.toString();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: userId),
                ),
              );
            },
            child: Container(
              width: avatarSize,
              height: avatarSize,
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
                              size: avatarSize * 0.6,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey.shade100,
                        child: Icon(
                          Icons.person,
                          color: Colors.grey.shade400,
                          size: avatarSize * 0.6,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Comment Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User name and verified badge (clickable)
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: () {
                          final userId = comment.user.uuid ?? comment.user.id.toString();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(userId: userId),
                            ),
                          );
                        },
                        child: Text(
                          comment.user.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
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
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeAgo(comment.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Comment text
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    height: 1.3,
                  ),
                ),
                // Reply button
                if (onReply != null) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: onReply,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 11,
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
        ],
      ),
    );
  }

  String _formatTimeAgo(String dateString) {
    return formatTimeAgo(dateString);
  }
}
