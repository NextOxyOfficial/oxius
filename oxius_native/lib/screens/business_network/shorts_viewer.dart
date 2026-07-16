import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import '../../services/auth_service.dart';
import '../../services/ads_service.dart';
import '../../services/user_suggestions_service.dart';
import '../../utils/html_content_utils.dart';
import '../../utils/network_error_handler.dart';
import '../../widgets/business_network/post_comment_input.dart';
import '../../widgets/business_network/post_comments_preview.dart';
import '../../widgets/business_network/diamond_gift_bottom_sheet.dart';
import '../../widgets/login_prompt_dialog.dart';
import '../../widgets/common/adsy_share_sheet.dart';
import 'profile_screen.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

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
  State<_ShortsCommentsBottomSheet> createState() =>
      _ShortsCommentsBottomSheetState();
}

class _ShortsCommentsBottomSheetState
    extends State<_ShortsCommentsBottomSheet> {
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

    final comments =
        await BusinessNetworkService.getPostComments(postId: widget.post.id);
    if (!mounted) return;

    setState(() {
      final nextCount =
          _post.commentsCount > 0 ? _post.commentsCount : comments.length;
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
                  margin: const EdgeInsets.symmetric(vertical: 0),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 2, 2),
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
                      ? const Center(
                          child: AdsyLoadingIndicator(strokeWidth: 2))
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
                                  final newComment =
                                      await BusinessNetworkService.addComment(
                                    postId: _post.id,
                                    content: content,
                                    parentCommentId: comment.id,
                                  );

                                  if (newComment != null && mounted) {
                                    setState(() {
                                      _post = _post.copyWith(
                                        commentsCount: _post.commentsCount + 1,
                                        comments: [
                                          ..._post.comments,
                                          newComment
                                        ],
                                      );
                                    });
                                    widget.onCommentAdded();
                                  }
                                },
                                onCommentCountChanged: () {
                                  if (!mounted) return;
                                  setState(() {
                                    _post = _post.copyWith(
                                      commentsCount: _post.commentsCount > 0
                                          ? _post.commentsCount - 1
                                          : 0,
                                    );
                                  });
                                },
                              ),
                            ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        top: BorderSide(color: Colors.grey.shade200, width: 1)),
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
                    postAuthorId:
                        widget.post.user.uuid ?? widget.post.user.id.toString(),
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

  // Ads: the currently-playing controller (so we can pause it behind a
  // full-screen ad) + a counter that triggers one every N shorts.
  VideoPlayerController? _activeController;
  int _shortsSinceAd = 0;
  // Media ids whose controller has been handed over to (and is owned by) a
  // live page — never re-preload these or we'd stream the same video twice.
  final Set<int> _pageOwnedMediaIds = {};

  @override
  void initState() {
    super.initState();
    _items = widget.posts
        .expand((p) => p.media
            .where((m) => m.isVideo)
            .map((m) => _ShortItem(post: p, media: m)))
        .toList();

    // Randomize the reel for every user/session (TikTok-style discovery):
    // the tapped video always plays first, everything after it is shuffled.
    final initial = _findInitialIndex(widget.initialVideoUrl, _items);
    if (_items.length > 1) {
      final first = _items.removeAt(initial);
      _items.shuffle();
      _items.insert(0, first);
    }
    _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);

    // Warm up the shorts full-screen ad slot.
    AdsService.preloadInterstitial('shorts_fullscreen');

    // Start warming neighbours immediately — previously preloading only
    // began after the FIRST swipe, so the second video always showed a
    // loading state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _preloadVideos(_currentIndex);
    });
  }

  int _findInitialIndex(String? initialVideoUrl, List<_ShortItem> items) {
    final target = (initialVideoUrl ?? '').trim();
    if (target.isEmpty) return 0;
    final idx = items.indexWhere((e) => e.media.bestUrl == target);
    return idx < 0 ? 0 : idx;
  }

  // Full-screen ad every N shorts (server-tuned, default 5). Pauses the
  // current video so audio doesn't play behind the ad, resumes after.
  Future<void> _maybeShowShortsAd(int index) async {
    if (!AdsService.placementActive('shorts_fullscreen')) return;
    if (index >= _items.length) return; // on the end/caught-up page
    _shortsSinceAd++;
    final every = AdsService.feedFrequency('shorts_fullscreen', fallback: 5);
    if (_shortsSinceAd < every) return;
    _shortsSinceAd = 0;
    final wasPlaying = _activeController?.value.isPlaying ?? false;
    _activeController?.pause();
    await AdsService.showInterstitial('shorts_fullscreen');
    if (!mounted) return;
    if (wasPlaying) _activeController?.play();
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
    // Merge-only: keep the current (shuffled) order stable and append the
    // newly fetched videos — themselves shuffled — at the end. Replacing the
    // list wholesale would both unshuffle it and yank the page under the
    // user's thumb.
    final incoming = widget.posts
        .expand((p) => p.media
            .where((m) => m.isVideo)
            .map((m) => _ShortItem(post: p, media: m)))
        .toList();
    final existingIds = _items.map((e) => e.media.id).toSet();
    final fresh = incoming
        .where((e) => !existingIds.contains(e.media.id))
        .toList()
      ..shuffle();

    if (fresh.isEmpty) return;

    final wasOnEndPage = _currentIndex >= _items.length;
    final oldItemsLength = _items.length;

    setState(() {
      _items.addAll(fresh);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (wasOnEndPage) {
        // User was parked on the end page — slide onto the first new video.
        _pageController.jumpToPage(oldItemsLength);
        setState(() {
          _currentIndex = oldItemsLength;
        });
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

  /// Warm the videos around [currentIndex]: the next two (forward swipes)
  /// and the previous one (swiping back), all in PARALLEL so the nearest
  /// neighbour isn't stuck behind a slower download.
  Future<void> _preloadVideos(int currentIndex) async {
    const offsets = [1, 2, -1];
    final futures = <Future<void>>[];

    for (final off in offsets) {
      final idx = currentIndex + off;
      if (idx < 0 || idx >= _items.length) continue;

      final item = _items[idx];
      final mediaId = item.media.id;

      if (_preloadedControllers.containsKey(mediaId)) continue;
      // A live page already owns a controller for this media.
      if (_pageOwnedMediaIds.contains(mediaId)) continue;

      final url = item.media.bestUrl;
      if (url.isEmpty) continue;

      futures.add(() async {
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

          if (!mounted || _pageOwnedMediaIds.contains(mediaId)) {
            controller.dispose();
            return;
          }

          _preloadedControllers[mediaId] = controller;
        } catch (e) {
          debugPrint('Failed to preload video at index $idx: $e');
        }
      }());
    }

    await Future.wait(futures);
    if (!mounted) return;

    // Drop warmed videos that fell outside the window.
    final validIds = <int>{};
    for (final off in offsets) {
      final idx = currentIndex + off;
      if (idx >= 0 && idx < _items.length) {
        validIds.add(_items[idx].media.id);
      }
    }
    final toRemove = _preloadedControllers.keys
        .where((id) => !validIds.contains(id))
        .toList();
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
            // Keeps the adjacent pages alive and pre-built (TikTok-style), so
            // swiping back/forth never rebuilds a page from scratch.
            allowImplicitScrolling: true,
            itemCount: _items.length + 1,
            onPageChanged: (i) {
              setState(() {
                _currentIndex = i;
              });
              _maybeRequestMore(i);
              _preloadVideos(i);
              _maybeShowShortsAd(i);
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
                          AdsyLoadingIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
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
                  color: const Color(0xFF0F172A),
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
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF6366F1),
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
                                color: Colors.white.withValues(alpha: 0.7),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.videocam_rounded,
                                        color: Colors.white, size: 22),
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
                                  color: Colors.white.withValues(alpha: 0.5),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Swipe down to go back',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
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
                  // Ownership moves to the page: out of the preload map, and
                  // marked so we never spin up a duplicate stream for it.
                  _preloadedControllers.remove(item.media.id);
                  _pageOwnedMediaIds.add(item.media.id);
                  _activeController = controller;
                },
                onControllerDisposed: () {
                  _pageOwnedMediaIds.remove(item.media.id);
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_outlined,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.9)),
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
  final VoidCallback? onControllerDisposed;

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
    this.onControllerDisposed,
  });

  @override
  State<_ShortVideoPage> createState() => _ShortVideoPageState();
}

