import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// The one way this app loads a picture from the network.
///
/// `Image.network` keeps bytes in memory only, so every cold start — and every
/// eviction under memory pressure — re-downloads the same avatars and
/// thumbnails the user has already seen. On a feed that is most of the data
/// the app moves, and most of the reason scrolling stutters. This caches to
/// disk, so an image is fetched once per device rather than once per session.
///
/// It also decodes at display size. A 2000px product photo painted into a 64px
/// avatar costs the same RAM and CPU as a full-screen one; [memCacheWidth]
/// (derived from the requested width and the device's pixel ratio) makes it
/// cost what it looks like.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeIn = true,
    this.httpHeaders,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Shown while the bytes are on their way. Defaults to a flat tint rather
  /// than a spinner: a spinner on every tile in a feed is visual noise, and a
  /// cached image appears too fast for one to be anything but a flash.
  final Widget? placeholder;

  /// Shown when the URL is empty, broken, or the fetch fails.
  final Widget? errorWidget;

  /// A cached image is already there when the widget builds, so fading it in
  /// would add a delay the user can see. Off for hero-sized art that should
  /// simply appear.
  final bool fadeIn;

  /// Headers the fetch must carry. Chat and post media live behind a CDN that
  /// refuses Dart's default User-Agent, so those call sites pass
  /// `kMediaHeaders` — without it the picture simply never arrives.
  final Map<String, String>? httpHeaders;

  Widget _fallback(BuildContext context) =>
      errorWidget ??
      Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.image_not_supported_outlined,
          size: (width != null && width! < 48) ? 16 : 24,
          color: Theme.of(context).colorScheme.outline,
        ),
      );

  Widget _placeholder(BuildContext context) =>
      placeholder ??
      Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      );

  @override
  Widget build(BuildContext context) {
    final src = url?.trim() ?? '';
    if (src.isEmpty) return _wrap(_fallback(context));

    // Ask the decoder for the size this will actually be painted at. Without
    // a width to go on, leave it alone rather than guess — a wrong cap shows
    // as a blurry image, which is worse than a heavy one.
    final ratio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final cacheWidth =
        width != null && width!.isFinite ? (width! * ratio).round() : null;

    return _wrap(
      CachedNetworkImage(
        imageUrl: src,
        httpHeaders: httpHeaders,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: cacheWidth,
        fadeInDuration:
            fadeIn ? const Duration(milliseconds: 180) : Duration.zero,
        placeholder: (context, _) => _placeholder(context),
        errorWidget: (context, _, __) => _fallback(context),
      ),
    );
  }

  Widget _wrap(Widget child) => borderRadius == null
      ? child
      : ClipRRect(borderRadius: borderRadius!, child: child);
}
