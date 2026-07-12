import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_config.dart';
import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import '../../services/auth_service.dart';
import '../../screens/business_network/post_detail_screen.dart';
import '../../screens/business_network/edit_post_screen.dart';
import '../../screens/business_network/search_screen.dart';
import '../../utils/network_error_handler.dart';
import '../../utils/html_content_utils.dart';
import '../../utils/mention_parser.dart';
import '../../utils/mention_navigator.dart';
import '../../utils/business_network_media_downloader.dart';
import '../../widgets/link_preview_card.dart';
import '../../widgets/login_prompt_dialog.dart';
import '../../widgets/common/adsy_report_sheet.dart';
import '../../widgets/common/adsy_share_sheet.dart';
import '../../widgets/common/adsy_toast.dart';
import 'post_header.dart';
import 'post_media_gallery.dart';
import 'post_actions.dart';
import 'post_comments_preview.dart';
import 'post_comment_input.dart';
import '../../screens/business_network/post_media_viewer_screen.dart';
import '../../screens/business_network/shorts_player_screen.dart';

class PostCard extends StatefulWidget {
  final BusinessNetworkPost post;
  final void Function(BusinessNetworkPost updatedPost)? onPostUpdated;
  final Function(BusinessNetworkComment)? onCommentAdded;
  final VoidCallback? onPostDeleted;
  final void Function(String userId)? onUserBlocked;
  final void Function(int postId, bool isSaved)? onSaveChanged;

