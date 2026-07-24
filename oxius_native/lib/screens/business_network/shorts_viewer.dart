import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:video_player/video_player.dart';
import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import '../../services/auth_service.dart';
import '../../services/ads_service.dart';
import '../../services/house_ads_service.dart';
import '../../widgets/ads/house_ad_card.dart';
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
import 'package:oxius_native/widgets/common/adsy_pro_badge.dart';

class ShortsViewer extends StatefulWidget {
  final List<BusinessNetworkPost> posts;
  final VoidCallback onClose;
  final void Function(BusinessNetworkPost post)? onLike;
  final void Function(BusinessNetworkPost post)? onComment;
  final void Function(BusinessNetworkPost post)? onShare;
  final String? initialVideoUrl;
  final Future<void> Function()? onRequestMore;
  final bool allLoaded;
  // 'discover' (ranked, all users) or 'following' (followed users only).
  final String feedScope;
  final void Function(String scope)? onFeedScopeChanged;

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
    this.feedScope = 'discover',
    this.onFeedScopeChanged,
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
  final BusinessNetworkPost? post;
  final PostMedia? media;
  // Non-null = this reel slot is a BOOSTED (sponsored) short.
  final HouseAd? boost;

  const _ShortItem({this.post, this.media, this.boost});

  bool get isBoost => boost != null;
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
    final idx = items.indexWhere((e) => e.media?.bestUrl == target);
    return idx < 0 ? 0 : idx;
  }

  // ── Boosted shorts: every N swipes ask the ads panel for a sponsored
  // short and slide it into the reel right after the current page. ──
  final Set<int> _boostCheckedIndexes = {};
  static const int _boostEvery = 6;

  Future<void> _maybeInsertBoost(int index) async {
    if (index <= 0 || index % _boostEvery != 0) return;
    if (_boostCheckedIndexes.contains(index)) return;
    _boostCheckedIndexes.add(index);
    final ad = await HouseAdsService.fetch('shorts_reel');
    final videoUrl = (ad?.boostedPost?['video_url'] ?? '').toString();
    if (!mounted || ad == null || videoUrl.isEmpty) return;
    setState(() {
      final at = (index + 1).clamp(0, _items.length);
      _items.insert(at, _ShortItem(boost: ad));
    });
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
    // The creator whose short the viewer just watched gets the revenue
    // share for this post-swipe ad view.
    final u = _items[index].post?.user;
    if (u != null) {
      HouseAdsService.track(
        eventType: 'impression',
        placement: 'shorts_fullscreen',
        source: 'admob',
        creatorId: u.uuid ?? u.id.toString(),
      );
    }
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
    final media = item.media;
    if (media == null) return 0; // sponsored slot — no views pill
    return _mediaViewsOverrides[media.id] ?? media.views;
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
    final existingIds =
        _items.where((e) => e.media != null).map((e) => e.media!.id).toSet();
    final fresh = incoming
        .where((e) => e.media != null && !existingIds.contains(e.media!.id))
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
      final media = item.media;
      if (media == null) continue; // sponsored slots manage their own player
      final mediaId = media.id;

      if (_preloadedControllers.containsKey(mediaId)) continue;
      // A live page already owns a controller for this media.
      if (_pageOwnedMediaIds.contains(mediaId)) continue;

      final url = media.bestUrl;
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
        final m = _items[idx].media;
        if (m != null) validIds.add(m.id);
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

  Widget _buildScopeTab(String label, String scope) {
    final active = widget.feedScope == scope;
    return GestureDetector(
      onTap: () => widget.onFeedScopeChanged?.call(scope),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.55),
                fontSize: 15,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
              ),
            ),
            const SizedBox(height: 3),
            Container(
              height: 2.5,
              width: 20,
              decoration: BoxDecoration(
                color: active ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Back arrow + Discover/Following tabs + views pill. Also shown on the
  /// empty state so the user can always switch tabs or leave.
  Widget _buildTopBar({required bool showViews}) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: widget.onClose,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildScopeTab('Discover', 'discover'),
                  const SizedBox(width: 6),
                  _buildScopeTab('Following', 'following'),
                ],
              ),
            ),
            if (showViews && _currentIndex < _items.length)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.16)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_outlined,
                        size: 16, color: Colors.white.withValues(alpha: 0.9)),
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
              )
            else
              // Balances the back button so the tabs stay centered.
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Container(
        color: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  widget.feedScope == 'following'
                      ? 'No videos from people you follow yet'
                      : 'No shorts yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            _buildTopBar(showViews: false),
          ],
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
              _maybeInsertBoost(i);
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
              // Boosted (sponsored) short — plays inline like any short.
              if (item.isBoost) {
                return _SponsoredShortPage(
                  key: ValueKey('boost_${item.boost!.id}_$index'),
                  ad: item.boost!,
                  isActive: index == _currentIndex,
                );
              }
              return _ShortVideoPage(
                key: ValueKey('short_${item.post!.id}_${item.media!.id}'),
                post: item.post!,
                media: item.media!,
                isActive: index == _currentIndex,
                preloadedController: _preloadedControllers[item.media!.id],
                onLike: widget.onLike,
                onComment: widget.onComment,
                onShare: widget.onShare,
                onViewsChanged: (nextViews) {
                  if (!mounted) return;
                  setState(() {
                    _mediaViewsOverrides[item.media!.id] = nextViews;
                  });
                },
                onControllerCreated: (controller) {
                  // Ownership moves to the page: out of the preload map, and
                  // marked so we never spin up a duplicate stream for it.
                  _preloadedControllers.remove(item.media!.id);
                  _pageOwnedMediaIds.add(item.media!.id);
                  _activeController = controller;
                },
                onControllerDisposed: () {
                  _pageOwnedMediaIds.remove(item.media!.id);
                },
              );
            },
          ),
          _buildTopBar(showViews: true),
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
  // Non-null = this is a BOOSTED short rendered from its REAL post: adds a
  // small 'Sponsored' label above the author row + the advertiser CTA chip
  // under the caption. Everything else behaves like a normal short.
  final HouseAd? sponsoredAd;

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
    this.sponsoredAd,
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

  // Sponsored banner above the author block (house ads only). The short's
  // creator earns the revenue share for its views.
  HouseAd? _bannerAd;
  bool _bannerRequested = false;
  bool _bannerTracked = false;

  Timer? _viewTimer;
  bool _viewCounted = false;

  String get _creatorId =>
      widget.post.user.uuid ?? widget.post.user.id.toString();

  // Rotates across shorts so only every 4th short carries a banner —
  // a banner on EVERY short fatigues users fast.
  static int _bannerSlotCounter = 0;

  Future<void> _loadBannerAd() async {
    // A boosted short is itself an ad — never stack a banner on top of it.
    if (widget.sponsoredAd != null) return;
    if (_bannerRequested) return;
    _bannerRequested = true;
    if (_bannerSlotCounter++ % 4 != 0) return;
    final ad = await HouseAdsService.fetch('shorts_banner');
    if (!mounted || ad == null) return;
    setState(() => _bannerAd = ad);
    if (widget.isActive && !_bannerTracked) {
      _bannerTracked = true;
      HouseAdsService.track(
        eventType: 'impression',
        placement: 'shorts_banner',
        adId: ad.id,
        creatorId: _creatorId,
      );
    }
  }

  // ✕-close on the shorts banner: apology chip for a moment, server mutes
  // the ad + its category for this user for 48h.
  bool _bannerApology = false;

  void _closeBannerAd() {
    final ad = _bannerAd;
    if (ad == null) return;
    HouseAdsService.track(
      eventType: 'close',
      placement: 'shorts_banner',
      adId: ad.id,
      creatorId: _creatorId,
    );
    setState(() => _bannerApology = true);
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) {
        setState(() {
          _bannerApology = false;
          _bannerAd = null;
        });
      }
    });
  }

  /// Tap on the banner → bottom sheet with the full ad details + CTA.
  void _openBannerAdSheet() {
    final ad = _bannerAd;
    if (ad == null) return;
    HouseAdsService.track(
      eventType: 'click',
      placement: 'shorts_banner',
      adId: ad.id,
      creatorId: _creatorId,
    );
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Feed-post style header — advertiser avatar + name up left,
              // Sponsored as the meta line.
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF1F5F9),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      ad.advertiser.isNotEmpty
                          ? ad.advertiser.characters.first.toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HouseAdCard.advertiserNameRow(ad, fontSize: 14),
                        const SizedBox(height: 1),
                        const Row(
                          children: [
                            Icon(Icons.campaign_outlined,
                                size: 12, color: Color(0xFF94A3B8)),
                            SizedBox(width: 3),
                            Text(
                              'Sponsored',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (ad.images.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    ad.images.first,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                ad.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (ad.description.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  ad.description,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF475569),
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              // Outline chip, left-aligned — no full-width filled bar.
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    HouseAdsService.track(
                      eventType: 'cta_click',
                      placement: 'shorts_banner',
                      adId: ad.id,
                      creatorId: _creatorId,
                    );
                    HouseAdCard.launchCta(ad);
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: const Color(0xFF111827).withValues(alpha: 0.06),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(HouseAdCard.ctaIcon(ad),
                            size: 15, color: const Color(0xFF111827)),
                        const SizedBox(width: 6),
                        Text(
                          ad.ctaLabel,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _post = widget.post;
    _commentsCount = widget.post.commentsCount;
    _viewsCount = widget.media.views;
    _isFollowing = widget.post.user.isFollowing;
    _init();
    if (widget.isActive) _loadBannerAd();
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
        _loadBannerAd();
        if (_bannerAd != null && !_bannerTracked) {
          _bannerTracked = true;
          HouseAdsService.track(
            eventType: 'impression',
            placement: 'shorts_banner',
            adId: _bannerAd!.id,
            creatorId: _creatorId,
          );
        }
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

  void _bumpShareCount() {
    if (!mounted) return;
    setState(() {
      _post = _post.copyWith(shareCount: _post.shareCount + 1);
    });
    // Propagate so the feed card shows the new count too (no reload).
    widget.onShare?.call(_post);
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
        imageUrl: _post.shareThumbUrl.isNotEmpty ? _post.shareThumbUrl : null,
        subject: 'Business Network Post',
        eyebrow: 'Business Network',
        hashtags: _post.tags.map((tag) => tag.tag).toList(),
        // Count non-repost shares (chat / external). Bump the rail counter
        // immediately — no reload needed to see the new total.
        onShared: () {
          BusinessNetworkService.trackShare(_post.sharedFrom?.id ?? _post.id);
          _bumpShareCount();
        },
        // Repost this short to the user's own profile/feed.
        onRepost: (caption) async {
          if (!AuthService.isAuthenticated) return false;
          final targetId = _post.sharedFrom?.id ?? _post.id;
          final result = await BusinessNetworkService.resharePost(
            targetId,
            caption: caption,
          );
          if (result != null) _bumpShareCount();
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
                child: _SmoothShortsSeekBar(
                  controller: _controller!,
                  emphasized: _showPlayHint,
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
          // While the caption is expanded, tapping anywhere outside it
          // collapses it. Sits BELOW the rail and author/caption overlays in
          // the stack, so those still win their own taps; it only exists
          // while expanded, so the normal play/pause tap is untouched.
          if (_captionExpanded)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(() => _captionExpanded = false),
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
                      label: _compact(post.shareCount),
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
    // ✕-closed banner: brief apology chip, then gone.
                    if (_bannerApology)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'দুঃখিত, বিজ্ঞাপনটি আপনার পছন্দ হয়নি জেনে।',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    // Sponsored ad card ABOVE the name section — styled like a
                    // feed/reel ad: creative thumbnail, 2-line headline, an
                    // "advertiser · Ad" line, ✕ (top) to mute + ⋯ (bottom) for
                    // options. Tapping the body opens the full details sheet.
                    if (_bannerAd != null && !_bannerApology)
                      GestureDetector(
                        onTap: _openBannerAdSheet,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.52),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Creative thumbnail — larger, like the reference.
                              ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: SizedBox(
                                  width: 54,
                                  height: 54,
                                  child: _bannerAd!.images.isNotEmpty
                                      ? Image.network(
                                          _bannerAd!.images.first,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const ColoredBox(
                                            color: Color(0x33FFFFFF),
                                            child: Icon(Icons.campaign_outlined,
                                                size: 22,
                                                color: Colors.white70),
                                          ),
                                        )
                                      : const ColoredBox(
                                          color: Color(0x33FFFFFF),
                                          child: Icon(Icons.campaign_outlined,
                                              size: 22, color: Colors.white70),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Headline + advertiser · Ad.
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _bannerAd!.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        height: 1.25,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _bannerAd!.advertiser.isNotEmpty
                                                ? _bannerAd!.advertiser
                                                : 'Sponsored',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.72),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const Text(
                                          '  ·  ',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          'Ad',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.72),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // ✕ (top) mutes the ad + category for 48h;
                              // ⋯ (bottom) opens the details/options sheet.
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: _closeBannerAd,
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.close_rounded,
                                          size: 16, color: Colors.white70),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: _openBannerAdSheet,
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.more_horiz_rounded,
                                          size: 16, color: Colors.white70),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Boosted short: small 'Sponsored' marker just above the
                    // author row — same typography as the fallback page.
                    if (widget.sponsoredAd != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Sponsored',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
                      // Avatar on the left; name + location stacked on the
                      // right so the address hugs the name, not the block.
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                                Container(
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
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                child: const AdsyProBadge(),
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
                                // Address hugs the name — same column, tiny gap.
                                if (post.user.locationLabel.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.location_on_rounded,
                                            size: 12.5,
                                            color: Colors.white
                                                .withValues(alpha: 0.7)),
                                        const SizedBox(width: 3),
                                        Flexible(
                                          child: Text(
                                            post.user.locationLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.78),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Title removed — show only the description, like the BN feed.
                    if (post.content.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      // AnimatedSize = the caption grows/shrinks smoothly
                      // instead of snapping. Collapsed: ONE line with the
                      // "আরো পড়ুন" toggle INLINE at the end of that line.
                      AnimatedSize(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topLeft,
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _captionExpanded = !_captionExpanded),
                          child: _captionExpanded
                              ? ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(context).size.height *
                                            0.3,
                                  ),
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          HtmlContentUtils.toPlainText(
                                              post.content),
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.86),
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w400,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'কম দেখুন',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.65),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        HtmlContentUtils.toPlainText(
                                            post.content),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.86),
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w400,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    if (post.content.trim().length > 40) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        'আরো পড়ুন',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.65),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                      ),
                    ],
                    // Boosted short: advertiser CTA under the caption — the
                    // same white outline chip the fallback page shows.
                    if (widget.sponsoredAd != null) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () {
                          HouseAdsService.track(
                            eventType: 'cta_click',
                            placement: 'shorts_reel',
                            adId: widget.sponsoredAd!.id,
                          );
                          HouseAdCard.launchCta(widget.sponsoredAd!);
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            // App-wide promo chip: icon + text, no border.
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(HouseAdCard.ctaIcon(widget.sponsoredAd!),
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                widget.sponsoredAd!.ctaLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

/// Seekbar that moves SMOOTHLY. The video controller only reports its
/// position every ~250-500ms (platform polling), so binding a Slider to it
/// directly makes the dot jump in visible steps. This widget interpolates:
/// every frame (Ticker) it estimates the position as
/// `lastReportedPosition + wall-clock elapsed × playbackSpeed`, re-anchoring
/// whenever the controller reports a fresh position.
class _SmoothShortsSeekBar extends StatefulWidget {
  final VideoPlayerController controller;
  // True while paused (scrub mode) — thicker track and bigger dot.
  final bool emphasized;

  const _SmoothShortsSeekBar({
    required this.controller,
    required this.emphasized,
  });

  @override
  State<_SmoothShortsSeekBar> createState() => _SmoothShortsSeekBarState();
}

class _SmoothShortsSeekBarState extends State<_SmoothShortsSeekBar>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  // Non-null while the user drags the dot (milliseconds position).
  double? _scrubValue;
  Duration _anchorPosition = Duration.zero;
  DateTime _anchorTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (mounted) setState(() {});
    });
    widget.controller.addListener(_onVideoUpdate);
    _onVideoUpdate();
  }

  @override
  void didUpdateWidget(covariant _SmoothShortsSeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onVideoUpdate);
      widget.controller.addListener(_onVideoUpdate);
      _onVideoUpdate();
    }
  }

  void _onVideoUpdate() {
    if (!mounted) return;
    final value = widget.controller.value;
    // Re-anchor the estimate on every real position report.
    _anchorPosition = value.position;
    _anchorTime = DateTime.now();
    // Tick only while playing — no battery burn on paused videos.
    if (value.isPlaying && !_ticker.isActive) {
      _ticker.start();
    } else if (!value.isPlaying && _ticker.isActive) {
      _ticker.stop();
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onVideoUpdate);
    _ticker.dispose();
    super.dispose();
  }

  double _estimatedPositionMs(VideoPlayerValue value, double maxMs) {
    if (!value.isPlaying) {
      return value.position.inMilliseconds.toDouble().clamp(0, maxMs);
    }
    final elapsedMs = DateTime.now().difference(_anchorTime).inMilliseconds *
        value.playbackSpeed;
    return (_anchorPosition.inMilliseconds + elapsedMs).clamp(0, maxMs);
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    final maxMs = value.duration.inMilliseconds.toDouble();
    if (maxMs <= 0) return const SizedBox.shrink();

    final posMs = _scrubValue ?? _estimatedPositionMs(value, maxMs);
    final scrubbing = _scrubValue != null;
    final emphasized = scrubbing || widget.emphasized;

    return SizedBox(
      height: 26,
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: emphasized ? 4 : 2.5,
          activeTrackColor: Colors.white,
          inactiveTrackColor: Colors.white.withValues(alpha: 0.25),
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
          onChangeStart: (v) => setState(() => _scrubValue = v),
          onChanged: (v) => setState(() => _scrubValue = v),
          onChangeEnd: (v) {
            widget.controller.seekTo(Duration(milliseconds: v.round()));
            // Anchor to the seek target so the dot doesn't snap back to the
            // pre-seek position while the platform catches up.
            _anchorPosition = Duration(milliseconds: v.round());
            _anchorTime = DateTime.now();
            setState(() => _scrubValue = null);
          },
        ),
      ),
    );
  }
}

