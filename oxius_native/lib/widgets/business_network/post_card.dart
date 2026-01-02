import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import '../../services/auth_service.dart';
import '../../config/app_config.dart';
import '../../screens/business_network/post_detail_screen.dart';
import '../../screens/business_network/search_screen.dart';
import '../../utils/network_error_handler.dart';
import '../../utils/url_launcher_utils.dart';
import '../../widgets/link_preview_card.dart';
import 'post_header.dart';
import 'post_media_gallery.dart';
import 'post_actions.dart';
import 'post_comments_preview.dart';
import 'post_comment_input.dart';
import '../../screens/business_network/post_media_viewer_screen.dart';
import '../../screens/business_network/shorts_player_screen.dart';

class PostCard extends StatefulWidget {
  final BusinessNetworkPost post;
  final VoidCallback? onLikeToggle;
  final Function(BusinessNetworkComment)? onCommentAdded;
  final VoidCallback? onPostDeleted;
  final void Function(int postId, bool isSaved)? onSaveChanged;

  const PostCard({
    super.key,
    required this.post,
    this.onLikeToggle,
    this.onCommentAdded,
    this.onPostDeleted,
    this.onSaveChanged,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late BusinessNetworkPost _post;
  bool _isAddingComment = false;
  BusinessNetworkComment? _replyingTo;
  bool _showFullContent = false;
  bool _isLiking = false; // Prevent double-clicking

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      setState(() {
        _post = widget.post;
      });
    }
  }

  bool _isSelfPost() {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return false;
    
    return _post.user.username == currentUser.username ||
           _post.user.uuid == currentUser.id ||
           _post.user.id.toString() == currentUser.id;
  }
  
  bool _shouldShowFollowButton() {
    // Don't show if user is not logged in
    if (AuthService.currentUser == null) return false;
    
    // Don't show on own posts
    if (_isSelfPost()) return false;
    
    return true;
  }

  Future<void> _addComment(String content) async {
    if (_isAddingComment) return;

    setState(() => _isAddingComment = true);

    final comment = await BusinessNetworkService.addComment(
      postId: _post.id,
      content: content,
    );

    if (comment != null && mounted) {
      // Small delay to allow UI to update smoothly
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Reload post from API to ensure gift comments and all properties are preserved
      final updatedPost = await BusinessNetworkService.getPost(_post.id);
      if (updatedPost != null && mounted) {
        setState(() {
          _post = updatedPost;
          _isAddingComment = false;
        });
        
        widget.onCommentAdded?.call(comment);
      } else if (mounted) {
        // Fallback to local update
        setState(() {
          _post = _post.copyWith(
            commentsCount: _post.commentsCount + 1,
            comments: [..._post.comments, comment],
          );
          _isAddingComment = false;
        });
        
        widget.onCommentAdded?.call(comment);
      }
    } else if (mounted) {
      setState(() => _isAddingComment = false);
    }
  }

  void _handleMediaTap(int index) {
    // ignore: discarded_futures
    _handleMediaTapAsync(index);
  }

  Future<void> _handleMediaTapAsync(int index) async {
    if (_post.media.length == 1 && index == 0 && _post.media[0].isVideo) {
      final updates = await Navigator.push<Map<int, BusinessNetworkPost>?>
      (
        context,
        MaterialPageRoute(
          builder: (context) => ShortsPlayerScreen(
            initialPost: _post,
            initialMedia: _post.media[0],
          ),
          fullscreenDialog: true,
        ),
      );

      if (!mounted) return;
      final updated = updates?[_post.id];
      if (updated != null) {
        setState(() {
          _post = updated;
        });
      }
      return;
    }

    await _openMediaViewer(index);
  }

  Future<void> _openMediaViewer(int index) async {
    final updatedPost = await Navigator.push<BusinessNetworkPost?>(
      context,
      MaterialPageRoute(
        builder: (context) => PostMediaViewerScreen(
          post: _post,
          initialIndex: index,
        ),
        fullscreenDialog: true,
      ),
    );

    if (updatedPost != null && mounted) {
      setState(() {
        _post = updatedPost;
      });
    }
  }

