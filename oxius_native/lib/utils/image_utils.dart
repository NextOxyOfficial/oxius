import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

/// Global image utility to handle CORS and network issues
/// Use this instead of Image.network throughout the app
class AppImage {
  /// Get CORS-safe URL for web platform
  static String _getCorsProxyUrl(String url) {
    // Only use proxy for web platform and external domains
    if (kIsWeb && (url.contains('adsyclub.com') || url.contains('http'))) {
      // Option 1: Use corsproxy.io (free service)
      // return 'https://corsproxy.io/?${Uri.encodeComponent(url)}';

      // Option 2: Use allorigins.win (free service)
      // return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}';

      // Option 3: For now, return original URL and let backend handle CORS
      // Backend should add proper CORS headers
      return url;
    }
    return url;
  }

  /// Load network image with CORS handling, disk+memory caching and automatic
  /// down-scaling.
  ///
  /// [cacheWidth] caps the decoded/disk-cached pixel width. When omitted it is
  /// derived from the display [width] (~3x for retina, clamped) so avatars and
  /// thumbnails are decoded small — far less RAM, no jank, faster scroll. Full
  /// width (no [width]) caches up to 1080px. Pass [fullResolution]: true to opt
  /// out (e.g. a zoomable full-screen viewer).
  static Widget network(
    String? url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    BorderRadius? borderRadius,
    Color? color,
    BlendMode? colorBlendMode,
    Alignment alignment = Alignment.center,
    int? cacheWidth,
    bool fullResolution = false,
  }) {
    if (url == null || url.isEmpty) {
      return _buildErrorWidget(width, height, errorWidget);
    }

    // Use CORS-safe URL for web
    final safeUrl = _getCorsProxyUrl(url);

    final int? memWidth = _resolveCacheWidth(
      explicit: cacheWidth,
      displayWidth: width,
      fullResolution: fullResolution,
    );

    Widget imageWidget = CachedNetworkImage(
      imageUrl: safeUrl,
      width: width,
      height: height,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
      alignment: alignment,
      // Decode at a capped size — the single biggest win for list scrolling.
      memCacheWidth: memWidth,
      maxWidthDiskCache: memWidth,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (context, url) =>
          placeholder ?? _buildPlaceholder(width, height),
      errorWidget: (context, url, error) {
        // Silently handle CORS errors without console spam
        if (error.toString().contains('CORS') ||
            error.toString().contains('XMLHttpRequest') ||
            error.toString().contains('ERR_FAILED')) {
          // Don't print CORS errors to reduce console noise
          // Return a fallback widget instead
        } else {
          debugPrint('Image load error: $error');
        }
        return errorWidget ?? _buildErrorWidget(width, height, null);
      },
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Load circular avatar image
  static Widget avatar(
    String? url, {
    required double radius,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return ClipOval(
      child: network(
        url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        // Avatars are tiny — decode them tiny too.
        cacheWidth: (radius * 2 * 3).round().clamp(48, 256),
        placeholder: placeholder,
        errorWidget: errorWidget,
      ),
    );
  }

  /// Resolve the effective decode/disk cache width.
  static int? _resolveCacheWidth({
    int? explicit,
    double? displayWidth,
    bool fullResolution = false,
  }) {
    if (fullResolution) return null;
    if (explicit != null && explicit > 0) return explicit;
    if (displayWidth != null && displayWidth.isFinite && displayWidth > 0) {
      return (displayWidth * 3).round().clamp(64, 1080);
    }
    // Unknown display size (e.g. full-bleed) — cap at a sane mobile width.
    return 1080;
  }

  /// Load image as background
  static DecorationImage? backgroundImage(String? url, {int maxWidth = 1080}) {
    if (url == null || url.isEmpty) return null;

    // Use CORS-safe URL for web
    final safeUrl = _getCorsProxyUrl(url);

    return DecorationImage(
      image: ResizeImage(
        CachedNetworkImageProvider(safeUrl),
        width: maxWidth,
        policy: ResizeImagePolicy.fit,
      ),
      fit: BoxFit.cover,
      onError: (error, stackTrace) {
        // Silently handle CORS errors
        if (!error.toString().contains('CORS') &&
            !error.toString().contains('XMLHttpRequest') &&
            !error.toString().contains('ERR_FAILED')) {
          debugPrint('Background image error: $error');
        }
      },
    );
  }

  static Widget _buildPlaceholder(double? width, double? height) {
    // Shimmer skeleton reads as "loading" far more smoothly than a spinner and
    // avoids layout shift since it fills the reserved box.
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
      ),
    );
  }

  static Widget _buildErrorWidget(
      double? width, double? height, Widget? custom) {
    if (custom != null) return custom;

    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: (width != null && height != null)
            ? (width < height ? width * 0.4 : height * 0.4)
            : 40,
        color: Colors.grey.shade400,
      ),
    );
  }
}

/// Extension method to make it easy to use
extension ImageExtension on Image {
  /// Quick method to convert Image.network to AppImage.network
  static Widget safeNetwork(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return AppImage.network(url, width: width, height: height, fit: fit);
  }
}
