import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import '../../services/auth_service.dart';
import '../../config/app_config.dart';
import '../../widgets/business_network/post_media_gallery.dart';
import '../../widgets/business_network/post_actions.dart';
import '../../widgets/business_network/post_comment_input.dart';
import '../../widgets/business_network/post_comments_preview.dart';
import '../../utils/time_utils.dart';
import '../../utils/url_launcher_utils.dart';
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
  bool _isLiking = false; // Prevent double-clicking

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadFullPost();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      // Reload post from API to ensure proper reply relationships and gift comments
      final updatedPost = await BusinessNetworkService.getPost(_post.id);
      if (updatedPost != null && mounted) {
        setState(() {
          _post = updatedPost;
        });
      } else if (mounted) {
        // Fallback to local update
        setState(() {
          _post = _post.copyWith(
            commentsCount: _post.commentsCount + 1,
            comments: [..._post.comments, comment],
          );
        });
      }
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
      shareText += '\n\nView on Business Network: ${AppConfig.mediaBaseUrl}/bn/posts/${_post.id}/';
      
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

  void _handleMediaTap(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Image ${index + 1} of ${_post.media.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Image
              Expanded(
                child: PageView.builder(
                  controller: PageController(initialPage: index),
                  itemCount: _post.media.length,
                  itemBuilder: (context, pageIndex) => InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.network(
                        _post.media[pageIndex].image,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 64, color: Colors.grey.shade600),
                                const SizedBox(height: 16),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // Image indicator dots
              if (_post.media.length > 1)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _post.media.length,
                      (dotIndex) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotIndex == index
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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
                            child: () {
                              final rawAvatarUrl = _post.user.image ?? _post.user.avatar;
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
                                        size: 20,
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
                                  size: 20,
                                ),
                              );
                            }(),
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
                          child: Html(
                            data: _post.content,
                            onLinkTap: (url, attributes, element) {
                              UrlLauncherUtils.launchExternalUrl(url);
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Post Media
                        if (_post.media.isNotEmpty)
                          PostMediaGallery(
                            media: _post.media,
                            onMediaTap: _handleMediaTap,
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
                        _buildUnifiedCommentsSection(),
                        
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
                userAvatar: AuthService.currentUser?.profilePicture,
                postId: _post.id.toString(),
                postAuthorId: _post.user.uuid ?? _post.user.id.toString(),
                postAuthorName: _post.user.name,
                onGiftSent: () {
                  // Reload post to show new gift comment
                  _loadFullPost();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedCommentsSection() {
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
      child: PostCommentsPreview(
        post: _post,
        onViewAll: () {},
        showAll: true,
        showHeader: true,
        onReplySubmit: (comment, content) async {
          final newComment = await BusinessNetworkService.addComment(
            postId: _post.id,
            content: content,
            parentCommentId: comment.id,
          );
          if (newComment != null) {
            await _handleCommentAdded(newComment);
          }
        },
        onCommentCountChanged: () {
          if (!mounted) return;
          setState(() {
            _post = _post.copyWith(
              commentsCount: _post.commentsCount > 0 ? _post.commentsCount - 1 : 0,
            );
          });
        },
      ),
    );
  }
}
