import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/business_network_models.dart';
import '../../services/auth_service.dart';
import '../../services/fcm_service.dart';
import '../../utils/business_network_media_downloader.dart';
import '../../widgets/business_network/bottom_nav_bar.dart';
import 'create_post_screen.dart';
import 'notifications_screen.dart';
import 'profile_options.dart';
import 'shorts_player_screen.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

class PostMediaViewerScreen extends StatefulWidget {
  final BusinessNetworkPost post;
  final int initialIndex;

  const PostMediaViewerScreen({
    super.key,
    required this.post,
    required this.initialIndex,
  });

  @override
  State<PostMediaViewerScreen> createState() => _PostMediaViewerScreenState();
}

class _PostMediaViewerScreenState extends State<PostMediaViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  late BusinessNetworkPost _post;

  /// Top bar + bottom bar visibility (Instagram-style tap-to-toggle chrome).
  bool _chromeVisible = true;

  /// True while the current photo is pinch/double-tap zoomed in — paging and
  /// swipe-to-dismiss are suspended so the pan gesture belongs to the photo.
  bool _isZoomed = false;

  /// Vertical swipe-to-dismiss state.
  double _dragOffset = 0;
  bool _isDragging = false;

  static const double _dismissDragThreshold = 120.0;
  static const double _dismissVelocityThreshold = 900.0;
  static const Duration _chromeAnimDuration = Duration(milliseconds: 220);

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _currentIndex = widget.initialIndex
        .clamp(0, _post.media.isEmpty ? 0 : _post.media.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleChrome() {
    setState(() {
      _chromeVisible = !_chromeVisible;
    });
  }

  void _handleZoomChanged(bool zoomed) {
    if (_isZoomed == zoomed) return;
    setState(() {
      _isZoomed = zoomed;
      // Hide chrome while inspecting a photo up close.
      if (zoomed) _chromeVisible = false;
    });
  }

  void _dismiss() {
    Navigator.pop(context, _post);
  }

  // ---------------------------------------------------------------------
  // Swipe-down (or up) to dismiss
  // ---------------------------------------------------------------------

  void _onVerticalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final flungAway = velocity.abs() > _dismissVelocityThreshold &&
        velocity.sign == _dragOffset.sign;
    if (_dragOffset.abs() > _dismissDragThreshold || flungAway) {
      _dismiss();
      return;
    }
    setState(() {
      _dragOffset = 0;
      _isDragging = false;
    });
  }

  double get _dragProgress {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight <= 0) return 0;
    return (_dragOffset.abs() / (screenHeight * 0.5)).clamp(0.0, 1.0);
  }

  // ---------------------------------------------------------------------
  // Existing behaviors (video → shorts, bottom nav, download options)
  // ---------------------------------------------------------------------

  void _openShorts(PostMedia media) {
    // ignore: discarded_futures
    _openShortsAsync(media);
  }

  Future<void> _openShortsAsync(PostMedia media) async {
    final updates = await Navigator.push<Map<int, BusinessNetworkPost>?>(
      context,
      MaterialPageRoute(
        builder: (context) => ShortsPlayerScreen(
          initialPost: _post,
          initialMedia: media,
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
  }

  void _handleNavTap(int index) {
    final isLoggedIn = AuthService.isAuthenticated;
    final rootNavigator =
        FCMService.navigatorKey.currentState ?? Navigator.of(context);

    switch (index) {
      case 0:
        rootNavigator.pushNamedAndRemoveUntil(
          '/business-network',
          (route) => route.isFirst,
        );
        break;
      case 1:
        if (isLoggedIn) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const NotificationsScreen()),
          );
        } else {
          Navigator.pushNamed(context, '/login');
        }
        break;
      case 2:
        if (isLoggedIn) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        } else {
          Navigator.pushNamed(context, '/login');
        }
        break;
      case 3:
        if (isLoggedIn) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ProfileOptionsScreen()),
          );
        } else {
          Navigator.pushNamed(context, '/login');
        }
        break;
      case 4:
        rootNavigator.pushNamedAndRemoveUntil('/', (route) => false);
        break;
    }
  }

  void _showMediaOptions() {
    if (_post.media.isEmpty) return;
    final media = _post.media[_currentIndex];

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
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.download_rounded,
                    color: Color(0xFF3B82F6)),
                title:
                    Text(media.isVideo ? 'Download Video' : 'Download Photo'),
                onTap: () {
                  Navigator.pop(context);
                  BusinessNetworkMediaDownloader.download(
                    this.context,
                    media,
                    ownerName: _post.user.name,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Media pages
  // ---------------------------------------------------------------------

  Widget _buildVideoThumbFallback() {
    return Container(
      color: const Color(0xFF111111),
      child: Center(
        child: Icon(
          Icons.videocam_off_rounded,
          color: Colors.white.withValues(alpha: 0.3),
          size: 40,
        ),
      ),
    );
  }

  Widget _buildVideoPreview(PostMedia media) {
    final thumbUrl = media.bestThumbnailUrl;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleChrome,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumbUrl.isNotEmpty)
            Image.network(
              thumbUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildVideoThumbFallback();
              },
            )
          else
            _buildVideoThumbFallback(),
          Center(
            child: GestureDetector(
              onTap: () => _openShorts(media),
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChromeButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Semantics(
      label: tooltip,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final chromeShown = _chromeVisible && !_isDragging;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: !chromeShown,
        child: AnimatedOpacity(
          opacity: chromeShown ? 1.0 : 0.0,
          duration: _chromeAnimDuration,
          curve: Curves.easeOut,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _buildChromeButton(
                      icon: Icons.close_rounded,
                      onTap: _dismiss,
                      tooltip: 'Close',
                    ),
                    Expanded(
                      child: Center(
                        child: _post.media.length > 1
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${_currentIndex + 1}/${_post.media.length}',
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.95),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    _buildChromeButton(
                      icon: Icons.more_horiz_rounded,
                      onTap: _showMediaOptions,
                      tooltip: 'More options',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final chromeShown = _chromeVisible && !_isDragging;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: !chromeShown,
        child: AnimatedSlide(
          offset: chromeShown ? Offset.zero : const Offset(0, 1),
          duration: _chromeAnimDuration,
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: chromeShown ? 1.0 : 0.0,
            duration: _chromeAnimDuration,
            curve: Curves.easeOut,
            child: BusinessNetworkBottomNavBar(
              currentIndex: 0,
              isLoggedIn: AuthService.isAuthenticated,
              unreadCount: 0,
              onTap: _handleNavTap,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGallery() {
    // Vertical dismiss gesture is only armed when the photo is not zoomed —
    // while zoomed the InteractiveViewer owns the pan gesture.
    final dismissEnabled = !_isZoomed;
    final progress = _dragProgress;
    final scale = 1.0 - (progress * 0.2);

    return GestureDetector(
      onVerticalDragStart: dismissEnabled ? _onVerticalDragStart : null,
      onVerticalDragUpdate: dismissEnabled ? _onVerticalDragUpdate : null,
      onVerticalDragEnd: dismissEnabled ? _onVerticalDragEnd : null,
      child: AnimatedContainer(
        duration: _isDragging
            ? Duration.zero
            : const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translateByDouble(0.0, _dragOffset, 0.0, 1.0)
          ..scaleByDouble(scale, scale, 1.0, 1.0),
        transformAlignment: Alignment.center,
        child: PageView.builder(
          controller: _pageController,
          physics: _isZoomed
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          itemCount: _post.media.length,
          onPageChanged: (i) {
            setState(() {
              _currentIndex = i;
            });
          },
          itemBuilder: (context, index) {
            final media = _post.media[index];
            if (media.isVideo) {
              return _buildVideoPreview(media);
            }
            return _ZoomablePhoto(
              media: media,
              onTap: _toggleChrome,
              onZoomChanged: _handleZoomChanged,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final backgroundOpacity = 1.0 - (_dragProgress * 0.5);

    return PopScope<BusinessNetworkPost>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, BusinessNetworkPost? result) {
        if (didPop) return;
        Navigator.pop(context, _post);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.black,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          extendBodyBehindAppBar: true,
          body: Container(
            color: Colors.black.withValues(alpha: backgroundOpacity),
            child: _post.media.isEmpty
                ? Center(
                    child: Text(
                      'No media',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  )
                : Stack(
                    children: [
                      Positioned.fill(child: _buildGallery()),
                      _buildTopBar(),
                      if (isMobile) _buildBottomBar(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen photo with pinch-to-zoom and double-tap-to-zoom, matching the
/// gesture behavior of Instagram/Facebook photo viewers.
class _ZoomablePhoto extends StatefulWidget {
  final PostMedia media;
  final VoidCallback onTap;
  final ValueChanged<bool> onZoomChanged;

  const _ZoomablePhoto({
    required this.media,
    required this.onTap,
    required this.onZoomChanged,
  });

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late final AnimationController _zoomAnimationController;
  Animation<Matrix4>? _zoomAnimation;
  TapDownDetails? _doubleTapDetails;
  bool _isZoomed = false;

  static const double _doubleTapScale = 2.5;
  static const double _maxScale = 5.0;

  @override
  void initState() {
    super.initState();
    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        final animation = _zoomAnimation;
        if (animation != null) {
          _transformationController.value = animation.value;
        }
      });
    _transformationController.addListener(_handleTransformChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_handleTransformChanged);
    _transformationController.dispose();
    _zoomAnimationController.dispose();
    super.dispose();
  }

  void _handleTransformChanged() {
    final zoomed =
        _transformationController.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed == _isZoomed) return;
    setState(() {
      _isZoomed = zoomed;
    });
    widget.onZoomChanged(zoomed);
  }

  void _handleDoubleTap() {
    final position = _doubleTapDetails?.localPosition;
    final current = _transformationController.value;

    final Matrix4 target;
    if (_isZoomed || position == null) {
      target = Matrix4.identity();
    } else {
      // Zoom in centered on the tap position.
      target = Matrix4.identity()
        ..translateByDouble(
          -position.dx * (_doubleTapScale - 1),
          -position.dy * (_doubleTapScale - 1),
          0.0,
          1.0,
        )
        ..scaleByDouble(
            _doubleTapScale, _doubleTapScale, 1.0, 1.0);
    }

    _zoomAnimation = Matrix4Tween(begin: current, end: target).animate(
      CurvedAnimation(
        parent: _zoomAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _zoomAnimationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        // Pan only while zoomed in, so horizontal page swipes and vertical
        // swipe-to-dismiss keep working at rest scale.
        panEnabled: _isZoomed,
        minScale: 1.0,
        maxScale: _maxScale,
        child: SizedBox.expand(
          child: Image.network(
            widget.media.bestUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: AdsyLoadingIndicator(color: Colors.white),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text(
                  'Failed to load media',
                  style:
                      TextStyle(color: Colors.white.withValues(alpha: 0.75)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
