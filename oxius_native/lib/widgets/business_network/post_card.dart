import 'dart:async';

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
import 'reshared_post_card.dart';
import 'reshared_news_card.dart';
import '../../screens/news_detail_screen.dart';
import 'post_actions.dart';
import 'post_comments_preview.dart';
import 'post_comment_input.dart';
import '../../screens/business_network/post_media_viewer_screen.dart';
import '../../screens/business_network/shorts_player_screen.dart';
import '../../screens/business_network/shorts_viewer.dart';

class PostCard extends StatefulWidget {
  final BusinessNetworkPost post;
  final void Function(BusinessNetworkPost updatedPost)? onPostUpdated;
  final Function(BusinessNetworkComment)? onCommentAdded;
  final VoidCallback? onPostDeleted;
  final void Function(String userId)? onUserBlocked;
  final void Function(int postId, bool isSaved)? onSaveChanged;
  // Called with the new reshare post so the feed can prepend it without reload.
  final void Function(BusinessNetworkPost reshared)? onReshared;

  const PostCard({
    super.key,
    required this.post,
    this.onPostUpdated,
    this.onCommentAdded,
    this.onPostDeleted,
    this.onUserBlocked,
    this.onSaveChanged,
    this.onReshared,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late BusinessNetworkPost _post;
  bool _isAddingComment = false;
  bool _showFullContent = false;
  // Hidden by the viewer — the card renders as an inline undo strip.
  bool _isHidden = false;
  bool _isLiking = false; // Prevent double-clicking
  // Live share-count updates (shares made from shorts/detail/anywhere reach
  // this card without a feed reload).
  StreamSubscription<MapEntry<int, int>>? _shareCountSub;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _shareCountSub = BusinessNetworkService.shareCountUpdates.listen((e) {
      // Shares on a reshare are tracked against the ORIGINAL post id.
      if (!mounted) return;
      if (e.key == (_post.sharedFrom?.id ?? _post.id)) {
        setState(() => _post = _post.copyWith(shareCount: e.value));
      }
    });
  }

  @override
  void dispose() {
    _shareCountSub?.cancel();
    super.dispose();
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

  // Embedded card showing the original post inside a reshare/repost.
  void _openSharedAuthor(SharedPostPreview orig) {
    if (orig.authorId.isEmpty) return;
    Navigator.pushNamed(
      context,
      '/business-network/profile',
      arguments: {'userId': orig.authorId},
    );
  }

  // Tap a shared video → open it full-screen in the Shorts player (with the
  // original owner's details), like other social apps.
  Future<void> _openSharedVideoInShorts(SharedPostPreview orig) async {
    final ident = orig.slug.isNotEmpty ? orig.slug : orig.id.toString();
    final post = await BusinessNetworkService.getPostByIdentifier(ident);
    if (!mounted || post == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          body: ShortsViewer(
            posts: [post],
            onClose: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
    );
  }

  // "আরও পড়ুন" on a reshared post → open the original post's detail screen.
  Future<void> _openSharedPostDetail(SharedPostPreview orig) async {
    final ident = orig.slug.isNotEmpty ? orig.slug : orig.id.toString();
    final post = await BusinessNetworkService.getPostByIdentifier(ident);
    if (!mounted || post == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
    );
  }

  Widget _buildResharedOriginal(SharedPostPreview orig) {
    // Single reusable card so the feed and the post-detail screen render the
    // reshared original identically (full media gallery, same tap behaviour).
    return ResharedPostCard(
      shared: orig,
      onAuthorTap: () => _openSharedAuthor(orig),
      onOpenPost: () => _openSharedPostDetail(orig),
      onOpenVideo: () => _openSharedVideoInShorts(orig),
    );
  }

  // Rounded overlapping avatars of who liked the post — mutual connections
  // (people the viewer follows) are ordered first, then a "+N more" count.
  Widget _buildLikedByRow() {
    final total = _post.likesCount;
    if (total <= 0) return const SizedBox.shrink();

    // Prefer the compact server preview (mutual-first); fall back to the full
    // postLikes array (present only on the detail screen).
    List<String> faceUrls;
    if (_post.likedByPreview.isNotEmpty) {
      faceUrls = _post.likedByPreview
          .where((f) => (f.image ?? '').isNotEmpty)
          .map((f) => f.image!)
          .toList();
    } else {
      final likes = [..._post.postLikes]
        ..sort((a, b) =>
            a.isFollowing == b.isFollowing ? 0 : (a.isFollowing ? -1 : 1));
      faceUrls = likes
          .where((l) => (l.userImage ?? '').isNotEmpty)
          .map((l) => l.userImage!)
          .toList();
    }
    final shown = faceUrls.take(5).toList();

    const double size = 24;
    const double overlap = 16;

    // Professional, human label: "<name> ও আরও N জন এই পোস্টটি পছন্দ করেছেন".
    final firstName = _post.likedByPreview.isNotEmpty
        ? _post.likedByPreview.first.name
        : (_post.postLikes.isNotEmpty ? _post.postLikes.first.userName : '');
    final String likeLabel = firstName.trim().isNotEmpty
        ? (total > 1
            ? '$firstName ও আরও ${total - 1} জন এই পোস্টটি পছন্দ করেছেন'
            : '$firstName এই পোস্টটি পছন্দ করেছেন')
        : '$total জন এই পোস্টটি পছন্দ করেছেন';

    if (shown.isEmpty) {
      // Have a count but no avatars loaded — show a plain count.
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
        child: Text(
          likeLabel,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => showPostLikers(
        context,
        likes: _post.postLikes,
        postId: _post.id,
        likesCount: _post.likesCount,
      ),
      child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
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
                          AppConfig.getAbsoluteUrl(shown[i]),
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
              likeLabel,
              maxLines: 2,
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
        // Count non-repost shares (chat / external) and bump the badge.
        onShared: () {
          BusinessNetworkService.trackShare(_post.sharedFrom?.id ?? _post.id);
          if (mounted) {
            setState(() =>
                _post = _post.copyWith(shareCount: _post.shareCount + 1));
          }
        },
        // Repost-to-profile composer inside the share sheet.
        onRepost: (caption) async {
          if (!AuthService.isAuthenticated) {
            _showLoginPrompt('repost');
            return false;
          }
          final targetId = _post.sharedFrom?.id ?? _post.id;
          final result = await BusinessNetworkService.resharePost(
            targetId,
            caption: caption,
          );
          if (result != null) {
            // Prepend the fresh repost to the feed (no reload).
            widget.onReshared?.call(result);
            if (mounted) {
              setState(() =>
                  _post = _post.copyWith(shareCount: _post.shareCount + 1));
            }
            return true;
          }
          return false;
        },
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
        final isReshare = _post.sharedFrom != null;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (_post.media.isNotEmpty)
                _menuTile(
                  icon: Icons.download_rounded,
                  color: const Color(0xFF3B82F6),
                  title: _downloadMenuTitle(),
                  onTap: _handleDownloadMedia,
                ),
              // Reshares hide Save in the actions row — offer it here instead.
              if (isReshare)
                _menuTile(
                  icon:
                      _post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: const Color(0xFF7C3AED),
                  title: _post.isSaved ? 'Unsave' : 'Save',
                  subtitle: 'পরে দেখার জন্য সেভ করুন',
                  onTap: _handleSave,
                ),
              if (isSelf) ...[
                _menuTile(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF2563EB),
                  title: 'Edit post',
                  onTap: _handleEditPost,
                ),
                _menuTile(
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFDC2626),
                  title: 'Delete post',
                  danger: true,
                  onTap: _handleDeletePost,
                ),
              ],
              if (!isSelf) ...[
                _menuTile(
                  icon: Icons.share_outlined,
                  color: const Color(0xFF3B82F6),
                  title: 'Share post',
                  onTap: _handleShare,
                ),
                _menuTile(
                  icon: Icons.flag_outlined,
                  color: const Color(0xFFEA580C),
                  title: 'Report',
                  onTap: _handleReportPost,
                ),
                _menuTile(
                  icon: Icons.visibility_off_outlined,
                  color: const Color(0xFF64748B),
                  title: 'Hide this post',
                  onTap: _handleHidePost,
                ),
                _menuTile(
                  icon: Icons.block_rounded,
                  color: const Color(0xFFDC2626),
                  title: 'Block user',
                  danger: true,
                  onTap: _handleBlockUser,
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _menuTile({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    bool danger = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: danger
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 11.5, color: Color(0xFF94A3B8)),
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
        // Send the backend code (option.value) like every other report flow —
        // sending the label made reasons silently degrade to 'other'.
        return BusinessNetworkService.reportPost(_post.id, option.value);
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
      // Swap the card for an inline undo strip instead of vanishing — a
      // mis-tap would otherwise lose the post with no way back.
      setState(() => _isHidden = true);
    } else if (mounted) {
      AdsyToast.error(context, 'Failed to hide post');
    }
  }

  Future<void> _handleUnhidePost() async {
    final success = await BusinessNetworkService.unhidePost(_post.id);
    if (success && mounted) {
      setState(() => _isHidden = false);
    } else if (mounted) {
      AdsyToast.error(context, 'আনডু করা যায়নি, আবার চেষ্টা করুন');
    }
  }

  // Compact strip shown in place of a hidden post.
  Widget _buildHiddenCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_off_outlined,
              size: 20, color: Color(0xFF64748B)),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'পোস্টটি সরিয়ে নেওয়া হয়েছে',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'এই পোস্টটি আপনার ফিডে আর দেখা যাবে না',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _handleUnhidePost,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'আনডু',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isHidden) return _buildHiddenCard();

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
                              fontSize: 16,
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
          // Embedded original when this post is a reshare/repost.
          if (_post.sharedFrom != null) _buildResharedOriginal(_post.sharedFrom!),
          // Embedded news story when this post is a news reshare.
          if (_post.sharedNews != null)
            ResharedNewsCard(
              news: _post.sharedNews!,
              onOpen: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewsDetailScreen(slug: _post.sharedNews!.slug),
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
            // Reshares move Save into the ⋯ menu to keep the row uncluttered.
            onSave: _post.sharedFrom != null ? null : _handleSave,
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
