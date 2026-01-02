import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import '../../services/auth_service.dart';
import '../../config/app_config.dart';
import '../../utils/network_error_handler.dart';
import '../../widgets/business_network/post_comment_input.dart';
import '../../widgets/business_network/post_comments_preview.dart';
import '../../widgets/business_network/diamond_gift_bottom_sheet.dart';

class ShortsViewer extends StatefulWidget {
  final List<BusinessNetworkPost> posts;
  final VoidCallback onClose;
  final void Function(BusinessNetworkPost post)? onLike;
  final void Function(BusinessNetworkPost post)? onComment;
  final void Function(BusinessNetworkPost post)? onShare;
  final String? initialVideoUrl;
  final Future<void> Function()? onRequestMore;
  final bool allLoaded;

  const ShortsViewer({
    super.key,
    required this.posts,
    required this.onClose,
    this.onLike,
    this.onComment,
    this.onShare,
    this.initialVideoUrl,
    this.onRequestMore,
    this.allLoaded = false,
  });

  @override
  State<ShortsViewer> createState() => _ShortsViewerState();
}

class _ShortsCommentsBottomSheet extends StatefulWidget {
  final BusinessNetworkPost post;
  final VoidCallback onCommentAdded;

  const _ShortsCommentsBottomSheet({
    required this.post,
    required this.onCommentAdded,
  });

  @override
  State<_ShortsCommentsBottomSheet> createState() => _ShortsCommentsBottomSheetState();
}

class _ShortsCommentsBottomSheetState extends State<_ShortsCommentsBottomSheet> {
  bool _isLoading = true;
  late BusinessNetworkPost _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    final comments = await BusinessNetworkService.getPostComments(postId: widget.post.id);
    if (!mounted) return;