  Future<void> _handleViewAllComments() async {
    // Check authentication
    if (AuthService.currentUser == null) {
      _showLoginPrompt('view comments');
      return;
    }
    
    final updatedPost = await Navigator.push<BusinessNetworkPost>(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(post: _post),
      ),
    );
    
    // Update the post if it was modified (e.g., new comments added)
    if (updatedPost != null && mounted) {
      setState(() {
        _post = updatedPost;
      });
    }
  }
  
  void _showLoginPrompt(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: Text('Please login to $action'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
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

  Future<void> _handleLike() async {
    // Check authentication
    if (AuthService.currentUser == null) {
      _showLoginPrompt('like this post');
      return;
    }
    
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
          isLiked: !originalIsLiked,
          likesCount: originalIsLiked ? originalLikesCount - 1 : originalLikesCount + 1,
        );
      });
    }
    
    // Make API call
    try {
      await BusinessNetworkService.toggleLike(_post.id, originalIsLiked);
      _isLiking = false;
      
      // Trigger callback if provided
      if (widget.onLikeToggle != null) {
        widget.onLikeToggle!();
      }
    } catch (e) {
      _isLiking = false;
      
      // Failed - rollback to original state
      if (mounted) {
        setState(() {
          _post = _post.copyWith(
            isLiked: originalIsLiked,
            likesCount: originalLikesCount,
          );
        });
        
        // Show professional error message
        NetworkErrorHandler.showErrorSnackbar(
          context,
          e,
          onRetry: _handleLike,
        );
      }
    }
  }

  Future<void> _handleSave() async {
    // Check authentication
    if (AuthService.currentUser == null) {
      _showLoginPrompt('save this post');
      return;
    }
    
    final success = await BusinessNetworkService.toggleSave(_post.id, _post.isSaved);
    
    if (success && mounted) {
      setState(() {
        _post = _post.copyWith(
          isSaved: !_post.isSaved,
        );
      });

      widget.onSaveChanged?.call(_post.id, _post.isSaved);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_post.isSaved ? 'Post saved' : 'Post unsaved'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleFollowToggle() async {
    // Check if we have the user UUID
    if (_post.user.uuid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to follow user'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await BusinessNetworkService.toggleFollow(
      _post.user.uuid!,
      _post.user.isFollowing,
    );
    
    if (success && mounted) {
      setState(() {
        // Create updated user with toggled follow status
        final updatedUser = BusinessNetworkUser(
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
          isFollowing: !_post.user.isFollowing,
        );
        
        _post = _post.copyWith(user: updatedUser);
      });
    }
  }

  void _showPostOptions() {
    final isSelf = _isSelfPost();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Options for own posts
              if (isSelf) ...[
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleEditPost();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _handleDeletePost();
                  },
                ),
              ],
              // Options for public posts
              if (!isSelf) ...[
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.orange),
                  title: const Text('Report'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleReportPost();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.visibility_off, color: Colors.grey),
                  title: const Text('Hide'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleHidePost();
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _handleEditPost() {
    // TODO: Navigate to edit post screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit post feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleDeletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await BusinessNetworkService.deletePost(_post.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onPostDeleted?.call();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete post'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleReportPost() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why are you reporting this post?'),
            const SizedBox(height: 16),
            _buildReportOption('Spam or misleading'),
            _buildReportOption('Harassment or hate speech'),
            _buildReportOption('Violence or dangerous content'),
            _buildReportOption('Inappropriate content'),
            _buildReportOption('Other'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOption(String reason) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _submitReport(reason);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          reason,
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  Future<void> _submitReport(String reason) async {
    final success = await BusinessNetworkService.reportPost(_post.id, reason);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post reported: $reason'),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to report post'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleHidePost() async {
    final success = await BusinessNetworkService.hidePost(_post.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post hidden from your feed'),
          duration: Duration(seconds: 2),
        ),
      );
      widget.onPostDeleted?.call(); // Remove from feed
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to hide post'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          PostHeader(
            post: _post,
            onFollowToggle: null, // Don't show follow button in posts
            onMorePressed: _showPostOptions,
          ),
          // Post Media Gallery (Vue-style: media on top)
          if (_post.media.isNotEmpty)
            PostMediaGallery(
              media: _post.media,
              onMediaTap: _handleMediaTap,
            ),
          // Post Title
          if (_post.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: GestureDetector(
                onTap: _handleViewAllComments,
                child: Text(
                  _post.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          // Post Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Html(
                  data: _showFullContent ? _post.content : (_post.content.length > 160 ? '${_post.content.substring(0, 160)}...' : _post.content),
                  onLinkTap: (url, attributes, element) {
                    UrlLauncherUtils.launchExternalUrl(url);
                  },
                ),
                FirstLinkPreview(text: _post.content),
                if (_post.content.length > 160)
                  TextButton(
                    onPressed: () {
                      setState(() => _showFullContent = !_showFullContent);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _showFullContent ? 'Read less' : 'Read more',
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Post Tags
          if (_post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _post.tags.map((tag) {
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchScreen(
                            initialQuery: '#${tag.tag}',
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#${tag.tag}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          // Post Actions (moved below title, content, and hashtags)
          PostActions(
            post: _post,
            onLike: _handleLike,
            onComment: _handleViewAllComments,
            onShare: _handleShare,
            onSave: _handleSave,
          ),
          // Comments Preview
          PostCommentsPreview(
            post: _post,
            onViewAll: _handleViewAllComments,
            onCommentCountChanged: () {
              setState(() {
                _post = _post.copyWith(
                  commentsCount: _post.commentsCount > 0 ? _post.commentsCount - 1 : 0,
                );
              });
            },
            onReplySubmit: (comment, content) async {
              if (_isAddingComment) return;
              
              setState(() => _isAddingComment = true);
              
              // Don't add automatic @mention - user can type @ if they want
              final newComment = await BusinessNetworkService.addComment(
                postId: _post.id,
                content: content,
                parentCommentId: comment.id,
              );
              
              if (newComment != null && mounted) {
                // Just add the new comment to existing list instead of reloading
                // This prevents losing parent comments when API returns incomplete data
                print('=== Adding Reply to Post ===');
                print('Current comments count: ${_post.comments.length}');
                print('Parent comment ID: ${comment.id}');
                print('New reply ID: ${newComment.id}');
                print('Comments before add:');
                for (var c in _post.comments) {
                  print('  - Comment ${c.id}: parentComment=${c.parentComment}');
                }
                
                setState(() {
                  // Create a completely new immutable list
                  final updatedComments = List<BusinessNetworkComment>.from(_post.comments)
                    ..add(newComment);
                  
                  _post = _post.copyWith(
                    commentsCount: _post.commentsCount + 1,
                    comments: updatedComments,
                  );
                  _isAddingComment = false;
                });
                
                print('Comments after add:');
                for (var c in _post.comments) {
                  print('  - Comment ${c.id}: parentComment=${c.parentComment}');
                }
                print('Post comments list identity: ${_post.comments.hashCode}');
                print('Post object identity: ${_post.hashCode}');
                
                widget.onCommentAdded?.call(newComment);
              } else if (mounted) {
                setState(() => _isAddingComment = false);
              }
            },
          ),
          // Add Comment Input
          PostCommentInput(
            onSubmit: _addComment,
            userAvatar: AuthService.currentUser?.profilePicture,
            postId: _post.id.toString(),
            postAuthorId: _post.user.uuid ?? _post.user.id.toString(),
            postAuthorName: _post.user.name,
            onGiftSent: () async {
              // Small delay to allow UI to update smoothly
              await Future.delayed(const Duration(milliseconds: 100));
              
              // Reload post data to show new gift comment
              final updatedPost = await BusinessNetworkService.getPost(_post.id);
              if (updatedPost != null && mounted) {
                setState(() {
                  _post = updatedPost;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