/// A BOOSTED short — an advertiser-promoted BN short playing inline in the
/// reel like any other short, marked "Sponsored" with author info and a CTA.
/// Billable impression fires after 3s of actual playback.
class _SponsoredShortPage extends StatefulWidget {
  final HouseAd ad;
  final bool isActive;

  const _SponsoredShortPage({super.key, required this.ad, required this.isActive});

  @override
  State<_SponsoredShortPage> createState() => _SponsoredShortPageState();
}

class _SponsoredShortPageState extends State<_SponsoredShortPage> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _billed = false;
  Timer? _billableTimer;

  // The REAL boosted post — fetched on mount so the page can re-render as a
  // genuine _ShortVideoPage (like/comment/gift/share all live) with just the
  // 'Sponsored' label + CTA layered on. Until it lands (or if it fails) the
  // minimal fallback below keeps playing.
  BusinessNetworkPost? _realPost;
  PostMedia? _realMedia;

  String get _videoUrl =>
      (widget.ad.boostedPost?['video_url'] ?? '').toString();
  String get _authorName =>
      (widget.ad.boostedPost?['author_name'] ?? '').toString();
  String get _authorAvatar =>
      (widget.ad.boostedPost?['author_avatar'] ?? '').toString();
  String get _caption =>
      (widget.ad.boostedPost?['content'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _init();
    _fetchRealPost();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(_videoUrl));
      _controller = c;
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(widget.isActive ? 1.0 : 0.0);
      // The real post arrived while we were initializing — the real page
      // owns playback now, so drop this fallback player.
      if (!mounted || _realPost != null) {
        c.dispose();
        return;
      }
      setState(() => _ready = true);
      if (widget.isActive) {
        c.play();
        _armBillable();
      }
    } catch (e) {
      debugPrint('[boost] video init failed: $e');
    }
  }

  Future<void> _fetchRealPost() async {
    final id = (widget.ad.boostedPost?['id'] ?? '').toString();
    if (id.isEmpty) return;
    final post = await BusinessNetworkService.getPostByIdentifier(id);
    if (!mounted || post == null) return;
    final videos = post.media.where((m) => m.isVideo).toList();
    if (videos.isEmpty) return;
    final media = videos.firstWhere(
      (m) => m.bestUrl == _videoUrl,
      orElse: () => videos.first,
    );
    final old = _controller;
    final wasReady = _ready;
    _controller = null;
    setState(() {
      _realPost = post;
      _realMedia = media;
    });
    // Only dispose a fully initialized fallback player here — if _init is
    // still in flight it sees _realPost and disposes its own controller.
    if (wasReady) old?.dispose();
  }

  void _armBillable() {
    if (_billed) return;
    _billableTimer?.cancel();
    _billableTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || _billed || !widget.isActive) return;
      _billed = true;
      HouseAdsService.track(
        eventType: 'impression',
        placement: 'shorts_reel',
        adId: widget.ad.id,
      );
    });
  }

  @override
  void didUpdateWidget(covariant _SponsoredShortPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _controller?.setVolume(1.0);
        _controller?.play();
        _armBillable();
      } else {
        _controller?.pause();
        _billableTimer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _billableTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  /// Boosted post's author avatar/name → their BN profile.
  void _openAuthorProfile() {
    final id = (widget.ad.boostedPost?['author_id'] ?? '').toString();
    if (id.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: id)),
    );
  }

  void _onCta() {
    HouseAdsService.track(
      eventType: 'cta_click',
      placement: 'shorts_reel',
      adId: widget.ad.id,
    );
    HouseAdCard.launchCta(widget.ad);
  }

  @override
  Widget build(BuildContext context) {
    // Real post loaded — render the SAME page normal shorts use, so every
    // action (like/comment/gift/share/follow/profile) works for real. The
    // billable-impression timer stays armed in this state either way.
    if (_realPost != null && _realMedia != null) {
      return _ShortVideoPage(
        post: _realPost!,
        media: _realMedia!,
        isActive: widget.isActive,
        sponsoredAd: widget.ad,
      );
    }
    final c = _controller;
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_ready && c != null)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            )
          else
            const Center(
              child: AdsyLoadingIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                strokeWidth: 2.5,
              ),
            ),
          // Bottom gradient + sponsored info + CTA.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  14, 40, 14, 18 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _openAuthorProfile,
                        child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF334155),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.9),
                              width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _authorAvatar.isNotEmpty
                            ? Image.network(_authorAvatar,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person_rounded,
                                    size: 20,
                                    color: Colors.white70))
                            : const Icon(Icons.person_rounded,
                                size: 20, color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: _openAuthorProfile,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _authorName.isNotEmpty
                                          ? _authorName
                                          : widget.ad.advertiser,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (widget.ad.advertiserVerified) ...[
                                    const SizedBox(width: 3),
                                    const Icon(Icons.verified,
                                        size: 15, color: Color(0xFF60A5FA)),
                                  ],
                                  if (widget.ad.advertiserPro) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        'Pro',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              'Sponsored',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_caption.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Small outline chip, left-aligned — the boost looks like a
                  // normal short; only this chip + "Sponsored" mark it.
                  InkWell(
                    onTap: _onCta,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        // Soft translucent chip on the dark video — icon +
                        // text, no border (matches the app-wide promo style).
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(HouseAdCard.ctaIcon(widget.ad),
                              size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            widget.ad.ctaLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
        ],
      ),
    );
  }
}
