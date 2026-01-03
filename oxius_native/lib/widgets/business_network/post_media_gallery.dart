import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../models/business_network_models.dart';

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
              color: item.isVideo ? Colors.white.withOpacity(0.9) : Colors.grey,
            ),
          ),
          if (item.isVideo)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
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
        Image.network(
          imageUrl,
          fit: fit,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
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
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
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
                color: Colors.black.withOpacity(0.45),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 500,
          minHeight: 200,
        ),
        child: _buildMediaContent(
          context,
          index,
          fit: BoxFit.contain,
          errorIconSize: 48,
        ),
      ),
    );
  }

  Widget _buildSingleVideo(BuildContext context, int index) {
    final item = media[index];
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 500,
        minHeight: 200,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _AutoPlaySingleVideoPreview(
            media: item,
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onMediaTap(index),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
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
                            color: Colors.black.withOpacity(0.6),
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

class _AutoPlaySingleVideoPreview extends StatefulWidget {
  final PostMedia media;

  const _AutoPlaySingleVideoPreview({required this.media});

  @override
  State<_AutoPlaySingleVideoPreview> createState() => _AutoPlaySingleVideoPreviewState();
}

class _AutoPlaySingleVideoPreviewState extends State<_AutoPlaySingleVideoPreview> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _AutoPlaySingleVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media.bestUrl != widget.media.bestUrl) {
      _disposeController();
      _isInitialized = false;
      _hasError = false;
      _init();
    }
  }

  Future<void> _init() async {
    try {
      final url = widget.media.bestUrl;
      if (url.isEmpty) {
        if (!mounted) return;
        setState(() => _hasError = true);
        return;
      }

      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(1.0);

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _hasError = false;
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
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thumbUrl = widget.media.bestThumbnailUrl;
    final c = _controller;

    Widget thumbFallback() {
      return Container(
        color: Colors.grey.shade300,
        child: Center(
          child: Icon(
            Icons.play_circle_fill_rounded,
            size: 48,
            color: Colors.black.withOpacity(0.35),
          ),
        ),
      );
    }

    return VisibilityDetector(
      key: ValueKey('bn_autoplay_${widget.media.id}_${widget.media.bestUrl}'),
      onVisibilityChanged: (info) {
        final nextVisible = info.visibleFraction >= 0.65;
        if (nextVisible == _isVisible) return;

        setState(() {
          _isVisible = nextVisible;
        });
        _updatePlayback();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          thumbFallback(),
          if (thumbUrl.isNotEmpty)
            Image.network(
              thumbUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          if (_hasError)
            Center(
              child: Icon(
                Icons.play_circle_fill_rounded,
                size: 48,
                color: Colors.white.withOpacity(0.9),
              ),
            )
          else if (!_isInitialized || c == null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 10,
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 10,
                      width: 92,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Center(
              child: AspectRatio(
                aspectRatio: c.value.aspectRatio,
                child: VideoPlayer(c),
              ),
            ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 12),
            ),
          ),
        ],
      ),
    );
  }
}