    setState(() {
      final nextCount = _post.commentsCount > 0 ? _post.commentsCount : comments.length;
      _post = _post.copyWith(
        comments: comments,
        commentsCount: nextCount,
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthService.currentUser != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
                child: Row(
                  children: [
                    Text(
                      'Comments',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : _post.comments.isEmpty
                        ? Center(
                            child: Text(
                              'No comments yet',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            controller: scrollController,
                            child: PostCommentsPreview(
                              post: _post,
                              onViewAll: () {},
                              showAll: true,
                              showHeader: false,
                              onReplySubmit: (comment, content) async {
                                final newComment = await BusinessNetworkService.addComment(
                                  postId: _post.id,
                                  content: content,
                                  parentCommentId: comment.id,
                                );

                                if (newComment != null && mounted) {
                                  setState(() {
                                    _post = _post.copyWith(
                                      commentsCount: _post.commentsCount + 1,
                                      comments: [..._post.comments, newComment],
                                    );
                                  });
                                  widget.onCommentAdded();
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
                          ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
                ),
                child: PostCommentInput(
                  onSubmit: (content) async {
                    final comment = await BusinessNetworkService.addComment(
                      postId: widget.post.id,
                      content: content,
                    );
                    if (comment != null) {
                      if (!mounted) return;
                      setState(() {
                        _post = _post.copyWith(
                          commentsCount: _post.commentsCount + 1,
                          comments: [..._post.comments, comment],
                        );
                      });
                      widget.onCommentAdded();
                    }
                  },
                  userAvatar: AuthService.currentUser?.profilePicture,
                  postId: widget.post.id.toString(),
                  postAuthorId: widget.post.user.uuid ?? widget.post.user.id.toString(),
                  postAuthorName: widget.post.user.name,
                  onGiftSent: isLoggedIn ? _loadComments : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShortItem {
  final BusinessNetworkPost post;
  final PostMedia media;

  const _ShortItem({required this.post, required this.media});
}

class _ShortsViewerState extends State<ShortsViewer> {
  late final List<_ShortItem> _items;
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _isRequestingMore = false;
  final Map<int, int> _mediaViewsOverrides = {};

  @override
  void initState() {
    super.initState();
    _items = widget.posts
        .expand((p) => p.media.where((m) => m.isVideo).map((m) => _ShortItem(post: p, media: m)))
        .toList();

    _currentIndex = _findInitialIndex(widget.initialVideoUrl, _items);
    _pageController = PageController(initialPage: _currentIndex);
  }

  int _findInitialIndex(String? initialVideoUrl, List<_ShortItem> items) {
    final target = (initialVideoUrl ?? '').trim();
    if (target.isEmpty) return 0;
    final idx = items.indexWhere((e) => e.media.bestUrl == target);
    return idx < 0 ? 0 : idx;
  }

  Future<void> _maybeRequestMore(int index) async {
    final cb = widget.onRequestMore;
    if (cb == null) return;
    if (_isRequestingMore) return;
    if (index < _items.length - 2) return;

    _isRequestingMore = true;
    try {
      await cb();
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingMore = false;
        });
      } else {
        _isRequestingMore = false;
      }
    }
  }

  int _currentViewsCount() {
    if (_currentIndex < 0 || _currentIndex >= _items.length) return 0;
    final item = _items[_currentIndex];
    return _mediaViewsOverrides[item.media.id] ?? item.media.views;
  }

  @override
  void didUpdateWidget(covariant ShortsViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextItems = widget.posts
        .expand((p) => p.media.where((m) => m.isVideo).map((m) => _ShortItem(post: p, media: m)))
        .toList();

    final nextIndex = _currentIndex.clamp(0, nextItems.isEmpty ? 0 : nextItems.length - 1);
    setState(() {
      _currentIndex = nextIndex;
      _items
        ..clear()
        ..addAll(nextItems);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _currentIndex.clamp(0, _items.isEmpty ? 0 : _items.length - 1);
      _pageController.jumpToPage(target);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Text(
            'No shorts yet',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _items.length + (widget.allLoaded ? 1 : 0),
            onPageChanged: (i) {
              setState(() {
                _currentIndex = i;
              });
              _maybeRequestMore(i);
            },
            itemBuilder: (context, index) {
              // Show "All videos loaded" page at the end
              if (index >= _items.length) {
                return Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.white.withValues(alpha: 0.7), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'All shorts loaded',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Swipe down to go back',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final item = _items[index];
              return _ShortVideoPage(
                key: ValueKey('short_${item.post.id}_${item.media.id}'),
                post: item.post,
                media: item.media,
                isActive: index == _currentIndex,
                onLike: widget.onLike,
                onComment: widget.onComment,
                onShare: widget.onShare,
                onViewsChanged: (nextViews) {
                  if (!mounted) return;
                  setState(() {
                    _mediaViewsOverrides[item.media.id] = nextViews;
                  });
                },
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Shorts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (_currentIndex < _items.length)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_outlined, size: 16, color: Colors.white.withValues(alpha: 0.9)),
                          const SizedBox(width: 6),
                          Text(
                            _currentViewsCount().toString(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
    );
  }
}

class _ShortVideoPage extends StatefulWidget {
  final BusinessNetworkPost post;
  final PostMedia media;
  final bool isActive;
  final void Function(BusinessNetworkPost post)? onLike;
  final void Function(BusinessNetworkPost post)? onComment;
  final void Function(BusinessNetworkPost post)? onShare;
  final void Function(int views)? onViewsChanged;

  const _ShortVideoPage({
    super.key,
    required this.post,
    required this.media,
    required this.isActive,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onViewsChanged,
  });

  @override
  State<_ShortVideoPage> createState() => _ShortVideoPageState();
}

class _ShortVideoPageState extends State<_ShortVideoPage> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorUrl;
  String? _errorText;
  bool _showPlayHint = false;
  int _commentsCount = 0;
  int _viewsCount = 0;
  late BusinessNetworkPost _post;
  bool _isLiking = false;

  Timer? _viewTimer;
  bool _viewCounted = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _commentsCount = widget.post.commentsCount;
    _viewsCount = widget.media.views;
    _init();
  }

  @override
  void didUpdateWidget(covariant _ShortVideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      _post = widget.post;
      _commentsCount = widget.post.commentsCount;
    }
    if (oldWidget.media.bestUrl != widget.media.bestUrl) {
      _viewTimer?.cancel();
      _viewTimer = null;
      _viewCounted = false;
      _viewsCount = widget.media.views;
      _disposeController();
      _init();
      return;
    }

    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _controller?.play();
        _maybeScheduleViewCount();
      } else {
        _controller?.pause();
        _viewTimer?.cancel();
        _viewTimer = null;
      }
    }
  }

  Future<void> _init() async {
    try {
      final url = widget.media.bestUrl;
      print('ShortsViewer: initializing video url=$url mediaId=${widget.media.id}');
      if (url.isEmpty) {
        setState(() {
          _hasError = true;
          _errorUrl = url;
          _errorText = 'Empty video url';
        });
        return;
      }

      _errorUrl = url;

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: const {
          'User-Agent': 'OxiUsFlutter/1.0',
        },
      );
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _hasError = false;
      });

      if (widget.isActive) {
        controller.play();
        _maybeScheduleViewCount();
      }
    } catch (e, stackTrace) {
      print('ShortsViewer: failed to initialize video url=${widget.media.bestUrl} mediaId=${widget.media.id} error=$e');
      print('ShortsViewer: stackTrace=$stackTrace');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorUrl = widget.media.bestUrl;
        _errorText = e.toString();
      });
    }
  }

  void _disposeController() {
    final c = _controller;
    _controller = null;
    c?.dispose();
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    _disposeController();
    super.dispose();
  }

  void _maybeScheduleViewCount() {
    if (!widget.isActive) return;
    if (_viewCounted) return;
    final c = _controller;
    if (c == null || !_isInitialized) return;
    if (!c.value.isPlaying) return;
    if (_viewTimer != null) return;

    _viewTimer = Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      if (!widget.isActive) return;
      if (_viewCounted) return;

      try {
        final next = await BusinessNetworkService.incrementMediaViews(widget.media.id.toString());
        if (!mounted) return;
        final nextViews = next ?? (_viewsCount + 1);
        setState(() {
          _viewsCount = nextViews;
          _viewCounted = true;
        });
        widget.onViewsChanged?.call(nextViews);
      } catch (_) {
        if (!mounted) return;
        final nextViews = _viewsCount + 1;
        setState(() {
          _viewsCount = nextViews;
          _viewCounted = true;
        });
        widget.onViewsChanged?.call(nextViews);
      } finally {
        _viewTimer?.cancel();
        _viewTimer = null;
      }
    });
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || !_isInitialized) return;

    if (c.value.isPlaying) {
      c.pause();
      setState(() {
        _showPlayHint = true;
      });
    } else {
      c.play();
      setState(() {
        _showPlayHint = false;
      });
      _maybeScheduleViewCount();
    }
  }

  bool _isOwnPost() {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) return false;

    final postUser = _post.user;
    final postUsername = (postUser.username ?? '').trim();
    if (postUsername.isNotEmpty && postUsername == currentUser.username) return true;

    final postUuid = (postUser.uuid ?? '').trim();
    if (postUuid.isNotEmpty && postUuid == currentUser.id) return true;

    if (postUser.id.toString() == currentUser.id) return true;

    return false;
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

  Future<void> _handleLike() async {
    if (AuthService.currentUser == null) {
      _showLoginPrompt('like this post');
      return;
    }

    if (_isLiking) return;
    _isLiking = true;

    final originalIsLiked = _post.isLiked;
    final originalLikesCount = _post.likesCount;

    if (mounted) {
      setState(() {
        _post = _post.copyWith(
          isLiked: !originalIsLiked,
          likesCount: originalIsLiked ? originalLikesCount - 1 : originalLikesCount + 1,
        );
      });
    }

    try {
      final success = await BusinessNetworkService.toggleLike(_post.id, originalIsLiked);
      if (!success) {
        throw Exception('Failed to ${originalIsLiked ? 'unlike' : 'like'} post');
      }
      widget.onLike?.call(_post);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _post = _post.copyWith(
          isLiked: originalIsLiked,
          likesCount: originalLikesCount,
        );
      });

      NetworkErrorHandler.showErrorSnackbar(
        context,
        e,
        onRetry: _handleLike,
      );
    } finally {
      _isLiking = false;
    }
  }

