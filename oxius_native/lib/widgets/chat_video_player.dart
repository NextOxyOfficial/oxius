import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

/// Video message in a chat bubble: a CLEAN first-frame thumbnail — no play /
/// seek chrome (they crowd the small bubble and look bad). Tapping opens a
/// full-screen player with proper controls.
///
/// The bubble keeps one paused, muted controller purely to paint the first
/// frame; playback happens on the full-screen route with its own controller.
class ChatVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isMe;
  final double width;
  final double height;

  const ChatVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.isMe,
    this.width = 240,
    this.height = 180,
  });

  @override
  State<ChatVideoPlayer> createState() => _ChatVideoPlayerState();
}

class _ChatVideoPlayerState extends State<ChatVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeThumb();
  }

  Future<void> _initializeThumb() async {
    try {
      final controller = widget.videoUrl.startsWith('http://') ||
              widget.videoUrl.startsWith('https://')
          ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
          : VideoPlayerController.file(File(widget.videoUrl));
      _controller = controller;
      await controller.initialize();
      await controller.setVolume(0);
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Error initializing video thumb: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _openFullScreen() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenChatVideo(videoUrl: widget.videoUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load video',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    final controller = _controller;
    if (!_isInitialized || controller == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: const Center(
          child: AdsyLoadingIndicator(
            color: Color(0xFF3B82F6),
          ),
        ),
      );
    }

    // Size the thumb to the video's real aspect ratio (portrait videos get a
    // tall frame instead of shrinking inside a letterboxed 16:9 box).
    final ar = controller.value.aspectRatio;
    const maxW = 240.0;
    const maxH = 320.0;
    double w = maxW;
    double h = w / (ar <= 0 ? 1 : ar);
    if (h > maxH) {
      h = maxH;
      w = h * ar;
    }

    return GestureDetector(
      onTap: _openFullScreen,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: w,
          height: h,
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen playback with normal controls — pushed when the bubble
/// thumbnail is tapped.
class _FullScreenChatVideo extends StatefulWidget {
  final String videoUrl;

  const _FullScreenChatVideo({required this.videoUrl});

  @override
  State<_FullScreenChatVideo> createState() => _FullScreenChatVideoState();
}

class _FullScreenChatVideoState extends State<_FullScreenChatVideo> {
  late final VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _videoController = widget.videoUrl.startsWith('http://') ||
              widget.videoUrl.startsWith('https://')
          ? VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
          : VideoPlayerController.file(File(widget.videoUrl));
      await _videoController.initialize();
      if (!mounted) return;
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: false,
          aspectRatio: _videoController.value.aspectRatio,
        );
      });
    } catch (e) {
      debugPrint('Error initializing full-screen video: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: _hasError
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: Colors.white54, size: 48),
                  SizedBox(height: 8),
                  Text('Failed to load video',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              )
            : _chewieController == null
                ? const AdsyLoadingIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : Chewie(controller: _chewieController!),
      ),
    );
  }
}
