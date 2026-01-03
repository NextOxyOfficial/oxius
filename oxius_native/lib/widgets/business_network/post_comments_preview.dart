import 'package:flutter/material.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import '../../models/business_network_models.dart';
import '../../services/user_search_service.dart';
import '../../services/business_network_service.dart';
import '../../services/auth_service.dart';
import '../../utils/time_utils.dart';
import '../../utils/mention_parser.dart';
import '../../screens/business_network/profile_screen.dart';
import '../../config/app_config.dart';
import '../../widgets/link_preview_card.dart';

class PostCommentsPreview extends StatefulWidget {
  final BusinessNetworkPost post;
  final VoidCallback onViewAll;
  final Function(BusinessNetworkComment, String)? onReplySubmit;
  final VoidCallback? onCommentCountChanged;
  final bool showAll;
  final bool showHeader;

  PostCommentsPreview({
    super.key,
    required this.post,
    required this.onViewAll,
    this.onReplySubmit,
    this.onCommentCountChanged,
    this.showAll = false,
    this.showHeader = false,
  });

  @override
  State<PostCommentsPreview> createState() => _PostCommentsPreviewState();
}

class _PostCommentsPreviewState extends State<PostCommentsPreview> {
  BusinessNetworkComment? _replyingTo;
  final Set<int> _deletedCommentIds = {};
  final Set<int> _expandedReplies = {};

  @override
  void didUpdateWidget(PostCommentsPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if the actual comment IDs have changed (not just length)
    final oldIds = oldWidget.post.comments.map((c) => c.id).toSet();
    final newIds = widget.post.comments.map((c) => c.id).toSet();
    
    // If comments were removed (IDs in old but not in new)
    final removedIds = oldIds.difference(newIds);
    if (removedIds.isNotEmpty) {
      print('=== Comments Removed: $removedIds ===');
      // Remove these IDs from deleted set since they're already gone from the list
      _deletedCommentIds.removeAll(removedIds);
    }
    
    // If new comments were added
    final addedIds = newIds.difference(oldIds);
    if (addedIds.isNotEmpty) {
      print('=== New Comments Added: $addedIds ===');
      _replyingTo = null;
    }
  }

  void _handleCommentDeleted(int commentId) {
    setState(() {
      _deletedCommentIds.add(commentId);
      // Don't mutate widget.post.comments directly - just use the deleted IDs set for filtering
    });
    // Notify parent to update comment count
    widget.onCommentCountChanged?.call();
  }

  void _handleCommentUpdated(BusinessNetworkComment updatedComment) {
    // Don't mutate widget.post.comments directly
    // The parent widget should handle updating the post object
    // For now, just trigger a rebuild
    setState(() {
      // Force rebuild without mutation
    });
  }

