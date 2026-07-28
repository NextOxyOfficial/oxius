import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../config/app_config.dart';
import '../../utils/media_headers.dart';
import '../common/adsy_loading.dart';

/// One item a chat can open full screen.
class ChatMediaItem {
  final String url;
  final bool isVideo;

  /// Who sent it and when — shown in the header so an opened photo still has
  /// its context. Both optional; the viewer works without them.
  final String? senderName;
  final String? timeLabel;

  const ChatMediaItem({
    required this.url,
    required this.isVideo,
    this.senderName,
    this.timeLabel,
  });
}

/// Full-screen viewer for photos and videos sent in a chat.
///
/// One screen for both kinds, because a chat has both and the difference
/// should not change how it feels to open one. Photos pinch-zoom, videos play
/// with a real scrubber, and either can be dragged down to dismiss.
///
/// Presented as an ordinary route on the navigator that owns the caller — the
/// old code pushed the video player on the ROOT navigator while the chat was
/// living in an overlay above it, so the player opened underneath and only
/// appeared once you pressed back.
class ChatMediaViewer extends StatefulWidget {
  final List<ChatMediaItem> items;
  final int initialIndex;

  /// Long-press on the media (save / share, supplied by the chat screen).
  final void Function(ChatMediaItem item)? onLongPress;

  const ChatMediaViewer({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.onLongPress,
  });

  static Future<void> open(
    BuildContext context, {
    required List<ChatMediaItem> items,
    int initialIndex = 0,
    void Function(ChatMediaItem item)? onLongPress,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) => ChatMediaViewer(
          items: items,
          initialIndex: initialIndex,
          onLongPress: onLongPress,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<ChatMediaViewer> createState() => _ChatMediaViewerState();
}

class _ChatMediaViewerState extends State<ChatMediaViewer> {
  late final PageController _pages =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  double _dragOffset = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  ChatMediaItem get _current => widget.items[_index];

  @override
  Widget build(BuildContext context) {
    // Drag-to-dismiss: the sheet fades as it moves, so the gesture explains
    // itself before it completes.
    final fade = (1 - (_dragOffset.abs() / 320)).clamp(0.35, 1.0);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: fade),
      body: Stack(
        children: [
          GestureDetector(
            onVerticalDragUpdate: (d) =>
                setState(() => _dragOffset += d.delta.dy),
            onVerticalDragEnd: (_) {
              if (_dragOffset.abs() > 120) {
                Navigator.of(context).maybePop();
              } else {
                setState(() => _dragOffset = 0);
              }
            },
            onLongPress: widget.onLongPress == null
                ? null
                : () => widget.onLongPress!(_current),
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: PageView.builder(
                controller: _pages,
                itemCount: widget.items.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final item = widget.items[i];
                  return item.isVideo
                      ? _VideoStage(url: item.url)
                      : _PhotoStage(url: item.url);
                },
              ),
            ),
          ),
          _header(),
        ],
      ),
    );
  }

  Widget _header() {
    final name = _current.senderName?.trim() ?? '';
    final time = _current.timeLabel?.trim() ?? '';
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            4, MediaQuery.of(context).padding.top + 4, 8, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.55),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (name.isNotEmpty)
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (time.isNotEmpty)
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11.5,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.items.length > 1)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  '${_index + 1}/${widget.items.length}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoStage extends StatelessWidget {
  final String url;
  const _PhotoStage({required this.url});

  @override
  Widget build(BuildContext context) {
    final isRemote = url.startsWith('http');
    return Center(
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: isRemote
            ? Image.network(
                AppConfig.getAbsoluteUrl(url),
                fit: BoxFit.contain,
                headers: kMediaHeaders,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: AdsyLoadingIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white70),
                          strokeWidth: 2.5,
                        ),
                      ),
                errorBuilder: (_, __, ___) => const _Broken(),
              )
            : Image.file(File(url),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const _Broken()),
      ),
    );
  }
}

class _VideoStage extends StatefulWidget {
  final String url;
  const _VideoStage({required this.url});

  @override
  State<_VideoStage> createState() => _VideoStageState();
}

class _VideoStageState extends State<_VideoStage> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final url = widget.url;
      final controller = url.startsWith('http')
          ? VideoPlayerController.networkUrl(
              Uri.parse(AppConfig.getAbsoluteUrl(url)),
              httpHeaders: kMediaHeaders,
            )
          : VideoPlayerController.file(File(url));
      _controller = controller;
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      await controller.play();
      setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const _Broken();
    final c = _controller;
    if (!_ready || c == null) {
      return const Center(
        child: AdsyLoadingIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          strokeWidth: 2.5,
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AspectRatio(
            aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(c),
                // Tap anywhere on the frame to pause/resume — the control most
                // used, so it gets the biggest target.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(
                      () => c.value.isPlaying ? c.pause() : c.play()),
                  child: ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: c,
                    builder: (_, value, __) => AnimatedOpacity(
                      opacity: value.isPlaying ? 0 : 1,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 38),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: VideoProgressIndicator(
              c,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.white,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Broken extends StatelessWidget {
  const _Broken();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.white54, size: 44),
            SizedBox(height: 10),
            Text('মিডিয়াটি লোড করা যায়নি',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      );
}
