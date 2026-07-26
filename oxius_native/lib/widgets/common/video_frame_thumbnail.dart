import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

/// A real frame from a video, used anywhere a video needs to look like a photo.
///
/// Before this, every place that could not show a server-side poster fell back
/// to a flat dark box with a play glyph — the composer did it for the file you
/// had just picked, and the feed did it for any video whose poster had not been
/// generated yet. Two of those side by side read as a broken post.
///
/// Two sources, one widget:
///   * [filePath] — a local pick. `video_compress` pulls the frame natively;
///     it is already a dependency, so this costs no new plugin.
///   * [videoUrl] — a remote clip with no poster. A player is initialised,
///     parked on an early frame and left paused; that frame IS the thumbnail.
///     Only used as a fallback, and a post carries at most two videos.
///
/// Extracted frames are memoised per source for the process, so scrolling a
/// feed past the same post does not redo the work.
class VideoFrameThumbnail extends StatefulWidget {
  /// Server-side poster. When present nothing is extracted — this is just a
  /// cached image, and the widget is as cheap as any other feed photo.
  final String? posterUrl;
  final String? filePath;
  final String? videoUrl;
  final BoxFit fit;

  /// Drawn over the frame once it resolves (play glyph, video badge…).
  final Widget? overlay;

  const VideoFrameThumbnail({
    super.key,
    this.posterUrl,
    this.filePath,
    this.videoUrl,
    this.fit = BoxFit.cover,
    this.overlay,
  });

  @override
  State<VideoFrameThumbnail> createState() => _VideoFrameThumbnailState();
}

class _VideoFrameThumbnailState extends State<VideoFrameThumbnail> {
  /// path/url -> extracted frame file. Survives widget rebuilds and list
  /// recycling; bounded by how many distinct videos a session scrolls past.
  static final Map<String, File> _fileCache = {};
  static final Set<String> _failed = {};

  /// Ceiling on remote-fallback players alive at once. Local extraction is a
  /// cheap native call, but the URL path holds a real decoder open, and a
  /// profile grid full of poster-less videos would otherwise open one per
  /// tile. Tiles past the ceiling keep the neutral surface — which only
  /// happens while the server is still generating posters.
  static const int _maxRemoteFallbacks = 3;
  static int _remoteFallbacks = 0;

  File? _frame;
  VideoPlayerController? _controller;
  bool _working = false;

  String? get _key => widget.filePath ?? widget.videoUrl;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant VideoFrameThumbnail old) {
    super.didUpdateWidget(old);
    if (old.posterUrl != widget.posterUrl ||
        old.filePath != widget.filePath ||
        old.videoUrl != widget.videoUrl) {
      if (_controller != null) {
        _remoteFallbacks--;
        _controller!.dispose();
        _controller = null;
      }
      _frame = null;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    // A server poster wins — nothing to extract.
    if ((widget.posterUrl ?? '').isNotEmpty) return;
    final key = _key;
    if (key == null || key.isEmpty || _working) return;

    final cached = _fileCache[key];
    if (cached != null) {
      setState(() => _frame = cached);
      return;
    }
    if (_failed.contains(key)) return;

    _working = true;
    try {
      if (widget.filePath != null) {
        final file = await VideoCompress.getFileThumbnail(
          widget.filePath!,
          quality: 70,
          // A hair into the clip: frame 0 is often black on phone recordings.
          position: 400,
        );
        if (await file.exists()) {
          _fileCache[key] = file;
          if (mounted) setState(() => _frame = file);
        } else {
          _failed.add(key);
        }
      } else if (widget.videoUrl != null) {
        if (_remoteFallbacks >= _maxRemoteFallbacks) return;
        _remoteFallbacks++;
        final c = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!));
        try {
          await c.initialize();
          await c.seekTo(const Duration(milliseconds: 400));
          await c.setVolume(0);
        } catch (_) {
          _remoteFallbacks--;
          await c.dispose();
          rethrow;
        }
        if (!mounted) {
          _remoteFallbacks--;
          await c.dispose();
          return;
        }
        setState(() => _controller = c);
      }
    } catch (_) {
      _failed.add(key);
    } finally {
      _working = false;
    }
  }

  @override
  void dispose() {
    if (_controller != null) {
      _remoteFallbacks--;
      _controller!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poster = widget.posterUrl ?? '';
    Widget base;
    if (poster.isNotEmpty) {
      base = CachedNetworkImage(
        imageUrl: poster,
        fit: widget.fit,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: 1080,
        fadeInDuration: const Duration(milliseconds: 120),
        placeholder: (_, __) => _resting(),
        errorWidget: (_, __, ___) => _resting(),
      );
    } else if (_frame != null) {
      base = Image.file(
        _frame!,
        fit: widget.fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _resting(),
      );
    } else if (_controller != null && _controller!.value.isInitialized) {
      base = FittedBox(
        fit: widget.fit,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      );
    } else {
      base = _resting();
    }

    if (widget.overlay == null) return base;
    return Stack(fit: StackFit.expand, children: [base, widget.overlay!]);
  }

  /// While the frame is being pulled. A soft neutral surface rather than the
  /// old near-black slab, so a not-yet-resolved tile never looks broken.
  Widget _resting() => Container(color: const Color(0xFFE9EEF3));
}
