import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import '../../screens/business_network/post_detail_screen.dart';
import 'post_header.dart';
import 'post_media_gallery.dart';
import 'post_actions.dart';
import 'post_comments_preview.dart';
import 'post_comment_input.dart';

class PostCard extends StatefulWidget {
  final BusinessNetworkPost post;
  final VoidCallback? onLikeToggle;
  final Function(BusinessNetworkComment)? onCommentAdded;
  final VoidCallback? onPostDeleted;

  const PostCard({
    super.key,
    required this.post,
    this.onLikeToggle,
    this.onCommentAdded,
    this.onPostDeleted,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late BusinessNetworkPost _post;
  bool _showFullContent = false;
  bool _isAddingComment = false;

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

  Future<void> _addComment(String content) async {
    if (_isAddingComment) return;

    setState(() => _isAddingComment = true);

    final comment = await BusinessNetworkService.addComment(
      postId: _post.id,
      content: content,
    );

    if (comment != null && mounted) {
      // Update local post state to show new comment immediately
      setState(() {
        _post = _post.copyWith(
          commentsCount: _post.commentsCount + 1,
          comments: [..._post.comments, comment],
        );
        _isAddingComment = false;
      });
      
      // Also notify parent widget
      widget.onCommentAdded?.call(comment);
    } else if (mounted) {
      setState(() => _isAddingComment = false);
    }
  }

  void _handleMediaTap(int index) {
    // TODO: Open media viewer
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Image.network(
                _post.media[index].image,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleViewAllComments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(post: _post),
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
      
      // Add post link (you can customize this URL)
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
            onFollowToggle: _handleFollowToggle,
            onMorePressed: () {
              // TODO: Show options menu
            },
          ),
          // Post Title
          if (_post.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                _post.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
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
                  return Container(
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
                  );
                }).toList(),
              ),
            ),
          // Post Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _post.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                  maxLines: _showFullContent ? null : 4,
                  overflow: _showFullContent ? null : TextOverflow.ellipsis,
                ),
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
          // Post Media Gallery
          if (_post.media.isNotEmpty)
            PostMediaGallery(
              media: _post.media,
              onMediaTap: _handleMediaTap,
            ),
          // Post Actions
          PostActions(
            post: _post,
            onLike: widget.onLikeToggle ?? () {},
            onComment: _handleViewAllComments,
            onShare: _handleShare,
            onSave: _handleSave,
          ),
          // Comments Preview
          PostCommentsPreview(
            post: _post,
            onViewAll: _handleViewAllComments,
            onReply: (comment) {
              // Navigate to post detail screen when replying
              _handleViewAllComments();
            },
          ),
          // Add Comment Input
          PostCommentInput(
            onSubmit: _addComment,
            userAvatar: null, // TODO: Get current user avatar
          ),
        ],
      ),
    );
  }
}