  Future<void> _handleShare() async {
    try {
      String shareText = '';

      if (_post.title.isNotEmpty) {
        shareText += '${_post.title}\n\n';
      }

      shareText += _post.content;
      shareText += '\n\nView on Business Network: ${AppConfig.mediaBaseUrl}/bn/posts/${_post.id}/';

      await Share.share(
        shareText,
        subject: _post.title.isNotEmpty ? _post.title : 'Business Network Post',
      );
      widget.onShare?.call(_post);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openCommentsSheet() async {
    final c = _controller;
    c?.pause();
    if (mounted) {
      setState(() {
        _showPlayHint = true;
      });
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ShortsCommentsBottomSheet(
          post: _post,
          onCommentAdded: () {
            if (!mounted) return;
            final nextCount = _commentsCount + 1;
            final updated = _post.copyWith(commentsCount: nextCount);
            setState(() {
              _commentsCount = nextCount;
              _post = updated;
            });
            widget.onComment?.call(updated);
          },
        );
      },
    );

    if (!mounted) return;
    if (widget.isActive) {
      _controller?.play();
      setState(() {
        _showPlayHint = false;
      });
    }
  }

  Future<void> _openGiftSheet() async {
    if (AuthService.currentUser == null) {
      _showLoginPrompt('send a gift');
      return;
    }

    final c = _controller;
    c?.pause();
    if (mounted) {
      setState(() {
        _showPlayHint = true;
      });
    }

    await DiamondGiftBottomSheet.show(
      context,
      postId: _post.id.toString(),
      postAuthorId: _post.user.uuid ?? _post.user.id.toString(),
      postAuthorName: _post.user.name,
      onGiftSent: () {
        if (!mounted) return;
        final nextCount = _commentsCount + 1;
        final updated = _post.copyWith(commentsCount: nextCount);
        setState(() {
          _commentsCount = nextCount;
          _post = updated;
        });
        widget.onComment?.call(updated);
      },
    );

    if (!mounted) return;
    if (widget.isActive) {
      _controller?.play();
      setState(() {
        _showPlayHint = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    final thumbUrl = widget.media.bestThumbnailUrl;

    return GestureDetector(
      onTap: _togglePlay,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        fit: StackFit.expand,
        children: [
        if (_hasError)
          Container(
            color: Colors.black,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Failed to load video',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                      textAlign: TextAlign.center,
                    ),
                    if ((_errorUrl ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorUrl!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if ((_errorText ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorText!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
        else if (!_isInitialized || _controller == null)
          Stack(
            fit: StackFit.expand,
            children: [
              if (thumbUrl.isNotEmpty)
                Image.network(
                  thumbUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: Colors.black);
                  },
                )
              else
                Container(color: Colors.black),
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ],
          )
        else
          Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.black),
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ],
          ),

        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 220,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (_showPlayHint)
          IgnorePointer(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 54),
              ),
            ),
          ),

        if (_isInitialized && _controller != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 6,
            child: SafeArea(
              top: false,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.25),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: const Color(0xFF3B82F6),
                      bufferedColor: Colors.white.withValues(alpha: 0.35),
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
            ),
          ),

        Positioned(
          right: 12,
          bottom: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                label: post.likesCount.toString(),
                onTap: _handleLike,
              ),
              const SizedBox(height: 14),
              _ActionButton(
                icon: Icons.comment_rounded,
                label: _commentsCount.toString(),
                onTap: _openCommentsSheet,
              ),
              const SizedBox(height: 14),
              if (!_isOwnPost()) ...[
                _ActionButton(
                  icon: Icons.card_giftcard,
                  label: 'Gift',
                  onTap: () {
                    // ignore: discarded_futures
                    _openGiftSheet();
                  },
                ),
                const SizedBox(height: 14),
              ],
              _ActionButton(
                icon: Icons.share_rounded,
                label: 'Share',
                onTap: _handleShare,
              ),
            ],
          ),
        ),

        Positioned(
          left: 12,
          right: 80,
          bottom: 18,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
              RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: post.user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (post.user.isVerified) ...[
                      const TextSpan(text: ' '),
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.verified,
                          size: 15,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                    if (post.user.isPro) ...[
                      const TextSpan(text: ' '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade600,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                          ),
                          child: const Text(
                            'Pro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (post.title.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                ],
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 56,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
