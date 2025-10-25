import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Global image utility to handle CORS and network issues
/// Use this instead of Image.network throughout the app
class AppImage {
  /// Load network image with CORS handling
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
  }) {
    if (url == null || url.isEmpty) {
      return _buildErrorWidget(width, height, errorWidget);
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
      alignment: alignment,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(width, height),
      errorWidget: (context, url, error) {
        // Silently handle CORS errors without console spam
        if (error.toString().contains('CORS') || 
            error.toString().contains('XMLHttpRequest') ||
            error.toString().contains('ERR_FAILED')) {
          // Don't print CORS errors to reduce console noise
        } else {
          print('Image load error: $error');
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
        placeholder: placeholder,
        errorWidget: errorWidget,
      ),
    );
  }

  /// Load image as background
  static DecorationImage? backgroundImage(String? url) {
    if (url == null || url.isEmpty) return null;
    
    return DecorationImage(
      image: CachedNetworkImageProvider(url),
      fit: BoxFit.cover,
      onError: (error, stackTrace) {
        // Silently handle CORS errors
        if (!error.toString().contains('CORS') && 
            !error.toString().contains('XMLHttpRequest')) {
          print('Background image error: $error');
        }
      },
    );
  }

  static Widget _buildPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  static Widget _buildErrorWidget(double? width, double? height, Widget? custom) {
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
