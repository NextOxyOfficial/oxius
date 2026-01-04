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
import '../../widgets/login_prompt_dialog.dart';
import 'profile_screen.dart';

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
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
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
  final Map<int, VideoPlayerController> _preloadedControllers = {};

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

    final wasOnEndPage = _currentIndex >= _items.length;
    final oldItemsLength = _items.length;
    
    setState(() {
      _items
        ..clear()
        ..addAll(nextItems);
    });

    // If user was on end page and new items were added, stay on end page
    // Otherwise keep current position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      if (wasOnEndPage) {
        // If new items were loaded, user can continue watching
        // If no new items, stay on end page
        if (nextItems.length > oldItemsLength) {
          // New videos loaded - go to first new video
          _pageController.jumpToPage(oldItemsLength);
          setState(() {
            _currentIndex = oldItemsLength;
          });
        } else {
          // No new videos - stay on end page
          _pageController.jumpToPage(nextItems.length);
          setState(() {
            _currentIndex = nextItems.length;
          });
        }
      } else {
        // User was watching a video - keep position
        final target = _currentIndex.clamp(0, _items.isEmpty ? 0 : _items.length - 1);
        if (_pageController.page?.round() != target) {
          _pageController.jumpToPage(target);
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _disposeAllPreloadedControllers();
    super.dispose();
  }

  void _disposeAllPreloadedControllers() {
    for (final controller in _preloadedControllers.values) {
      controller.dispose();
    }
    _preloadedControllers.clear();
  }

  Future<void> _preloadVideos(int currentIndex) async {
    // Preload next 2 videos
    for (int i = 1; i <= 2; i++) {
      final nextIndex = currentIndex + i;
      if (nextIndex >= _items.length) break;
      
      final item = _items[nextIndex];
      final mediaId = item.media.id;
      
      // Skip if already preloaded
      if (_preloadedControllers.containsKey(mediaId)) continue;
      
      final url = item.media.bestUrl;
      if (url.isEmpty) continue;
      
      try {
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(url),
          httpHeaders: const {
            'User-Agent': 'OxiUsFlutter/1.0',
          },
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        
        await controller.initialize();
        await controller.setLooping(true);
        await controller.setVolume(0.0); // Muted until active
        
        if (!mounted) {
          controller.dispose();
          return;
        }
        
        _preloadedControllers[mediaId] = controller;
        print('Preloaded video at index $nextIndex (mediaId: $mediaId)');
      } catch (e) {
        print('Failed to preload video at index $nextIndex: $e');
      }
    }
    
    // Clean up old preloaded videos (keep only next 2)
    final validIds = <int>{};
    for (int i = 1; i <= 2; i++) {
      final nextIndex = currentIndex + i;
      if (nextIndex < _items.length) {
        validIds.add(_items[nextIndex].media.id);
      }
    }
    
    final toRemove = _preloadedControllers.keys.where((id) => !validIds.contains(id)).toList();
    for (final id in toRemove) {
      _preloadedControllers[id]?.dispose();
      _preloadedControllers.remove(id);
    }
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
            itemCount: _items.length + 1,
            onPageChanged: (i) {
              setState(() {
                _currentIndex = i;
              });
              _maybeRequestMore(i);
              _preloadVideos(i);
            },
            itemBuilder: (context, index) {
              // Show end page (loading or all caught up)
              if (index >= _items.length) {
                // If still loading more, show loading indicator
                if (!widget.allLoaded && _isRequestingMore) {
                  return Container(
                    color: Colors.black,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading more shorts...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // Show "All Caught Up" page
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF1a1a2e),
                        const Color(0xFF16213e),
                        const Color(0xFF0f3460),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Animated checkmark icon with glow
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF667eea),
                                    const Color(0xFF764ba2),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF667eea).withOpacity(0.4),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_circle_filled_rounded,
                                color: Colors.white,
                                size: 56,
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Main title
                            const Text(
                              "You're All Caught Up!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            // Subtitle
                            Text(
                              "You've watched all the latest shorts.\nCheck back later for more amazing content!",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 15,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),
                            // Create shorts button
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                // Navigate to create post with video
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF667eea).withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.videocam_rounded, color: Colors.white, size: 22),
                                    SizedBox(width: 10),
                                    Text(
                                      'Create Your Short',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Swipe hint
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.swipe_down_rounded,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Swipe down to go back',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
                preloadedController: _preloadedControllers[item.media.id],
                onLike: widget.onLike,
                onComment: widget.onComment,
                onShare: widget.onShare,
                onViewsChanged: (nextViews) {
                  if (!mounted) return;
                  setState(() {
                    _mediaViewsOverrides[item.media.id] = nextViews;
                  });
                },
                onControllerCreated: (controller) {
                  // Remove from preloaded map once it's being used
                  _preloadedControllers.remove(item.media.id);
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
  final VideoPlayerController? preloadedController;
  final void Function(BusinessNetworkPost post)? onLike;
  final void Function(BusinessNetworkPost post)? onComment;
  final void Function(BusinessNetworkPost post)? onShare;
  final void Function(int views)? onViewsChanged;
  final void Function(VideoPlayerController controller)? onControllerCreated;

  const _ShortVideoPage({
    super.key,
    required this.post,
    required this.media,
    required this.isActive,
    this.preloadedController,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onViewsChanged,
    this.onControllerCreated,
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
        _controller?.setVolume(1.0);
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

      // Use preloaded controller if available
      if (widget.preloadedController != null) {
        print('ShortsViewer: using preloaded controller for mediaId=${widget.media.id}');
        _controller = widget.preloadedController;
        widget.onControllerCreated?.call(widget.preloadedController!);
        
        // Controller is already initialized, just set volume and play
        await _controller!.setVolume(1.0);
        
        if (!mounted) return;
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });

        if (widget.isActive) {
          _controller!.play();
          _maybeScheduleViewCount();
        }
        return;
      }

      // No preloaded controller, initialize normally
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: const {
          'User-Agent': 'OxiUsFlutter/1.0',
        },
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _controller = controller;
      widget.onControllerCreated?.call(controller);
      
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(1.0);

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
    // Only dispose if it wasn't a preloaded controller
    // (preloaded controllers are managed by parent)
    if (c != null && c != widget.preloadedController) {
      c.dispose();
    }
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
    LoginPromptDialog.show(context, action: action);
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
      shareText += '\n\nView on Business Network: https://adsyclub.com/business-network/posts/${_post.id}';

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

    Widget thumbFallback() {
      return Container(
        color: Colors.grey.shade300,
        child: Center(
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
      );
    }

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
                    return thumbFallback();
                  },
                )
              else
                thumbFallback(),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 10,
                        width: 180,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 10,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
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
                iconPath: post.isLiked ? 'assets/icons/like.png' : 'assets/icons/unlike.png',
                label: post.likesCount.toString(),
                onTap: _handleLike,
                applyGrayFill: !post.isLiked,
              ),
              const SizedBox(height: 14),
              _ActionButton(
                iconPath: 'assets/icons/comments.png',
                label: _commentsCount.toString(),
                onTap: _openCommentsSheet,
              ),
              const SizedBox(height: 14),
              if (!_isOwnPost()) ...[
                _ActionButton(
                  materialIcon: Icons.card_giftcard,
                  label: 'Gift',
                  onTap: () {
                    // ignore: discarded_futures
                    _openGiftSheet();
                  },
                ),
                const SizedBox(height: 14),
              ],
              _ActionButton(
                iconPath: 'assets/icons/share.png',
                label: 'Share',
                onTap: _handleShare,
              ),
            ],
          ),
        ),

        Positioned(
          left: 12,
          right: 80,
          bottom: 34,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      userId: post.user.uuid ?? post.user.id.toString(),
                    ),
                  ),
                );
              },
              child: RichText(
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
            if (post.content.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
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

class _ActionButton extends StatelessWidget {
  final String? iconPath;
  final IconData? materialIcon;
  final String label;
  final VoidCallback? onTap;
  final bool applyGrayFill;

  const _ActionButton({
    this.iconPath,
    this.materialIcon,
    required this.label,
    required this.onTap,
    this.applyGrayFill = false,
  }) : assert(iconPath != null || materialIcon != null, 'Either iconPath or materialIcon must be provided');

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
            ),
            child: Center(
              child: iconPath != null
                  ? (applyGrayFill
                      ? ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.grey.shade400,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            iconPath!,
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Image.asset(
                          iconPath!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ))
                  : Icon(
                      materialIcon!,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