  @override
  Widget build(BuildContext context) {
    print('=== BUILD START ===');
    print('Post ID: ${widget.post.id}');
    print('Total comments received: ${widget.post.comments.length}');
    print('Deleted IDs in state: $_deletedCommentIds');
    
    if (widget.post.comments.isEmpty) return const SizedBox.shrink();

    // Debug: Check what we're getting
    print('=== Comment Structure Debug ===');
    for (var c in widget.post.comments) {
      print('Comment ${c.id}: parentComment=${c.parentComment}, isGift=${c.isGiftComment}');
    }

    // Separate parent comments and replies (filter out deleted)
    print('=== Filtering Comments ===');
    print('Total comments: ${widget.post.comments.length}');
    print('Deleted IDs: $_deletedCommentIds');
    
    final parentComments = widget.post.comments.where((c) {
      final isDeleted = _deletedCommentIds.contains(c.id);
      final isParent = c.parentComment == null || c.parentComment == 0;
      print('Comment ${c.id}: isDeleted=$isDeleted, isParent=$isParent, parentComment=${c.parentComment}');
      return !isDeleted && isParent;
    }).toList();
    
    final replies = widget.post.comments.where((c) => 
      !_deletedCommentIds.contains(c.id) &&
      (c.parentComment != null && c.parentComment != 0)
    ).toList();
    
    print('Found ${parentComments.length} parent comments and ${replies.length} replies');
    
    // Only show parent comments (never show replies as standalone)
    if (parentComments.isEmpty) {
      print('WARNING: No parent comments found! Returning empty widget.');
      return const SizedBox.shrink(); // No parent comments to show
    }
    
    // Find the comment with highest diamond amount for pinning at the top (like Vue)
    BusinessNetworkComment? highestGiftComment;
    final giftComments = parentComments.where((c) => c.isGiftComment).toList();
    if (giftComments.isNotEmpty) {
      giftComments.sort((a, b) => (b.diamondAmount ?? 0).compareTo(a.diamondAmount ?? 0));
      highestGiftComment = giftComments.first;
      print('=== Gift Comment Found ===');
      print('Gift comment ID: ${highestGiftComment.id}');
      print('Is in deleted IDs: ${_deletedCommentIds.contains(highestGiftComment.id)}');
      print('Replying to ID: ${_replyingTo?.id}');
    }
    
    // Filter out the highest gift comment from regular comments to avoid duplication
    List<BusinessNetworkComment> displayedComments = [...parentComments];
    if (highestGiftComment != null) {
      displayedComments = displayedComments.where((c) => c.id != highestGiftComment!.id).toList();
    }
    
    // Sort comments by creation date in ascending order (oldest first)
    displayedComments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    final List<BusinessNetworkComment> recentParents;
    if (widget.showAll) {
      recentParents = displayedComments.reversed.toList();
    } else {
      recentParents = displayedComments.length <= 3
          ? displayedComments.reversed.toList()
          : displayedComments.sublist(displayedComments.length - 3).reversed.toList();
    }

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
          if (widget.showHeader) ...[
            Row(
              children: [
                Text(
                  'Comments',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${widget.post.commentsCount})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          // Pinned highest gift comment (if exists)
          if (highestGiftComment != null) ...[
            Row(
              children: [
                Icon(Icons.star, size: 12, color: Colors.amber.shade600),
                const SizedBox(width: 4),
                Text(
                  'Top Gift',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _CommentItem(
              comment: highestGiftComment,
              post: widget.post,
              onReply: widget.onReplySubmit != null ? () {
                setState(() {
                  _replyingTo = highestGiftComment;
                });
              } : null,
              onCommentDeleted: () => _handleCommentDeleted(highestGiftComment!.id),
              onCommentUpdated: _handleCommentUpdated,
            ),
            // Replies to highest gift comment
            ...(() {
              final giftReplies = replies.where((r) => r.parentComment == highestGiftComment!.id).toList()
                ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
              print('=== Gift Replies ===');
              print('Total replies: ${replies.length}');
              print('Gift comment ID: ${highestGiftComment!.id}');
              print('Matching replies: ${giftReplies.length}');
              for (var r in replies) {
                print('Reply ${r.id}: parentComment=${r.parentComment}');
              }
              return giftReplies.map((reply) => _CommentItem(
                comment: reply,
                post: widget.post,
                isReply: true,
                onCommentDeleted: () => _handleCommentDeleted(reply.id),
                onCommentUpdated: _handleCommentUpdated,
              ));
            })(),
            // Reply input for highest gift
            if (_replyingTo?.id == highestGiftComment.id)
              _ReplyInput(
                replyingTo: highestGiftComment,
                onCancel: () {
                  setState(() {
                    _replyingTo = null;
                  });
                },
                onSubmit: (content) async {
                  if (widget.onReplySubmit != null) {
                    await widget.onReplySubmit!(highestGiftComment!, content);
                    setState(() {
                      _replyingTo = null;
                    });
                  }
                },
              ),
            const SizedBox(height: 8),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 8),
          ],
          // Regular comments with replies (including other gift comments)
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
            final isExpanded = _expandedReplies.contains(comment.id);
            final repliesToShow = widget.showAll
                ? (isExpanded ? commentReplies : commentReplies.take(4).toList())
                : commentReplies.take(3).toList();
            
            if (commentReplies.isNotEmpty) {
              print('Comment ${comment.id} has ${commentReplies.length} replies');
            }
            
            return [
              // Parent comment
              _CommentItem(
                comment: comment,
                post: widget.post,
                onReply: widget.onReplySubmit != null ? () {
                  setState(() {
                    _replyingTo = comment;
                  });
                } : null,
                onCommentDeleted: () => _handleCommentDeleted(comment.id),
                onCommentUpdated: _handleCommentUpdated,
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
              if (repliesToShow.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...repliesToShow.map((reply) => Container(
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
                    post: widget.post,
                    onReply: null, // Don't allow replying to replies for now
                    isReply: true,
                    onCommentDeleted: () => _handleCommentDeleted(reply.id),
                    onCommentUpdated: _handleCommentUpdated,
                  ),
                )),
                if (widget.showAll) ...[
                  if (commentReplies.length > 4 && !isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(left: 48, bottom: 8, right: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _expandedReplies.add(comment.id);
                              });
                            },
                            child: Text(
                              'See ${commentReplies.length - 4} more ${commentReplies.length - 4 == 1 ? 'reply' : 'replies'}',
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
                ] else ...[
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
              ],
              // Spacing between comment groups
              if (index < recentParents.length - 1)
                const SizedBox(height: 12),
            ];
          }),
          // View all comments button
          if (!widget.showAll && widget.post.commentsCount > 2) ...[
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
  final GlobalKey<FlutterMentionsState> _mentionKey = GlobalKey<FlutterMentionsState>();
  List<Map<String, dynamic>> _userData = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialUsers();
  }

  Future<void> _loadInitialUsers() async {
    final users = await _searchUsers('');
    if (mounted) {
      setState(() {
        _userData = users;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _searchUsers(String query) async {
    try {
      final users = await UserSearchService.searchUsers(query);
      return users.map((user) => {
        'id': user.id.toString(),
        'display': user.name,
        'full_name': user.name,
        'photo': user.image ?? user.avatar,
      }).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  void _handleSubmit() {
    if (_isSubmitting) return;
    
    final plainText = _mentionKey.currentState?.controller?.text ?? '';
    if (plainText.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    // Format mentions with double space after name for parsing
    final formattedText = plainText.replaceAllMapped(
      RegExp(r'@([A-Za-z][A-Za-z\s]+?)(?=\s{2,}|[.!?,;:]|\s+[^A-Z]|$)'),
      (match) {
        final name = match.group(1)?.trim() ?? '';
        return '@$name  ';
      },
    ).trim();

    widget.onSubmit(formattedText);
    _mentionKey.currentState?.controller?.clear();
    
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
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
                maxHeight: 80,
              ),
              child: FlutterMentions(
                key: _mentionKey,
                suggestionPosition: SuggestionPosition.Top,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Reply to ${widget.replyingTo.user.name}...',
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 11, height: 1.3),
                onChanged: (value) async {
                  if (value.contains('@')) {
                    final lastAtIndex = value.lastIndexOf('@');
                    final textAfterAt = value.substring(lastAtIndex + 1);
                    
                    if (textAfterAt.isNotEmpty && !textAfterAt.contains(' ')) {
                      final users = await _searchUsers(textAfterAt);
                      if (mounted) {
                        setState(() {
                          _userData = users;
                        });
                      }
                    }
                  }
                },
                mentions: [
                  Mention(
                    trigger: '@',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    data: _userData,
                    matchAll: false,
                    disableMarkup: false,
                    suggestionBuilder: (data) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade100,
                              ),
                              child: ClipOval(
                                child: () {
                                  final avatarUrl = AppConfig.getAbsoluteUrl(data['photo']);
                                  if (avatarUrl.isNotEmpty) {
                                    return Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(Icons.person, color: Colors.grey.shade400, size: 14);
                                      },
                                    );
                                  }
                                  return Icon(Icons.person, color: Colors.grey.shade400, size: 14);
                                }(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data['display'] ?? '',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: InkWell(
              onTap: _isSubmitting ? null : _handleSubmit,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: _isSubmitting
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blue.shade700,
                        ),
                      )
                    : Icon(Icons.send, size: 14, color: Colors.blue.shade700),
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

class _CommentItem extends StatefulWidget {
  final BusinessNetworkComment comment;
  final VoidCallback? onReply;
  final bool isReply;
  final Function(BusinessNetworkComment)? onCommentUpdated;
  final VoidCallback? onCommentDeleted;
  final BusinessNetworkPost? post;

  const _CommentItem({
    required this.comment,
    this.onReply,
    this.isReply = false,
    this.post,
    this.onCommentUpdated,
    this.onCommentDeleted,
  });

  @override
  State<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<_CommentItem> {
  bool _isEditing = false;
  late TextEditingController _editController;
  final GlobalKey<FlutterMentionsState> _editMentionKey = GlobalKey();
  List<Map<String, dynamic>> _userData = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Remove mention formatting for editing (keep just the plain text)
    final plainContent = widget.comment.content.replaceAllMapped(
      RegExp(r'@([^@]+?)  '),
      (match) => '@${match.group(1)} ',
    );
    _editController = TextEditingController(text: plainContent);
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    final user = AuthService.currentUser;
    _currentUserId = user?.id;
    print('=== Edit/Delete Check ===');
    print('Current user: $user');
    print('Current user ID: $_currentUserId (type: ${_currentUserId.runtimeType})');
    print('Comment author: ${widget.comment.user.name}');
    print('Comment author ID: ${widget.comment.user.id} (type: ${widget.comment.user.id.runtimeType})');
    print('Comment author UUID: ${widget.comment.user.uuid}');
    print('IDs match: ${widget.comment.user.id == _currentUserId}');
    print('Can edit/delete: $_canEditDelete');
    
    // Force rebuild to show the menu
    if (mounted) {
      setState(() {});
    }
  }

  Future<List<Map<String, dynamic>>> _searchUsers(String query) async {
    if (query.isEmpty) return [];
    try {
      final users = await UserSearchService.searchUsers(query);
      return users.map((user) => {
        'id': user.id.toString(),
        'display': (user.username != null && user.username!.trim().isNotEmpty) ? user.username!.trim() : user.name,
        'full_name': user.name,
        'photo': user.image ?? user.avatar,
      }).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  bool get _isCommentAuthor {
    if (_currentUserId == null) return false;
    
    final commentUserId = widget.comment.user.id.toString();
    final commentUserUuid = widget.comment.user.uuid;
    
    // Compare with UUID first if available
    if (commentUserUuid != null && commentUserUuid.isNotEmpty) {
      if (commentUserUuid == _currentUserId) return true;
    }
    
    // Compare with ID (both as strings)
    if (commentUserId == _currentUserId) return true;
    
    // Also try comparing with ID as integer if currentUserId is numeric
    if (int.tryParse(_currentUserId!) != null && 
        int.tryParse(commentUserId) != null) {
      if (int.parse(_currentUserId!) == int.parse(commentUserId)) return true;
    }
    
    return false;
  }

  bool get _isPostOwner {
    if (_currentUserId == null || widget.post == null) return false;
    
    final postAuthorId = widget.post!.user.id.toString();
    final postAuthorUuid = widget.post!.user.uuid;
    
    // Compare with UUID first if available
    if (postAuthorUuid != null && postAuthorUuid.isNotEmpty) {
      if (postAuthorUuid == _currentUserId) return true;
    }
    
    // Compare with ID (both as strings)
    if (postAuthorId == _currentUserId) return true;
    
    // Also try comparing with ID as integer
    if (int.tryParse(_currentUserId!) != null && 
        int.tryParse(postAuthorId) != null) {
      if (int.parse(_currentUserId!) == int.parse(postAuthorId)) return true;
    }
    
    return false;
  }

  bool get _canEditDelete {
    return _isCommentAuthor || _isPostOwner;
  }

  @override
  Widget build(BuildContext context) {
    final avatarSize = widget.isReply ? 28.0 : 32.0;
    
    return InkWell(
      onLongPress: _canEditDelete ? () {
        print('=== Long Press Detected ===');
        print('Can edit/delete: $_canEditDelete');
        print('Current user ID: $_currentUserId');
        print('Comment user ID: ${widget.comment.user.id}');
        _showEditDeleteOptions();
      } : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // User Avatar (clickable) - wrapped in Padding to align with text baseline
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: () {
                final userId = widget.comment.user.uuid ?? widget.comment.user.id.toString();
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
                child: () {
                  final rawAvatarUrl = widget.comment.user.image ?? widget.comment.user.avatar;
                  final avatarUrl = AppConfig.getAbsoluteUrl(rawAvatarUrl);
                  
                  if (avatarUrl.isNotEmpty) {
                    return Image.network(
                      avatarUrl,
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
                    );
                  }
                  return Container(
                    color: Colors.grey.shade100,
                    child: Icon(
                      Icons.person,
                      color: Colors.grey.shade400,
                      size: avatarSize * 0.6,
                    ),
                  );
                }(),
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
                // User name, verified badge, time, and menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Name and verified badge
                    Flexible(
                      child: GestureDetector(
                        onTap: () {
                          final userId = widget.comment.user.uuid ?? widget.comment.user.id.toString();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(userId: userId),
                            ),
                          );
                        },
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: widget.comment.user.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  height: 1.2,
                                ),
                              ),
                              if (widget.comment.user.isVerified) ...[
                                const TextSpan(text: ' '),
                                const WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                              if (widget.comment.user.isPro) ...[
                                const TextSpan(text: ' '),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade600,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                                    ),
                                    child: const Text(
                                      'Pro',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          maxLines: null,
                        ),
                      ),
                    ),
                    // Time (inline on right)
                    const SizedBox(width: 6),
                    Text(
                      _formatTimeAgo(widget.comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                // Comment text or gift comment
                if (widget.comment.isGiftComment)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.pink.shade50.withOpacity(0.7),
                          Colors.purple.shade50.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.pink.shade200, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gift label
                        Row(
                          children: [
                            Icon(Icons.card_giftcard, size: 14, color: Colors.pink.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Sent ${widget.comment.diamondAmount ?? 0} diamonds',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.pink.shade700,
                              ),
                            ),
                          ],
                        ),
                        if (widget.comment.content.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          () {
                            final extractedMessage = _extractGiftMessage(widget.comment.content);
                            if (extractedMessage.isNotEmpty) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    extractedMessage,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade800,
                                      height: 1.4,
                                    ),
                                  ),
                                  FirstLinkPreview(text: extractedMessage),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          }(),
                        ],
                      ],
                    ),
                  )
                else if (_isEditing)
                  // Edit mode with mention support
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FlutterMentions(
                        key: _editMentionKey,
                        suggestionPosition: SuggestionPosition.Top,
                        maxLines: 3,
                        minLines: 1,
                        defaultText: _editController.text,
                        decoration: InputDecoration(
                          hintText: 'Edit comment...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                        mentions: [
                          Mention(
                            trigger: '@',
                            data: _userData,
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                            matchAll: false,
                            suggestionBuilder: (data) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage: data['photo'] != null
                                          ? NetworkImage(data['photo'])
                                          : null,
                                      child: data['photo'] == null
                                          ? const Icon(Icons.person, size: 16)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      data['full_name'] ?? data['display'] ?? '',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                        onChanged: (value) async {
                          // Search users when typing @
                          if (value.contains('@')) {
                            final lastAtIndex = value.lastIndexOf('@');
                            final query = value.substring(lastAtIndex + 1);
                            if (query.isNotEmpty && !query.contains(' ')) {
                              final users = await _searchUsers(query);
                              setState(() {
                                _userData = users;
                              });
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                // Reset to original plain content
                                final plainContent = widget.comment.content.replaceAllMapped(
                                  RegExp(r'@([^@]+?)  '),
                                  (match) => '@${match.group(1)} ',
                                );
                                _editController.text = plainContent;
                              });
                            },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              // Get text from FlutterMentions and format for storage
                              final plainText = _editMentionKey.currentState?.controller?.text ?? '';
                              
                              final updatedComment = await BusinessNetworkService.updateComment(
                                commentId: widget.comment.id,
                                content: plainText.trim(),
                              );
                              if (!mounted) return;
                              
                              if (updatedComment != null) {
                                setState(() => _isEditing = false);
                                widget.onCommentUpdated?.call(updatedComment);
                                if (mounted && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Comment updated')),
                                  );
                                }
                              }
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  // Regular comment with mention support
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: MentionParser.parseTextWithMentionsAndLinks(
                            widget.comment.content,
                            context,
                            onMentionTap: (username) async {
                              // Search for user by name to get their ID
                              try {
                                final users = await UserSearchService.searchUsers(username);
                                if (users.isNotEmpty && context.mounted) {
                                  final user = users.first;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfileScreen(
                                        userId: user.id.toString(),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                print('Error finding user: $e');
                              }
                            },
                          ),
                        ),
                      ),
                      FirstLinkPreview(text: widget.comment.content),
                    ],
                  ),
                // Reply button
                if (widget.onReply != null && !_isEditing) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: widget.onReply,
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
      ),
    );
  }

  void _showEditDeleteOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit option (only for comment author)
            if (_isCommentAuthor) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF3B82F6)),
                title: const Text('Edit Comment'),
                onTap: () {
                  Navigator.pop(context);
                  final plainContent = widget.comment.content.replaceAllMapped(
                    RegExp(r'@([^@]+?)  '),
                    (match) => '@${match.group(1)} ',
                  );
                  _editController.text = plainContent;
                  setState(() => _isEditing = true);
                },
              ),
              const Divider(height: 1),
            ],
            // Delete option (for both comment author and post owner)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Comment', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Comment'),
                    content: const Text('Are you sure you want to delete this comment?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final success = await BusinessNetworkService.deleteComment(widget.comment.id);
                  if (!mounted) return;
                  
                  if (success) {
                    widget.onCommentDeleted?.call();
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Comment deleted')),
                      );
                    }
                  } else {
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to delete comment'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(String dateString) {
    return formatTimeAgo(dateString);
  }

  String _extractGiftMessage(String content) {
    // Remove common prefixes like "Sent X diamonds as a gift! ✨"
    if (content.contains('diamonds as a gift')) {
      final cleaned = content.replaceFirst(RegExp(r'Sent \d+ diamonds as a gift! ✨\s*'), '').trim();
      // Only return the custom message if it's not empty
      return cleaned.isEmpty ? '' : cleaned;
    }
    return content;
  }
}
