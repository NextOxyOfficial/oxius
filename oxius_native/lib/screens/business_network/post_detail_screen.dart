import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import '../../widgets/business_network/post_header.dart';
import '../../widgets/business_network/post_media_gallery.dart';
import '../../widgets/business_network/post_actions.dart';
import '../../widgets/business_network/post_comment_input.dart';
import '../../utils/time_utils.dart';

class PostDetailScreen extends StatefulWidget {
  final BusinessNetworkPost post;

  const PostDetailScreen({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late BusinessNetworkPost _post;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  BusinessNetworkComment? _replyingTo;
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadFullPost();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadFullPost() async {
    setState(() => _isLoading = true);
    
    final fullPost = await BusinessNetworkService.getPost(_post.id);
    
    if (mounted && fullPost != null) {
      setState(() {
        _post = fullPost;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLikeToggle() async {
    final success = await BusinessNetworkService.toggleLike(_post.id, _post.isLiked);
    
    if (success && mounted) {
      setState(() {
        _post = _post.copyWith(
          isLiked: !_post.isLiked,
          likesCount: _post.isLiked ? _post.likesCount - 1 : _post.likesCount + 1,
        );
      });
    }
  }

  Future<void> _handleCommentAdded(BusinessNetworkComment comment) async {
    if (mounted) {
      setState(() {
        _post = _post.copyWith(
          commentsCount: _post.commentsCount + 1,
          comments: [..._post.comments, comment],
        );
      });
    }
  }

  Future<void> _handleShare() async {
    try {
      // Create share text with post title and content
      String shareText = '';
      
      if (_post.title.isNotEmpty) {
        shareText += '${_post.title}\n\n';
      }
      
      shareText += _post.content;
      
      // Add post link
      shareText += '\n\nView on Business Network: http://127.0.0.1:8000/bn/posts/${_post.id}/';
      
      // Share the content
      await Share.share(
        shareText,
        subject: _post.title.isNotEmpty ? _post.title : 'Business Network Post',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    final success = await BusinessNetworkService.toggleSave(_post.id, _post.isSaved);
    
    if (success && mounted) {
      setState(() {
        _post = _post.copyWith(
          isSaved: !_post.isSaved,
        );
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_post.isSaved ? 'Post saved' : 'Post unsaved'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Post',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 672),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(4, 8, 4, isMobile ? 80 : 16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post Header
                  PostHeader(
                    post: _post,
                    onMorePressed: () {},
                  ),
                  
                  // Post Title
                  if (_post.title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Text(
                        _post.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  
                  // Post Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _post.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Post Media
                  if (_post.media.isNotEmpty)
                    PostMediaGallery(
                      media: _post.media,
                      onMediaTap: (index) {
                        // TODO: Open media viewer
                      },
                    ),
                  
                  // Post Actions
                  PostActions(
                    post: _post,
                    onLike: _handleLikeToggle,
                    onComment: () {
                      // Scroll to comment input
                    },
                    onShare: _handleShare,
                    onSave: _handleSave,
                  ),
                  
                  const Divider(height: 1),
                  
                  // All Comments Section
                  _buildCommentsSection(),
                  
                  // Reply Input (shown when replying to a comment)
                  if (_replyingTo != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: Colors.blue.shade50,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Replying to ${_replyingTo!.user.name}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _replyingTo = null;
                                    _replyController.clear();
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          PostCommentInput(
                            onSubmit: (content) async {
                              final comment = await BusinessNetworkService.addComment(
                                postId: _post.id,
                                content: content,
                                parentCommentId: _replyingTo!.id,
                              );
                              if (comment != null) {
                                _handleCommentAdded(comment);
                                setState(() {
                                  _replyingTo = null;
                                  _replyController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  
                  // Add Comment Input
                  if (_replyingTo == null)
                    PostCommentInput(
                      onSubmit: (content) async {
                        final comment = await BusinessNetworkService.addComment(
                          postId: _post.id,
                          content: content,
                        );
                        if (comment != null) {
                          _handleCommentAdded(comment);
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_post.comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.comment_outlined,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'No comments yet',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Be the first to comment!',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'Comments (${_post.commentsCount})',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          // Display top-level comments and their replies
          ..._buildCommentTree(),
        ],
      ),
    );
  }

  List<Widget> _buildCommentTree() {
    // Separate top-level comments and replies
    final topLevelComments = _post.comments.where((c) => c.parentComment == null).toList();
    final replies = _post.comments.where((c) => c.parentComment != null).toList();
    
    // Build comment tree
    final widgets = <Widget>[];
    
    for (final comment in topLevelComments) {
      // Add parent comment
      widgets.add(_CommentItem(
        comment: comment,
        isReply: false,
        onReply: () {
          setState(() {
            _replyingTo = comment;
          });
          // Scroll to bottom to show reply input
          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        },
      ));
      
      // Add replies to this comment
      final commentReplies = replies.where((r) => r.parentComment == comment.id).toList();
      for (final reply in commentReplies) {
        widgets.add(_CommentItem(
          comment: reply,
          isReply: true,
          onReply: () {
            setState(() {
              _replyingTo = comment; // Reply to the parent comment
            });
            Future.delayed(const Duration(milliseconds: 100), () {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            });
          },
        ));
      }
    }
    
    return widgets;
  }
}

class _CommentItem extends StatelessWidget {
  final BusinessNetworkComment comment;
  final VoidCallback onReply;
  final bool isReply;

  const _CommentItem({
    required this.comment,
    required this.onReply,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: isReply ? 48 : 0), // Indent replies
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isReply ? Colors.grey.shade50 : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade100,
            width: 1,
          ),
          left: isReply
              ? BorderSide(
                  color: Colors.blue.shade200,
                  width: 3,
                )
              : BorderSide.none,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
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
                            size: 20,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey.shade100,
                      child: Icon(
                        Icons.person,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Comment Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.user.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (comment.user.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: Color(0xFF3B82F6),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      formatTimeAgo(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        // TODO: Like comment
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Like',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: onReply,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
