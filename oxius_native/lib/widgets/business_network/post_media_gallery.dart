import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../models/business_network_models.dart';

const Map<String, String> _kMediaHeaders = {'User-Agent': 'OxiUsFlutter/1.0'};

class PostMediaGallery extends StatelessWidget {
  final List<PostMedia> media;
  final Function(int) onMediaTap;

  const PostMediaGallery({
    super.key,
    required this.media,
    required this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildMediaLayout(context),
      ),
    );
  }

  Widget _buildMediaLayout(BuildContext context) {
    if (media.length == 1) {
      final item = media[0];
      if (item.isVideo) {
        return _buildSingleVideo(context, 0);
      }
      return _buildSingleImage(context, 0);
    } else if (media.length == 2) {
      return _buildTwoImages(context);
    } else if (media.length == 3) {
      return _buildThreeImages(context);
    } else if (media.length == 4) {
      return _buildFourImages(context);
    } else {
      return _buildFiveOrMoreImages(context);
    }
  }

  Widget _buildMediaContent(
    BuildContext context,
    int index, {
    required BoxFit fit,
    double errorIconSize = 48,
  }) {
    final item = media[index];
    final imageUrl = item.bestThumbnailUrl;

    if (imageUrl.isEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: item.isVideo
                ? BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.grey.shade800, Colors.grey.shade900],
                    ),
                  )
                : null,
            color: item.isVideo ? null : Colors.grey.shade200,
          ),
          Center(
            child: Icon(
              item.isVideo ? Icons.play_circle_fill_rounded : Icons.image,
              size: errorIconSize,
              color: item.isVideo ? Colors.white.withValues(alpha: 0.9) : Colors.grey,
            ),
          ),
          if (item.isVideo)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 12),
              ),
            ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Disk + memory cached, decoded at a capped width so full-res photos
        // never blow up memory or re-download on every scroll.
        CachedNetworkImage(
          imageUrl: imageUrl,
          httpHeaders: _kMediaHeaders,
          fit: fit,
          width: double.infinity,
          memCacheWidth: 1080,
          fadeInDuration: const Duration(milliseconds: 120),
          placeholder: (context, url) =>
              Container(color: Colors.grey.shade200),
          errorWidget: (context, url, error) {
            return Container(
              color: Colors.grey.shade200,
              child: Center(
                child: Icon(
                  item.isVideo ? Icons.play_circle_fill_rounded : Icons.image,
                  size: errorIconSize,
                  color: item.isVideo ? Colors.grey.shade700 : Colors.grey,
                ),
              ),
            );
          },
        ),
        if (item.isVideo)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 12),
            ),
          ),
        if (item.isVideo)
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSingleImage(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => onMediaTap(index),
      child: _AdaptiveAspectRatioBox(
        imageUrl: media[index].bestThumbnailUrl,
        minHeight: 180,
        maxHeight: 520,
        child: _buildMediaContent(
          context,
          index,
          fit: BoxFit.cover,
          errorIconSize: 48,
        ),
      ),
    );
  }

  Widget _buildSingleVideo(BuildContext context, int index) {
    // The preview sizes ITSELF to the video's aspect ratio (clamped), exactly
    // like a single image — no fixed box, so wide videos no longer show dark
    // letterbox bars.
    return AutoPlaySingleVideoPreview(
      media: media[index],
      minHeight: 200,
      maxHeight: 520,
      onTap: () => onMediaTap(index),
    );
  }

  Widget _buildTwoImages(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 350,
        minHeight: 200,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onMediaTap(0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: _buildMediaContent(
                    context,
                    0,
                    fit: BoxFit.cover,
                    errorIconSize: 48,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: GestureDetector(
                onTap: () => onMediaTap(1),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: _buildMediaContent(
                    context,
                    1,
                    fit: BoxFit.cover,
                    errorIconSize: 48,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreeImages(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 350,
        minHeight: 200,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => onMediaTap(0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: _buildMediaContent(
                    context,
                    0,
                    fit: BoxFit.cover,
                    errorIconSize: 48,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onMediaTap(1),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: _buildMediaContent(
                          context,
                          1,
                          fit: BoxFit.cover,
                          errorIconSize: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onMediaTap(2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: _buildMediaContent(
                          context,
                          2,
                          fit: BoxFit.cover,
                          errorIconSize: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFourImages(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 350,
        minHeight: 200,
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onMediaTap(0),
                    child: _buildMediaContent(
                      context,
                      0,
                      fit: BoxFit.cover,
                      errorIconSize: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onMediaTap(1),
                    child: _buildMediaContent(
                      context,
                      1,
                      fit: BoxFit.cover,
                      errorIconSize: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onMediaTap(2),
                    child: _buildMediaContent(
                      context,
                      2,
                      fit: BoxFit.cover,
                      errorIconSize: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onMediaTap(3),
                    child: _buildMediaContent(
                      context,
                      3,
                      fit: BoxFit.cover,
                      errorIconSize: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiveOrMoreImages(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 350,
        minHeight: 200,
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onMediaTap(0),
                    child: _buildMediaContent(
                      context,
                      0,
                      fit: BoxFit.cover,
                      errorIconSize: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onMediaTap(1),
                    child: _buildMediaContent(
                      context,
                      1,
                      fit: BoxFit.cover,
                      errorIconSize: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onMediaTap(2),
                    child: _buildMediaContent(
                      context,
                      2,
                      fit: BoxFit.cover,
                      errorIconSize: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onMediaTap(3),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildMediaContent(
                          context,
                          3,
                          fit: BoxFit.cover,
                          errorIconSize: 32,
                        ),
                        if (media.length > 4)
                          Container(
                            color: Colors.black.withValues(alpha: 0.6),
                            child: Center(
                              child: Text(
                                '+${media.length - 4}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdaptiveAspectRatioBox extends StatefulWidget {
  final String imageUrl;
  final double minHeight;
  final double maxHeight;
  final Widget child;

  const _AdaptiveAspectRatioBox({
    required this.imageUrl,
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  State<_AdaptiveAspectRatioBox> createState() => _AdaptiveAspectRatioBoxState();
}

class _AdaptiveAspectRatioBoxState extends State<_AdaptiveAspectRatioBox> {
  double? _aspectRatio;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _AdaptiveAspectRatioBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _removeListener();
      _aspectRatio = null;
      _resolve();
    }
  }

  void _removeListener() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
  }

  void _resolve() {
    final url = widget.imageUrl.trim();
    if (url.isEmpty) return;

    // Reuse the SAME cached image the tile displays, so measuring the aspect
    // ratio doesn't trigger a second network fetch of the photo.
    final provider = CachedNetworkImageProvider(url, headers: _kMediaHeaders);

    final stream = provider.resolve(const ImageConfiguration());
    _stream = stream;

    final listener = ImageStreamListener(
      (info, _) {
        final img = info.image;
        if (img.width == 0 || img.height == 0) return;
        final ratio = img.width / img.height;
        if (!mounted) return;
        setState(() {
          _aspectRatio = ratio;
        });
      },
      onError: (_, __) {},
    );

    _listener = listener;
    stream.addListener(listener);
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        var ratio = (_aspectRatio ?? 1.0);
        if (ratio <= 0) ratio = 1.0;

        final expectedH = maxW / ratio;
        if (expectedH > widget.maxHeight) {
          ratio = maxW / widget.maxHeight;
        } else if (expectedH < widget.minHeight) {
          ratio = maxW / widget.minHeight;
        }

        return AspectRatio(
          aspectRatio: ratio,
          child: widget.child,
        );
      },
    );
  }
}

class AutoPlaySingleVideoPreview extends StatefulWidget {
  final PostMedia media;
  final double minHeight;
  final double maxHeight;
  final VoidCallback? onTap;

  const AutoPlaySingleVideoPreview({
    super.key,
    required this.media,
    this.minHeight = 200,
    this.maxHeight = 520,
    this.onTap,
  });

  @override
  State<AutoPlaySingleVideoPreview> createState() => AutoPlaySingleVideoPreviewState();
}

class AutoPlaySingleVideoPreviewState extends State<AutoPlaySingleVideoPreview> {
  /// Feed-wide mute preference: muting one video mutes every video the user
  /// scrolls to next (and survives feed rebuilds), like Facebook's feed.
  static final ValueNotifier<bool> feedMuted = ValueNotifier<bool>(false);

  VideoPlayerController? _controller;
  bool _isInitialized = false;
  // Aspect ratio measured from the thumbnail so the box is sized correctly even
  // before the video controller finishes initializing.
  double? _thumbAspect;
  // Once known, the box keeps this shape forever — prevents the feed jumping
  // when the video's own aspect arrives after initialization.
  double? _lockedAspect;
  bool _hasError = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    // Only measure the thumbnail up front (cheap). The heavy video controller
    // is created lazily the first time the tile scrolls near the viewport.
    _resolveThumbAspect();
    feedMuted.addListener(_applyMute);
  }

  void _applyMute() {
    final c = _controller;
    if (c != null && _isInitialized) {
      c.setVolume(feedMuted.value ? 0.0 : 1.0);
    }
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant AutoPlaySingleVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media.bestUrl != widget.media.bestUrl) {
      _disposeController();
      _isInitialized = false;
      _hasError = false;
      _thumbAspect = null;
      _resolveThumbAspect();
      if (_isVisible) _init();
    }
  }

  void _resolveThumbAspect() {
    final url = widget.media.bestThumbnailUrl.trim();
    if (url.isEmpty) return;
    final provider = CachedNetworkImageProvider(url, headers: _kMediaHeaders);
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      final img = info.image;
      if (img.height != 0 && mounted) {
        setState(() {
          _thumbAspect = img.width / img.height;
          // Lock the box to the thumbnail's shape — the thumb is a frame of
          // the video, so the aspect matches and the card never resizes when
          // the video finishes loading.
          _lockedAspect ??= _thumbAspect;
        });
      }
      stream.removeListener(listener);
    }, onError: (_, __) => stream.removeListener(listener));
    stream.addListener(listener);
  }

  Future<void> _init() async {
    if (_controller != null) return; // already initializing/initialized
    try {
      final url = widget.media.bestUrl;
      if (url.isEmpty) {
        if (!mounted) return;
        setState(() => _hasError = true);
        return;
      }

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: const {
          'User-Agent': 'OxiUsFlutter/1.0',
        },
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);
      // Honour the sticky feed-wide mute choice.
      await controller.setVolume(feedMuted.value ? 0.0 : 1.0);

      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _isInitialized = true;
        _hasError = false;
        // No thumbnail case: lock to the video's real shape (single, animated
        // resize instead of repeated jumps).
        if (controller.value.aspectRatio > 0) {
          _lockedAspect ??= controller.value.aspectRatio;
        }
      });

      _updatePlayback();
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  void _updatePlayback() {
    final c = _controller;
    if (c == null || !_isInitialized) return;

    if (_isVisible) {
      if (!c.value.isPlaying) {
        c.play();
      }
    } else {
      if (c.value.isPlaying) {
        c.pause();
      }
    }
  }

  void _disposeController() {
    final c = _controller;
    _controller = null;
    c?.dispose();
  }

  @override
  void dispose() {
    feedMuted.removeListener(_applyMute);
    _disposeController();
    super.dispose();
  }

  /// Best-known aspect ratio. Locked after first measurement so the card
  /// keeps a stable size; otherwise: video's, then thumbnail's, then 16:9.
  double get _aspect {
    if (_lockedAspect != null && _lockedAspect! > 0) return _lockedAspect!;
    final c = _controller;
    if (c != null && _isInitialized && c.value.aspectRatio > 0) {
      return c.value.aspectRatio;
    }
    return (_thumbAspect != null && _thumbAspect! > 0) ? _thumbAspect! : 16 / 9;
  }

  @override
  Widget build(BuildContext context) {
    final thumbUrl = widget.media.bestThumbnailUrl;
    final c = _controller;

    final stack = Stack(
      fit: StackFit.expand,
      children: [
        // Soft dark placeholder instead of a flat black slab, so a video with
        // a missing thumbnail still looks intentional while it loads.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF334155), Color(0xFF0F172A)],
            ),
          ),
        ),
        // Poster (cover-fills the box, no letterbox).
        if (thumbUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: thumbUrl,
            httpHeaders: _kMediaHeaders,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorWidget: (context, url, error) => const SizedBox.shrink(),
          ),
        // Video, cover-filled so it exactly covers the box (matches images).
        if (!_hasError && _isInitialized && c != null)
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            ),
          ),
        if (_hasError)
          Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              size: 48,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        // Play affordance while the video hasn't started.
        if (!_hasError && !(_isInitialized && (c?.value.isPlaying ?? false)))
          Center(
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.40),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 32),
            ),
          ),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: const Icon(Icons.videocam_rounded,
                color: Colors.white, size: 12),
          ),
        ),
        if (widget.onTap != null)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
            ),
          ),
        // Mute toggle — AFTER the full-bleed tap layer so it wins the tap.
        // The choice is feed-wide and sticky (see [feedMuted]).
        if (!_hasError && _isInitialized)
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => feedMuted.value = !feedMuted.value,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Icon(
                  feedMuted.value
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );

    return VisibilityDetector(
      key: ValueKey('bn_autoplay_${widget.media.id}_${widget.media.bestUrl}'),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        final frac = info.visibleFraction;
        // Create the controller lazily the moment the tile enters the viewport.
        if (frac > 0 && _controller == null && !_hasError) {
          _init();
        }
        final nextVisible = frac >= 0.6;
        if (nextVisible != _isVisible) {
          setState(() => _isVisible = nextVisible);
          _updatePlayback();
        }
        // Free the decoder once the tile is fully off-screen (memory + battery).
        if (frac == 0 && _controller != null) {
          _disposeController();
          setState(() => _isInitialized = false);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          var ratio = _aspect;
          final expectedH = maxW / ratio;
          if (expectedH > widget.maxHeight) {
            ratio = maxW / widget.maxHeight;
          } else if (expectedH < widget.minHeight) {
            ratio = maxW / widget.minHeight;
          }
          // AnimatedSize smooths the one-time settle when a video with no
          // thumbnail locks to its real shape.
          return AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: AspectRatio(aspectRatio: ratio, child: stack),
          );
        },
      ),
    );
  }
}
