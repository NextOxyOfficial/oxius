import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../config/app_config.dart';
import '../../utils/media_headers.dart';
import '../common/adsy_loading.dart';
import '../app_network_image.dart';
import 'package:oxius_native/l10n/tr.dart';

/// One item a chat can open full screen.
class ChatMediaItem {
  final String url;
  final bool isVideo;

  /// Who sent it and when — shown in the header so an opened photo still has
  /// its context. Both optional; the viewer works without them.
  final String? senderName;
  final String? timeLabel;

  /// The chat message this media came from. Carried so a reply typed in the
  /// viewer can quote the right thing; surfaces with no chat behind them
  /// (a gig submission, a bare video link) simply leave it null and get no
  /// composer.
  final Map<String, dynamic>? sourceMessage;

  const ChatMediaItem({
    required this.url,
    required this.isVideo,
    this.senderName,
    this.timeLabel,
    this.sourceMessage,
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

  /// Send a reply to [item] with [text]. Supplied by the chat screen, which
  /// owns the composing, the optimistic bubble and the reply encoding — the
  /// viewer only collects the words. Omit it and no composer is shown.
  final void Function(ChatMediaItem item, String text)? onSendReply;

  const ChatMediaViewer({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.onLongPress,
    this.onSendReply,
  });

  static Future<void> open(
    BuildContext context, {
    required List<ChatMediaItem> items,
    int initialIndex = 0,
    void Function(ChatMediaItem item)? onLongPress,
    void Function(ChatMediaItem item, String text)? onSendReply,
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
          onSendReply: onSendReply,
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

  /// True while the current photo is pinch-zoomed. The dismiss drag's
  /// vertical recognizer wins the gesture arena against InteractiveViewer's
  /// pan (its slop is half the size), so with the handlers attached a zoomed
  /// photo could never be panned — one-finger drags moved the whole viewer.
  /// While zoomed, the dismiss handlers are simply not registered.
  bool _zoomed = false;

  @override
  void dispose() {
    _pages.dispose();
    _reply.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  ChatMediaItem get _current => widget.items[_index];

  final TextEditingController _reply = TextEditingController();
  final FocusNode _replyFocus = FocusNode();
  bool _replySent = false;

  /// A reply needs both a chat willing to send it and a message to attach it
  /// to. The gig-submission and bare-video callers have neither.
  bool get _canReply =>
      widget.onSendReply != null && _current.sourceMessage != null;

  void _sendReply() {
    final text = _reply.text.trim();
    if (text.isEmpty || !_canReply) return;
    widget.onSendReply!(_current, text);
    _reply.clear();
    _replyFocus.unfocus();
    // The reply lands in the thread behind this screen, so say it went —
    // otherwise the only feedback is the box emptying itself.
    setState(() => _replySent = true);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _replySent = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Drag-to-dismiss: the sheet fades as it moves, so the gesture explains
    // itself before it completes.
    final fade = (1 - (_dragOffset.abs() / 320)).clamp(0.35, 1.0);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black.withValues(alpha: fade),
      body: Stack(
        children: [
          GestureDetector(
            onVerticalDragUpdate: _zoomed
                ? null
                : (d) => setState(() => _dragOffset += d.delta.dy),
            onVerticalDragEnd: _zoomed
                ? null
                : (_) {
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
                onPageChanged: (i) => setState(() {
                  _index = i;
                  _zoomed = false;
                }),
                itemBuilder: (_, i) {
                  final item = widget.items[i];
                  return item.isVideo
                      ? _VideoStage(url: item.url, active: i == _index)
                      : _PhotoStage(
                          url: item.url,
                          onZoomChanged: (z) {
                            if (z != _zoomed) setState(() => _zoomed = z);
                          },
                        );
                },
              ),
            ),
          ),
          _header(),
          if (_canReply) _composer(),
          if (_replySent) _sentToast(),
        ],
      ),
    );
  }

  /// The reply box, pinned to the bottom and lifted by the keyboard.
  ///
  /// Scaffold's own resize is off here — the photo must keep the whole screen
  /// rather than being squeezed into what the keyboard leaves — so the inset
  /// is applied to this bar alone.
  Widget _composer() {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            10,
            8,
            10,
            8 + (inset > 0 ? 0 : MediaQuery.of(context).padding.bottom),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.72),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.22)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: _reply,
                    focusNode: _replyFocus,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendReply(),
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                      border: InputBorder.none,
                      hintText: _current.isVideo
                          ? tr('ভিডিওটিতে রিপ্লাই দিন…')
                          : tr('ছবিটিতে রিপ্লাই দিন…'),
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Enabled only with something to send, so the button never
              // promises an action it will ignore.
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _reply,
                builder: (context, value, _) {
                  final ready = value.text.trim().isNotEmpty;
                  return GestureDetector(
                    onTap: ready ? _sendReply : null,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ready
                            ? const Color(0xFF2563EB)
                            : Colors.white.withValues(alpha: 0.16),
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        size: 20,
                        color: ready
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sentToast() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 96 + MediaQuery.of(context).viewInsets.bottom,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tr('রিপ্লাই পাঠানো হয়েছে'),
              style: TextStyle(color: Colors.white, fontSize: 12.5),
            ),
          ),
        ),
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

class _PhotoStage extends StatefulWidget {
  final String url;
  final ValueChanged<bool>? onZoomChanged;
  const _PhotoStage({required this.url, this.onZoomChanged});

  @override
  State<_PhotoStage> createState() => _PhotoStageState();
}

class _PhotoStageState extends State<_PhotoStage> {
  final TransformationController _transform = TransformationController();

  @override
  void initState() {
    super.initState();
    _transform.addListener(() {
      widget.onZoomChanged?.call(_transform.value.getMaxScaleOnAxis() > 1.02);
    });
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    final isRemote = url.startsWith('http');
    return Center(
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 1,
        maxScale: 4,
        child: isRemote
            ? AppNetworkImage(
                AppConfig.getAbsoluteUrl(url),
                fit: BoxFit.contain,
                httpHeaders: kMediaHeaders,
                fadeIn: false,
                placeholder: const Center(
                  child: AdsyLoadingIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    strokeWidth: 2.5,
                  ),
                ),
                errorWidget: const _Broken(),
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

  /// Whether this page is the one on screen. A page being swiped away is
  /// still mounted, and with autoplay that meant two soundtracks at once.
  final bool active;

  const _VideoStage({required this.url, this.active = true});

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
      if (widget.active) await controller.play();
      setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(covariant _VideoStage old) {
    super.didUpdateWidget(old);
    final c = _controller;
    if (c == null || !_ready) return;
    if (!widget.active && c.value.isPlaying) {
      c.pause();
    } else if (widget.active && old.active != widget.active) {
      c.play();
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
            aspectRatio:
                c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(c),
                // Tap anywhere on the frame to pause/resume — the control most
                // used, so it gets the biggest target.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      setState(() => c.value.isPlaying ? c.pause() : c.play()),
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
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: Colors.white54, size: 44),
            SizedBox(height: 10),
            Text(tr('মিডিয়াটি লোড করা যায়নি'),
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      );
}
