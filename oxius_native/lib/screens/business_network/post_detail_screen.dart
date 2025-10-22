import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/business_network/post_header.dart';
import '../../widgets/business_network/post_media_gallery.dart';
import '../../widgets/business_network/post_actions.dart';
import '../../widgets/business_network/post_comment_input.dart';
import '../../utils/time_utils.dart';
import 'profile_screen.dart';

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
  int _displayedCommentsCount = 10; // Show 10 comments initially
  bool _isLoadingMore = false;
  final Set<int> _expandedReplies = {}; // Track which comments have expanded replies
  bool _isLiking = false; // Prevent double-clicking

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadFullPost();
    _scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreComments();
    }
  }
  
  void _loadMoreComments() {
    if (_isLoadingMore) return;
    
    final totalComments = _post.comments.where((c) => c.parentComment == null || c.parentComment == 0).length;
    if (_displayedCommentsCount >= totalComments) return;
    
    setState(() {
      _isLoadingMore = true;
      _displayedCommentsCount = (_displayedCommentsCount + 10).clamp(0, totalComments);
    });
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    });
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
    // Prevent double-clicking
    if (_isLiking) return;
    
    _isLiking = true;
    
    // Store original state for rollback
    final originalIsLiked = _post.isLiked;
    final originalLikesCount = _post.likesCount;
    
    // Optimistic update - update UI immediately
    if (mounted) {
      setState(() {
        _post = _post.copyWith(
          isLiked: !_post.isLiked,
          likesCount: _post.isLiked ? _post.likesCount - 1 : _post.likesCount + 1,
        );
      });
    }
    
    // Make API call
    final success = await BusinessNetworkService.toggleLike(_post.id, originalIsLiked);
    
    _isLiking = false;
    
    if (!success && mounted) {
      // Failed - rollback to original state
      setState(() {
        _post = _post.copyWith(
          isLiked: originalIsLiked,
          likesCount: originalLikesCount,
        );
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${originalIsLiked ? 'unlike' : 'like'} post'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
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

  bool _isSelfPost() {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return false;
    
    return _post.user.username == currentUser.username ||
           _post.user.uuid == currentUser.id ||
           _post.user.id.toString() == currentUser.id;
  }
  
  void _navigateToProfile() {
    final userId = _post.user.uuid ?? _post.user.id.toString();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: userId),
      ),
    );
  }

  Future<void> _handleFollowToggle() async {
    // Use user UUID or username for follow action
    final userId = _post.user.uuid ?? _post.user.username ?? _post.user.id.toString();
    
    final wasFollowing = _post.user.isFollowing;
    
    // Optimistic update - update UI immediately
    if (mounted) {
      setState(() {
        _post = _post.copyWith(
          user: BusinessNetworkUser(
            id: _post.user.id,
            uuid: _post.user.uuid,
            name: _post.user.name,
            avatar: _post.user.avatar,
            image: _post.user.image,
            isVerified: _post.user.isVerified,
            bio: _post.user.bio,
            username: _post.user.username,
            firstName: _post.user.firstName,
            lastName: _post.user.lastName,
            isFollowing: !wasFollowing, // Toggle immediately
          ),
        );
      });
    }
    
    // Make API call
    final success = await BusinessNetworkService.toggleFollow(userId, wasFollowing);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_post.user.isFollowing ? 'Following ${_post.user.name}' : 'Unfollowed ${_post.user.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (!success && mounted) {
      // Failed - rollback to original state
      setState(() {
        _post = _post.copyWith(
          user: BusinessNetworkUser(
            id: _post.user.id,
            uuid: _post.user.uuid,
            name: _post.user.name,
            avatar: _post.user.avatar,
            image: _post.user.image,
            isVerified: _post.user.isVerified,
            bio: _post.user.bio,
            username: _post.user.username,
            firstName: _post.user.firstName,
            lastName: _post.user.lastName,
            isFollowing: wasFollowing, // Rollback
          ),
        );
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${wasFollowing ? 'unfollow' : 'follow'} ${_post.user.name}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  // Back Button
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    color: Colors.black87,
                    onPressed: () => Navigator.pop(context, _post),
                    padding: const EdgeInsets.all(8),
                  ),
                  // Profile Section
                  Expanded(
                    child: GestureDetector(
                      onTap: _navigateToProfile,
                      child: Row(
                        children: [
                          // Profile Photo
                          Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _post.user.image != null || _post.user.avatar != null
                                ? Image.network(
                                    _post.user.image ?? _post.user.avatar!,
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
                        // Name and Verified Badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _post.user.name,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_post.user.isVerified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified,
                                      size: 16,
                                      color: Color(0xFF3B82F6),
                                    ),
                                  ],
                                                  // Follow/Following Button (not for self posts) - inline with name
                                  if (!_isSelfPost()) ...[
                                    if (!_post.user.isFollowing) ...[
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: _handleFollowToggle,
                                        child: const Text(
                                          '• Follow',
                                          style: TextStyle(
                                            color: Color(0xFF3B82F6),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: _handleFollowToggle,
                                        child: Text(
                                          '• Following',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                              Text(
                                formatTimeAgo(_post.createdAt),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadFullPost,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 672),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Post Title
                        if (_post.title.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                          padding: EdgeInsets.fromLTRB(16, _post.title.isNotEmpty ? 0 : 16, 16, 0),
                          child: Text(
                            _post.content,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                              height: 1.5,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
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
                        
                        // All Comments Section with inline reply inputs
                        _buildCommentsSection(),
                        
                        // Loading more indicator
                        if (_isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        
                        const SizedBox(height: 80), // Space for bottom input
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Sticky Bottom Input
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: PostCommentInput(
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
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
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
    final topLevelComments = _post.comments
        .where((c) => c.parentComment == null || c.parentComment == 0)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort newest first
    
    // Limit to displayed count
    final displayedComments = topLevelComments.take(_displayedCommentsCount).toList();
    
    final replies = _post.comments
        .where((c) => c.parentComment != null && c.parentComment != 0)
        .toList();
    
    // Build comment tree
    final widgets = <Widget>[];
    
    for (final comment in displayedComments) {
      final isReplyingToThis = _replyingTo?.id == comment.id;
      
      // Add parent comment
      widgets.add(_CommentItem(
        comment: comment,
        isReply: false,
        onReply: () {
          setState(() {
            _replyingTo = comment;
          });
        },
      ));
      
      // Add inline reply input (shown directly under this comment when replying)
      if (isReplyingToThis) {
        widgets.add(
          Container(
            margin: const EdgeInsets.only(left: 40, top: 0, bottom: 12, right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.blue.shade200,
                width: 0.5,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(Icons.reply, size: 12, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: InputDecoration(
                        hintText: 'Reply to ${comment.user.name}...',
                        hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 11),
                      maxLines: 4,
                      minLines: 1,
                      onSubmitted: (content) async {
                        if (content.trim().isEmpty) return;
                        final newComment = await BusinessNetworkService.addComment(
                          postId: _post.id,
                          content: content,
                          parentCommentId: comment.id,
                        );
                        if (newComment != null) {
                          _handleCommentAdded(newComment);
                          setState(() {
                            _replyingTo = null;
                            _replyController.clear();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () async {
                              if (_replyController.text.trim().isEmpty) return;
                              final newComment = await BusinessNetworkService.addComment(
                                postId: _post.id,
                                content: _replyController.text,
                                parentCommentId: comment.id,
                              );
                              if (newComment != null) {
                                _handleCommentAdded(newComment);
                                setState(() {
                                  _replyingTo = null;
                                  _replyController.clear();
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(Icons.send, size: 14, color: Colors.blue.shade700),
                            ),
                          ),
                          const SizedBox(width: 2),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _replyingTo = null;
                                _replyController.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(Icons.close, size: 14, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
      
      // Add replies to this comment
      final commentReplies = replies
          .where((r) => r.parentComment == comment.id)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Sort oldest first for replies
      
      if (commentReplies.isNotEmpty) {
        widgets.add(const SizedBox(height: 1));
        
        // Check if this comment's replies are expanded
        final isExpanded = _expandedReplies.contains(comment.id);
        final repliesToShow = isExpanded ? commentReplies : commentReplies.take(4).toList();
        
        for (final reply in repliesToShow) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Vertical line
                    Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 4, bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Comment content
                    Expanded(
                      child: _CommentItem(
                        comment: reply,
                        isReply: true,
                        onReply: null, // Don't allow replying to replies
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        // Show "See more replies" button if there are more than 4 replies
        if (commentReplies.length > 4 && !isExpanded) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 4, bottom: 8),
              child: InkWell(
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
            ),
          );
        }
        
        // Add margin after last reply
        widgets.add(const SizedBox(height: 12));
      }
    }
    
    return widgets;
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
                      formatTimeAgo(comment.createdAt),
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
}
