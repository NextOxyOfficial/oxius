import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../services/business_network_service.dart';
import '../services/fcm_service.dart';
import '../screens/business_network/post_detail_screen.dart';

class DeepLinkService {
  DeepLinkService._();

  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _initialized = false;
  Uri? _pendingUri;
  int _pendingRetryCount = 0;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        scheduleMicrotask(() => _handleUri(initial));
      }
    } catch (_) {}

    _sub = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleUri(uri);
      },
      onError: (_) {},
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _initialized = false;
  }

  Future<void> _handleUri(Uri uri) async {
    final host = uri.host.toLowerCase();
    final isWebLink = uri.scheme == 'https' && (host == 'adsyclub.com' || host == 'www.adsyclub.com');
    final isCustomScheme = uri.scheme == 'adsyclub';

    if (!isWebLink && !isCustomScheme) return;

    final List<String> segments;
    if (isCustomScheme) {
      final fromHost = uri.host.trim();
      final fromPath = uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
      if (fromHost.isNotEmpty) {
        segments = [fromHost, ...fromPath];
      } else {
        segments = fromPath;
      }
    } else {
      segments = uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
    }
    if (segments.isEmpty) return;

    final navigator = FCMService.navigatorKey.currentState;
    final context = FCMService.navigatorKey.currentContext;
    if (navigator == null) {
      _pendingUri = uri;
      _pendingRetryCount = 0;
      _retryPending();
      return;
    }

    if (segments[0] == 'business-network') {
      if (segments.length == 1) {
        navigator.pushNamed('/business-network');
        return;
      }

      if (segments.length >= 3 && segments[1] == 'posts') {
        final postId = int.tryParse(segments[2]);
        if (postId != null && context != null) {
          await _openBusinessNetworkPost(context, postId);
        }
        return;
      }

      if (segments.length >= 3 && segments[1] == 'profile') {
        navigator.pushNamed(
          '/business-network/profile',
          arguments: {'userId': segments[2]},
        );
        return;
      }

      navigator.pushNamed('/business-network');
      return;
    }

    if (segments[0] == 'classified-details' && segments.length >= 2) {
      final slug = segments[1];
      navigator.pushNamed(
        '/classified-post-details',
        arguments: {
          'postId': slug,
          'postSlug': slug,
        },
      );
      return;
    }

    if (segments[0] == 'sale' && segments.length >= 2) {
      final slug = segments[1];
      navigator.pushNamed(
        '/sale/detail',
        arguments: {'slug': slug},
      );
      return;
    }

    if (segments[0] == 'food-zone') {
      navigator.pushNamed('/food-zone');
      return;
    }
  }

  void _retryPending() {
    if (_pendingUri == null) return;
    if (_pendingRetryCount >= 10) {
      _pendingUri = null;
      _pendingRetryCount = 0;
      return;
    }

    _pendingRetryCount += 1;
    Future.delayed(const Duration(milliseconds: 300), () {
      final uri = _pendingUri;
      if (uri == null) return;

      final navigator = FCMService.navigatorKey.currentState;
      if (navigator == null) {
        _retryPending();
        return;
      }

      _pendingUri = null;
      _pendingRetryCount = 0;
      _handleUri(uri);
    });
  }

  Future<void> _openBusinessNetworkPost(BuildContext context, int postId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final post = await BusinessNetworkService.getPost(postId);
      if (!context.mounted) return;
      Navigator.pop(context);

      if (post == null) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailScreen(post: post),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      Navigator.pop(context);
    }
  }
}