  const PostCard({
    super.key,
    required this.post,
    this.onPostUpdated,
    this.onCommentAdded,
    this.onPostDeleted,
    this.onUserBlocked,
    this.onSaveChanged,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late BusinessNetworkPost _post;
  bool _isAddingComment = false;
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
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.isLiked != widget.post.isLiked ||
        oldWidget.post.isSaved != widget.post.isSaved ||
        oldWidget.post.likesCount != widget.post.likesCount ||
        oldWidget.post.commentsCount != widget.post.commentsCount) {
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

  Future<void> _handleMentionTap(String mentionName) async {
    // Exact-match resolution with an ambiguity chooser — never navigates to
    // a random same-named profile (the old `results.first` bug).
    await MentionNavigator.open(context, mentionName);
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
      final updates = await Navigator.push<Map<int, BusinessNetworkPost>?>(
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
    LoginPromptDialog.show(context, action: action);
  }

  // Rounded overlapping avatars of who liked the post — mutual connections
  // (people the viewer follows) are ordered first, then a "+N more" count.
  Widget _buildLikedByRow() {
    final total = _post.likesCount;
    if (total <= 0) return const SizedBox.shrink();

    final likes = [..._post.postLikes];
    // Mutual (followed) likers first.
    likes.sort((a, b) => a.isFollowing == b.isFollowing
        ? 0
        : (a.isFollowing ? -1 : 1));
    final withImage =
        likes.where((l) => (l.userImage ?? '').isNotEmpty).toList();
    final shown = withImage.take(7).toList();

    const double size = 24;
    const double overlap = 16;
    final int extra = total - shown.length;

    if (shown.isEmpty) {
      // Have a count but no avatars loaded — show a plain count.
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
        child: Text(
          '$total ${total == 1 ? 'like' : 'likes'}',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: Row(
        children: [
          SizedBox(
            height: size,
            width: size + (shown.length - 1) * overlap,
            child: Stack(
              children: [
                for (int i = 0; i < shown.length; i++)
                  Positioned(
                    left: i * overlap,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.6),
                        color: const Color(0xFFE2E8F0),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          AppConfig.getAbsoluteUrl(shown[i].userImage!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              size: 15,
                              color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              extra > 0
                  ? '+$extra more'
                  : '$total ${total == 1 ? 'like' : 'likes'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleShare() async {
    final plainPostContent = HtmlContentUtils.toPlainText(_post.content);
    await AdsyShareSheet.show(
      context,
      data: AdsyShareData(
        title: '${_post.user.name} on Business Network',
        description: HtmlContentUtils.previewText(plainPostContent, 140),
        url:
            'https://adsyclub.com/business-network/posts/${_post.slug.isNotEmpty ? _post.slug : _post.id}',
        imageUrl: _post.media.isNotEmpty
            ? _post.media.first.bestThumbnailUrl
            : _post.user.image ?? _post.user.avatar,
        subject: 'Business Network Post',
        eyebrow: 'Business Network',
        hashtags: _post.tags.map((tag) => tag.tag).toList(),
      ),
    );
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
      final updated = _post.copyWith(
        isLiked: !originalIsLiked,
        likesCount:
            originalIsLiked ? originalLikesCount - 1 : originalLikesCount + 1,
      );
      setState(() {
        _post = updated;
      });
      widget.onPostUpdated?.call(updated);
    }

    // Make API call
    try {
      await BusinessNetworkService.toggleLike(_post.id, originalIsLiked);
      _isLiking = false;
      widget.onPostUpdated?.call(_post);
    } catch (e) {
      _isLiking = false;

      // Failed - rollback to original state
      if (mounted) {
        final rolledBack = _post.copyWith(
          isLiked: originalIsLiked,
          likesCount: originalLikesCount,
        );
        setState(() {
          _post = rolledBack;
        });
        widget.onPostUpdated?.call(rolledBack);

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

    final originalIsSaved = _post.isSaved;
    final updated = _post.copyWith(isSaved: !originalIsSaved);

    if (mounted) {
      setState(() {
        _post = updated;
      });
      widget.onPostUpdated?.call(updated);
    }

    final success =
        await BusinessNetworkService.toggleSave(_post.id, originalIsSaved);

    if (success && mounted) {
      widget.onSaveChanged?.call(_post.id, _post.isSaved);

      AdsyToast.success(context, _post.isSaved ? 'Post saved' : 'Post unsaved');
    } else if (!success && mounted) {
      final rolledBack = _post.copyWith(isSaved: originalIsSaved);
      setState(() {
        _post = rolledBack;
      });
      widget.onPostUpdated?.call(rolledBack);
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
              if (_post.media.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.download_rounded,
                      color: Color(0xFF3B82F6)),
                  title: Text(_downloadMenuTitle()),
                  onTap: () {
                    Navigator.pop(context);
                    _handleDownloadMedia();
                  },
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
                  title:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _handleDeletePost();
                  },
                ),
              ],
              // Options for public posts
              if (!isSelf) ...[
                ListTile(
                  leading: const Icon(Icons.share_outlined,
                      color: Color(0xFF3B82F6)),
                  title: const Text('Share Post'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleShare();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.orange),
                  title: const Text('Report'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleReportPost();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text('Block User',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _handleBlockUser();
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

  String _downloadMenuTitle() {
    if (_post.media.length > 1) return 'Download Media';
    return _post.media.first.isVideo ? 'Download Video' : 'Download Photo';
  }

  Future<void> _handleDownloadMedia() async {
    if (_post.media.length == 1) {
      await BusinessNetworkMediaDownloader.download(
        context,
        _post.media.first,
        ownerName: _post.user.name,
      );
      return;
    }

    final selectedMedia = await showModalBottomSheet<PostMedia>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              for (var i = 0; i < _post.media.length; i++)
                ListTile(
                  leading: Icon(
                    _post.media[i].isVideo
                        ? Icons.videocam_rounded
                        : Icons.image_rounded,
                    color: const Color(0xFF3B82F6),
                  ),
                  title: Text(
                    '${_post.media[i].isVideo ? 'Video' : 'Photo'} ${i + 1}',
                  ),
                  trailing: const Icon(Icons.download_rounded),
                  onTap: () => Navigator.pop(context, _post.media[i]),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selectedMedia == null || !mounted) return;
    await BusinessNetworkMediaDownloader.download(
      context,
      selectedMedia,
      ownerName: _post.user.name,
    );
  }

  Future<void> _handleEditPost() async {
    final updatedPost = await Navigator.push<BusinessNetworkPost>(
      context,
      MaterialPageRoute(
        builder: (context) => EditPostScreen(post: _post),
      ),
    );

    if (updatedPost != null && mounted) {
      setState(() {
        _post = updatedPost;
      });
      widget.onPostUpdated?.call(updatedPost);
      AdsyToast.success(context, 'Post updated');
    }
  }

  Future<void> _handleDeletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
            'Are you sure you want to delete this post? This action cannot be undone.'),
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
        AdsyToast.success(context, 'Post deleted successfully');
        widget.onPostDeleted?.call();
      } else if (mounted) {
        AdsyToast.error(context, 'Failed to delete post');
      }
    }
  }

  void _handleReportPost() {
    AdsyReportSheet.show(
      context,
      title: 'Report Post',
      prompt: 'Why are you reporting this post?',
      options: const [
        AdsyReportOption(label: 'Spam or misleading', value: 'spam'),
        AdsyReportOption(
            label: 'Harassment or hate speech', value: 'harassment'),
        AdsyReportOption(
            label: 'Violence or dangerous content', value: 'violence'),
        AdsyReportOption(
            label: 'Inappropriate content', value: 'inappropriate'),
        AdsyReportOption(label: 'Other', value: 'other'),
      ],
      successMessage: 'Post reported. We will review it shortly.',
      onSubmit: (option, details) {
        return BusinessNetworkService.reportPost(_post.id, option.label);
      },
    );
  }

  Future<void> _handleBlockUser() async {
    // Prefer UUID (the User PK on the backend); username is only used for display.
    final userId = _post.user.uuid ?? _post.user.id.toString();
    final username = _post.user.username;
    if (userId.isEmpty) {
      if (mounted) {
        AdsyToast.error(context, 'Cannot block this user');
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          username != null && username.isNotEmpty
              ? 'Block @$username? You will no longer see their posts.'
              : 'Block ${_post.user.name}? You will no longer see their posts.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await BusinessNetworkService.blockUser(userId);
    if (mounted) {
      if (success) {
        AdsyToast.success(context, 'User blocked');
      } else {
        AdsyToast.error(context, 'Failed to block user');
      }
      if (success) {
        widget.onUserBlocked?.call(userId);
        widget.onPostDeleted?.call(); // Remove post from feed
      }
    }
  }

  Future<void> _handleHidePost() async {
    final success = await BusinessNetworkService.hidePost(_post.id);

    if (success && mounted) {
      AdsyToast.info(context, 'Post hidden from your feed');
      widget.onPostDeleted?.call(); // Remove from feed
    } else if (mounted) {
      AdsyToast.error(context, 'Failed to hide post');
    }
  }

  @override
  Widget build(BuildContext context) {
    final plainPostContent = HtmlContentUtils.toPlainText(_post.content);
    final previewPostContent = _showFullContent
        ? plainPostContent
        : HtmlContentUtils.previewText(plainPostContent, 160);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
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
            onFollowToggle: null, // Don't show follow button in posts
            onMorePressed: _showPostOptions,
          ),
          // Post Media Gallery (Vue-style: media on top)
          if (_post.media.isNotEmpty)
            PostMediaGallery(
              media: _post.media,
              onMediaTap: _handleMediaTap,
            ),
          // Post Content with long press copy (title removed from design)
          if (plainPostContent.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: plainPostContent));
                      AdsyToast.success(context, 'Content copied to clipboard');
                    },
                    child: Text.rich(
                      TextSpan(
                        children: [
                          ...MentionParser.parseTextWithMentions(
                            previewPostContent,
                            context,
                            onMentionTap: _handleMentionTap,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF111827),
                              height: 1.55,
                            ),
                          ),
                          if (plainPostContent.length > 160)
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() =>
                                      _showFullContent = !_showFullContent);
                                },
                                child: Text(
                                  _showFullContent
                                      ? '  কম পড়ুন'
                                      : '  আরো পড়ুন',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6366F1),
                                    height: 1.55,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  FirstLinkPreview(text: plainPostContent),
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
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '#${tag.tag}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          // Post Actions (moved below title, content, and hashtags)
          Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
          PostActions(
            post: _post,
            onLike: _handleLike,
            onComment: _handleViewAllComments,
            onShare: _handleShare,
            onSave: _handleSave,
          ),
          // Liked-by faces (mutual connections first)
          _buildLikedByRow(),
          // Comments Preview
          PostCommentsPreview(
            post: _post,
            onViewAll: _handleViewAllComments,
            onCommentCountChanged: () {
              setState(() {
                _post = _post.copyWith(
                  commentsCount:
                      _post.commentsCount > 0 ? _post.commentsCount - 1 : 0,
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
                debugPrint('=== Adding Reply to Post ===');
                debugPrint('Current comments count: ${_post.comments.length}');
                debugPrint('Parent comment ID: ${comment.id}');
                debugPrint('New reply ID: ${newComment.id}');
                debugPrint('Comments before add:');
                for (var c in _post.comments) {
                  debugPrint(
                      '  - Comment ${c.id}: parentComment=${c.parentComment}');
                }

                setState(() {
                  // Create a completely new immutable list
                  final updatedComments =
                      List<BusinessNetworkComment>.from(_post.comments)
                        ..add(newComment);

                  _post = _post.copyWith(
                    commentsCount: _post.commentsCount + 1,
                    comments: updatedComments,
                  );
                  _isAddingComment = false;
                });

                debugPrint('Comments after add:');
                for (var c in _post.comments) {
                  debugPrint(
                      '  - Comment ${c.id}: parentComment=${c.parentComment}');
                }
                debugPrint(
                    'Post comments list identity: ${_post.comments.hashCode}');
                debugPrint('Post object identity: ${_post.hashCode}');

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
              final updatedPost =
                  await BusinessNetworkService.getPost(_post.id);
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