class _ShortVideoPageState extends State<_ShortVideoPage>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorUrl;
  String? _errorText;
  bool _showPlayHint = false;
  // Non-null while the user drags the seekbar dot (milliseconds position).
  double? _scrubValue;
  int _commentsCount = 0;
  int _viewsCount = 0;
  late BusinessNetworkPost _post;
  bool _isLiking = false;
  bool _wasPlayingBeforePause = false;
  bool _captionExpanded = false;
  bool _isFollowing = false;
  bool _followBusy = false;
  bool _showHeartBurst = false;
  Timer? _heartBurstTimer;

  Timer? _viewTimer;
  bool _viewCounted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _post = widget.post;
    _commentsCount = widget.post.commentsCount;
    _viewsCount = widget.media.views;
    _isFollowing = widget.post.user.isFollowing;
    _init();
  }

  /// 12500 -> 12.5K, 3400000 -> 3.4M — keeps rail labels tidy.
  static String _compact(int n) {
    if (n >= 1000000) {
      final v = n / 1000000;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}M';
    }
    if (n >= 1000) {
      final v = n / 1000;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}K';
    }
    return n.toString();
  }

  Future<void> _handleFollow() async {
    if (AuthService.currentUser == null) {
      _showLoginPrompt('follow this user');
      return;
    }
    if (_followBusy || _isFollowing) return;
    _followBusy = true;
    setState(() => _isFollowing = true); // optimistic
    try {
      final ok = await UserSuggestionsService.followUser(
          _post.user.uuid ?? _post.user.id.toString());
      if (!ok && mounted) setState(() => _isFollowing = false);
    } catch (_) {
      if (mounted) setState(() => _isFollowing = false);
    } finally {
      _followBusy = false;
    }
  }

  void _handleDoubleTapLike() {
    // Instagram/TikTok double-tap: like (never unlike) + heart burst.
    if (!_post.isLiked) {
      _handleLike();
    }
    _heartBurstTimer?.cancel();
    setState(() => _showHeartBurst = true);
    _heartBurstTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _showHeartBurst = false);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App went to background or another screen pushed - pause video
      _wasPlayingBeforePause = _controller?.value.isPlaying ?? false;
      _controller?.pause();
    } else if (state == AppLifecycleState.resumed) {
      // App came back to foreground - resume if was playing and still active
      if (_wasPlayingBeforePause && widget.isActive && mounted) {
        _controller?.play();
      }
    }
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
      debugPrint(
          'ShortsViewer: initializing video url=$url mediaId=${widget.media.id}');
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
        debugPrint(
            'ShortsViewer: using preloaded controller for mediaId=${widget.media.id}');
        _controller = widget.preloadedController;
        widget.onControllerCreated?.call(widget.preloadedController!);

        // Only unmute when this page is actually on screen — with implicit
        // scrolling the neighbour pages build (and take their controllers)
        // while still offscreen.
        await _controller!.setVolume(widget.isActive ? 1.0 : 0.0);

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
      await controller.setVolume(widget.isActive ? 1.0 : 0.0);

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
      debugPrint(
          'ShortsViewer: failed to initialize video url=${widget.media.bestUrl} mediaId=${widget.media.id} error=$e');
      debugPrint('ShortsViewer: stackTrace=$stackTrace');
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
    // The page owns whatever controller it holds — preloaded ones are handed
    // over by the parent (and removed from its map) the moment we take them,
    // so skipping disposal here leaked a looping decoder per watched video.
    if (c != null) {
      c.dispose();
      widget.onControllerDisposed?.call();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewTimer?.cancel();
    _heartBurstTimer?.cancel();
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
        final next = await BusinessNetworkService.incrementMediaViews(
            widget.media.id.toString());
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
    if (postUsername.isNotEmpty && postUsername == currentUser.username) {
      return true;
    }

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
          likesCount:
              originalIsLiked ? originalLikesCount - 1 : originalLikesCount + 1,
        );
      });
    }

    try {
      final success =
          await BusinessNetworkService.toggleLike(_post.id, originalIsLiked);
      if (!success) {
        throw Exception(
            'Failed to ${originalIsLiked ? 'unlike' : 'like'} post');
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
    final plainPostContent = HtmlContentUtils.toPlainText(_post.content);
    await AdsyShareSheet.show(
      context,
      data: AdsyShareData(
        title: '${_post.user.name} on Business Network',
        description: HtmlContentUtils.previewText(plainPostContent, 140),
        url:
            'https://adsyclub.com/business-network/posts/${_post.slug.isNotEmpty ? _post.slug : _post.id}',
        imageUrl:
            _post.media.isNotEmpty ? _post.media.first.bestThumbnailUrl : null,
        subject: 'Business Network Post',
        eyebrow: 'Business Network',
        hashtags: _post.tags.map((tag) => tag.tag).toList(),
        // Repost this short to the user's own profile/feed.
        onRepost: (caption) async {
          if (!AuthService.isAuthenticated) return false;
          final targetId = _post.sharedFrom?.id ?? _post.id;
          final result = await BusinessNetworkService.resharePost(
            targetId,
            caption: caption,
          );
          return result != null;
        },
      ),
    );
    widget.onShare?.call(_post);
  }

  Future<void> _openCommentsSheet() async {
    // Don't pause video - let it play while comments are open
    // final c = _controller;
    // c?.pause();
    // if (mounted) {
    //   setState(() {
    //     _showPlayHint = true;
    //   });
    // }

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

    // No need to resume since we didn't pause
    // if (!mounted) return;
    // if (widget.isActive) {
    //   _controller?.play();
    //   setState(() {
    //     _showPlayHint = false;
    //   });
    // }
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

  /// TikTok/Reels-style video surface:
  /// - portrait videos fill the whole screen (cover crop),
  /// - landscape videos sit centered over a blurred, darkened backdrop so
  ///   there are never hard black bars.
  /// A small spinner overlays while the network stream re-buffers.
  Widget _buildVideoSurface(String thumbUrl) {
    final controller = _controller!;
    final ar = controller.value.aspectRatio;
    final isPortrait = ar <= 0.85;

    Widget video;
    if (isPortrait) {
      video = SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      );
    } else {
      video = Stack(
        fit: StackFit.expand,
        children: [
          if (thumbUrl.isNotEmpty)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
              child: Image.network(
                thumbUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.black),
              ),
            )
          else
            Container(color: Colors.black),
          Container(color: Colors.black.withValues(alpha: 0.45)),
          Center(
            child: AspectRatio(
              aspectRatio: ar,
              child: VideoPlayer(controller),
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        video,
        // Re-buffer indicator: only when playing but starved of data.
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final stalled =
                value.isBuffering && value.isPlaying && !value.hasError;
            if (!stalled) return const SizedBox.shrink();
            return const Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: AdsyLoadingIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            );
          },
        ),
      ],
    );
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
      onDoubleTap: _handleDoubleTapLike,
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
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85)),
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
            // While the video initializes: full-bleed thumbnail (so the frame
            // is already "there", reels-style) with a small quiet spinner.
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
                Container(color: Colors.black.withValues(alpha: 0.25)),
                const Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: AdsyLoadingIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ],
            )
          else
            _buildVideoSurface(thumbUrl),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 220,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showPlayHint ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 180),
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
          ),
          if (_showPlayHint)
            IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 54),
                ),
              ),
            ),
          if (_isInitialized && _controller != null)
            // Seekbar: thin track with a white draggable dot, floated above
            // the screen edge with side padding so it never sits flush against
            // the bottom.
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: SafeArea(
                top: false,
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _controller!,
                  builder: (context, value, _) {
                    final maxMs = value.duration.inMilliseconds.toDouble();
                    if (maxMs <= 0) return const SizedBox.shrink();
                    final posMs = _scrubValue ??
                        value.position.inMilliseconds
                            .clamp(0, value.duration.inMilliseconds)
                            .toDouble();
                    final scrubbing = _scrubValue != null;
                    final emphasized = scrubbing || _showPlayHint;
                    return SizedBox(
                      height: 26,
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: emphasized ? 4 : 2.5,
                          activeTrackColor: Colors.white,
                          inactiveTrackColor:
                              Colors.white.withValues(alpha: 0.25),
                          thumbColor: Colors.white,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: emphasized ? 7 : 4.5,
                            elevation: 0,
                            pressedElevation: 0,
                          ),
                          overlayShape: SliderComponentShape.noOverlay,
                          trackShape: const RectangularSliderTrackShape(),
                        ),
                        child: Slider(
                          value: posMs.clamp(0, maxMs),
                          max: maxMs,
                          onChangeStart: (v) =>
                              setState(() => _scrubValue = v),
                          onChanged: (v) => setState(() => _scrubValue = v),
                          onChangeEnd: (v) {
                            _controller!
                                .seekTo(Duration(milliseconds: v.round()));
                            setState(() => _scrubValue = null);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          // Double-tap heart burst (Instagram-style).
          if (_showHeartBurst)
            IgnorePointer(
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.4, end: 1.0),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 96,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 24)],
                  ),
                ),
              ),
            ),
          // Action rail — fades out while paused so only the video and the
          // seekbar remain (clean scrub mode). The seekbar sits inside a
          // SafeArea, so on iOS the home-indicator inset lifts it — the rail
          // and author block must rise by the same inset or they overlap it.
          Positioned(
            right: 10,
            bottom: 64 + MediaQuery.of(context).padding.bottom,
            child: IgnorePointer(
              ignoring: _showPlayHint,
              child: AnimatedOpacity(
                opacity: _showPlayHint ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      iconPath: post.isLiked
                          ? 'assets/icons/like.png'
                          : 'assets/icons/unlike.png',
                      label: _compact(post.likesCount),
                      onTap: _handleLike,
                      applyGrayFill: !post.isLiked,
                    ),
                    const SizedBox(height: 18),
                    _ActionButton(
                      iconPath: 'assets/icons/comments.png',
                      label: _compact(_commentsCount),
                      onTap: _openCommentsSheet,
                    ),
                    const SizedBox(height: 18),
                    if (!_isOwnPost()) ...[
                      _ActionButton(
                        iconPath: 'assets/icons/gift.png',
                        label: 'Gift',
                        onTap: () {
                          // ignore: discarded_futures
                          _openGiftSheet();
                        },
                      ),
                      const SizedBox(height: 18),
                    ],
                    _ActionButton(
                      iconPath: 'assets/icons/share.png',
                      label: 'Share',
                      onTap: _handleShare,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Author + caption block — sits just above the seekbar with a small
          // consistent gap on every device. The seekbar occupies ~36px above
          // the safe area (bottom:10 + 26 height), so clearing it needs ~46px.
          Positioned(
            left: 14,
            right: 78,
            bottom: 46 + MediaQuery.of(context).padding.bottom,
            child: IgnorePointer(
              ignoring: _showPlayHint,
              child: AnimatedOpacity(
                opacity: _showPlayHint ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Pause video before navigating
                        _controller?.pause();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(
                              userId: post.user.uuid ?? post.user.id.toString(),
                            ),
                          ),
                        ).then((_) {
                          // Resume video when returning if still active
                          if (mounted && widget.isActive) {
                            _controller?.play();
                          }
                        });
                      },
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            // Reels-style author row: avatar chip before the name.
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.9),
                                        width: 1.5),
                                  ),
                                  child: ClipOval(
                                    child: ((post.user.avatar ??
                                                    post.user.image) ??
                                                '')
                                            .isNotEmpty
                                        ? Image.network(
                                            (post.user.avatar ??
                                                post.user.image)!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                const _AvatarFallback(),
                                          )
                                        : const _AvatarFallback(),
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(
                              text: post.user.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade600,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.18)),
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
                            // Inline follow beside the name. Hidden entirely
                            // when the data already says we follow them; after
                            // a tap it reads "Following" for this session only
                            // (next load the API reports is_following=true and
                            // the button simply doesn't render).
                            if (!_isOwnPost() &&
                                !widget.post.user.isFollowing) ...[
                              const TextSpan(text: '  '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: GestureDetector(
                                  onTap: _isFollowing ? null : _handleFollow,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: _isFollowing
                                          ? Colors.white.withValues(alpha: 0.14)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                            alpha: _isFollowing ? 0.25 : 0.85),
                                        width: 1.1,
                                      ),
                                    ),
                                    child: Text(
                                      _isFollowing ? 'Following' : 'Follow',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                            alpha: _isFollowing ? 0.7 : 1.0),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Title removed — show only the description, like the BN feed.
                    if (post.content.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(
                            () => _captionExpanded = !_captionExpanded),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: _captionExpanded
                                ? MediaQuery.of(context).size.height * 0.3
                                : double.infinity,
                          ),
                          child: SingleChildScrollView(
                            physics: _captionExpanded
                                ? const BouncingScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                            child: Text(
                              // Strip HTML — captions written on the web can
                              // carry <p class="text-wrap"> wrappers.
                              HtmlContentUtils.toPlainText(post.content),
                              // Collapsed = a single tidy line; "আরো পড়ুন"
                              // expands upward to the full caption.
                              maxLines: _captionExpanded ? null : 1,
                              overflow: _captionExpanded
                                  ? TextOverflow.visible
                                  : TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Long captions get an explicit reels-style toggle.
                      if (post.content.trim().length > 90 ||
                          post.title.length > 70) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => setState(
                              () => _captionExpanded = !_captionExpanded),
                          child: Text(
                            _captionExpanded ? 'কম দেখুন' : 'আরো পড়ুন',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
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
  }) : assert(iconPath != null || materialIcon != null,
            'Either iconPath or materialIcon must be provided');

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
          const SizedBox(height: 5),
          SizedBox(
            width: 56,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF334155),
      child: const Icon(Icons.person_rounded, size: 20, color: Colors.white70),
    );
  }
}
