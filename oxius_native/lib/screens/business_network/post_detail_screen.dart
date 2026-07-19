import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import '../../services/auth_service.dart';
import '../../config/app_config.dart';
import '../../widgets/business_network/post_media_gallery.dart';
import '../../widgets/business_network/reshared_post_card.dart';
import '../../widgets/business_network/reshared_news_card.dart';
import '../news_detail_screen.dart';
import 'shorts_viewer.dart';
import '../../widgets/business_network/post_actions.dart';
import '../../widgets/business_network/post_comment_input.dart';
import '../../widgets/business_network/post_comments_preview.dart';
import '../../utils/time_utils.dart';
import '../../utils/html_content_utils.dart';
import '../../utils/url_launcher_utils.dart';
import '../../widgets/common/adsy_share_sheet.dart';
import 'post_media_viewer_screen.dart';
import 'profile_screen.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

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
        // Keep the reshare data the feed already handed us if the refetch
        // comes back without it — otherwise the embedded original silently
        // disappears on the detail screen.
        _post = fullPost.sharedFrom == null && widget.post.sharedFrom != null
            ? fullPost.copyWith(sharedFrom: widget.post.sharedFrom)
            : fullPost;
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
          likesCount:
              _post.isLiked ? _post.likesCount - 1 : _post.likesCount + 1,
        );
      });
    }

    // Make API call
    final success =
        await BusinessNetworkService.toggleLike(_post.id, originalIsLiked);

    _isLiking = false;

    if (!success && mounted) {
      // Failed - rollback to original state
      setState(() {
        _post = _post.copyWith(
          isLiked: originalIsLiked,
          likesCount: originalLikesCount,
        );
      });

      AdsyToast.error(
          context, 'Failed to ${originalIsLiked ? 'unlike' : 'like'} post');
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
    final plainPostContent = HtmlContentUtils.toPlainText(_post.content);
    await AdsyShareSheet.show(
      context,
      data: AdsyShareData(
        title: '${_post.user.name} on Business Network',
        description: HtmlContentUtils.previewText(plainPostContent, 140),
        url:
            'https://adsyclub.com/business-network/posts/${_post.slug.isNotEmpty ? _post.slug : _post.id}',
        // Text-only posts share with NO thumb (clean text-only chat card).
        imageUrl:
            _post.shareThumbUrl.isNotEmpty ? _post.shareThumbUrl : null,
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
        // Same repost-to-profile composer as the feed's post card.
        onRepost: (caption) async {
          if (!AuthService.isAuthenticated) return false;
          final targetId = _post.sharedFrom?.id ?? _post.id;
          final result = await BusinessNetworkService.resharePost(
            targetId,
            caption: caption,
          );
          if (result != null && mounted) {
            setState(() =>
                _post = _post.copyWith(shareCount: _post.shareCount + 1));
          }
          return result != null;
        },
      ),
    );
  }

  Future<void> _handleSave() async {
    final success =
        await BusinessNetworkService.toggleSave(_post.id, _post.isSaved);

    if (success && mounted) {
      setState(() {
        _post = _post.copyWith(
          isSaved: !_post.isSaved,
        );
      });

      AdsyToast.success(
          context, _post.isSaved ? 'Post saved' : 'Post unsaved');
    }
  }

  void _handleMediaTap(int index) {
    // ignore: discarded_futures
    _openMediaViewer(index);
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

  // ---- Reshared original (embedded) navigation ------------------------------
  void _openSharedAuthor(SharedPostPreview orig) {
    if (orig.authorId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: orig.authorId)),
    );
  }

  Future<void> _openSharedPostDetail(SharedPostPreview orig) async {
    final ident = orig.slug.isNotEmpty ? orig.slug : orig.id.toString();
    final post = await BusinessNetworkService.getPostByIdentifier(ident);
    if (!mounted || post == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
    );
  }

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

  Future<void> _handleFollowToggle() async {
    // Use user UUID or username for follow action
    final userId =
        _post.user.uuid ?? _post.user.username ?? _post.user.id.toString();

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
    final success =
        await BusinessNetworkService.toggleFollow(userId, wasFollowing);

    if (success && mounted) {
      AdsyToast.info(
          context,
          _post.user.isFollowing
              ? 'Following ${_post.user.name}'
              : 'Unfollowed ${_post.user.name}');
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

      AdsyToast.error(context,
          'Failed to ${wasFollowing ? 'unfollow' : 'follow'} ${_post.user.name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<BusinessNetworkPost>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, BusinessNetworkPost? result) {
        if (didPop) return;
        Navigator.pop(context, _post);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: () {
                                  final rawAvatarUrl =
                                      _post.user.image ?? _post.user.avatar;
                                  final avatarUrl =
                                      AppConfig.getAbsoluteUrl(rawAvatarUrl);

                                  if (avatarUrl.isNotEmpty) {
                                    return Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
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
                child: AdsyRefreshIndicator(
                  onRefresh: _loadFullPost,
                  color: const Color(0xFF3B82F6),
                  child: _isLoading
                      ? const Center(
                          child: AdsyLoadingIndicator(),
                        )
                      : SingleChildScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 672),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Post Content — title removed from design.
                                // Explicit type scale: the Html default body
                                // (~14px + its own margins) read small and
                                // doubled the side padding.
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 14, 12, 0),
                                  child: Html(
                                    data: HtmlContentUtils.toDisplayHtml(
                                        _post.content),
                                    onLinkTap: (url, attributes, element) {
                                      UrlLauncherUtils.launchExternalUrl(url);
                                    },
                                    style: {
                                      "body": Style(
                                        fontSize: FontSize(16),
                                        lineHeight: const LineHeight(1.6),
                                        color: const Color(0xFF1F2937),
                                        margin: Margins.zero,
                                      ),
                                      "a": Style(
                                        color: const Color(0xFF2563EB),
                                        textDecoration: TextDecoration.none,
                                      ),
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

                                // Reshared original — same card as the feed so
                                // the shared items always show here too.
                                if (_post.sharedFrom != null)
                                  ResharedPostCard(
                                    shared: _post.sharedFrom!,
                                    onAuthorTap: () =>
                                        _openSharedAuthor(_post.sharedFrom!),
                                    onOpenPost: () =>
                                        _openSharedPostDetail(_post.sharedFrom!),
                                    onOpenVideo: () => _openSharedVideoInShorts(
                                        _post.sharedFrom!),
                                  ),

                                // Reshared news story — same card as the feed.
                                if (_post.sharedNews != null)
                                  ResharedNewsCard(
                                    news: _post.sharedNews!,
                                    onOpen: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => NewsDetailScreen(
                                            slug: _post.sharedNews!.slug),
                                      ),
                                    ),
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

                                const SizedBox(
                                    height: 80), // Space for bottom input
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
      ),
    );
  }

  Widget _buildUnifiedCommentsSection() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: AdsyLoadingIndicator(strokeWidth: 2),
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
      padding: const EdgeInsets.only(left: 0, right: 0, top: 4),
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
              commentsCount:
                  _post.commentsCount > 0 ? _post.commentsCount - 1 : 0,
            );
          });
        },
      ),
    );
  }
}
