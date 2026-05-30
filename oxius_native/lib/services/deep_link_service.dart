import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../services/business_network_service.dart';
import '../services/eshop_service.dart';
import '../services/fcm_service.dart';
import '../screens/business_network/post_detail_screen.dart';
import '../screens/gig_details_screen.dart';
import '../screens/microgig/pending_tasks_screen.dart';
import '../screens/news_detail_screen.dart';
import '../screens/product_details_screen.dart';
import '../screens/vendor_store_screen.dart';
import '../screens/workspace/gig_detail_screen.dart' as workspace;
import '../screens/workspace/order_detail_screen.dart' as workspace;
import '../screens/workspace/workspace_screen.dart' as workspace;
import 'package:oxius_native/widgets/common/adsy_loading.dart';

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
    final isWebLink = uri.scheme == 'https' &&
        (host == 'adsyclub.com' || host == 'www.adsyclub.com');
    final isCustomScheme = uri.scheme == 'adsyclub';

    if (!isWebLink && !isCustomScheme) return;

    final List<String> segments;
    if (isCustomScheme) {
      final embeddedUrl = uri.queryParameters['url'];
      if ((uri.host == 'open' || uri.host == 'link') &&
          embeddedUrl != null &&
          embeddedUrl.isNotEmpty) {
        final embeddedUri = Uri.tryParse(embeddedUrl);
        if (embeddedUri != null) {
          await _handleUri(embeddedUri);
        }
        return;
      }

      final fromHost = uri.host.trim();
      final fromPath =
          uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
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

    final first = segments[0].toLowerCase();

    if (first == 'home') {
      navigator.pushNamed('/');
      return;
    }

    if (first == 'business-network') {
      if (segments.length == 1) {
        navigator.pushNamed('/business-network');
        return;
      }

      if (segments.length >= 3 && segments[1] == 'posts') {
        final postIdentifier = segments[2];
        if (postIdentifier.isNotEmpty && context != null) {
          await _openBusinessNetworkPost(context, postIdentifier);
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

      if (segments.length >= 2 &&
          (segments[1] == 'workspaces' || segments[1] == 'workspace-details')) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => const workspace.WorkspaceScreen(),
          ),
        );
        return;
      }

      if (segments.length >= 3 && segments[1] == 'workspace') {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => workspace.GigDetailScreen(gigId: segments[2]),
          ),
        );
        return;
      }

      navigator.pushNamed('/business-network');
      return;
    }

    if (first == 'verify-payment' ||
        first == 'deposit-withdraw' ||
        first == 'payment-callback.html' ||
        first == 'payment-cancel.html') {
      final paymentRoute = _buildWalletRouteFromUri(uri, segments);
      navigator.pushNamed(paymentRoute);
      return;
    }

    if ((first == 'classified-details' ||
            (first == 'classified-categories' &&
                segments.length >= 3 &&
                segments[1] == 'details')) &&
        segments.length >= 2) {
      final slug = first == 'classified-details' ? segments[1] : segments[2];
      navigator.pushNamed(
        '/classified-post-details',
        arguments: {
          'postId': slug,
          'postSlug': slug,
        },
      );
      return;
    }

    if (first == 'classified-categories' && segments.length >= 2) {
      if (segments[1] == 'post') {
        navigator.pushNamed('/classified-post-form');
        return;
      }

      final slug = segments[1];
      navigator.pushNamed(
        '/classified-category',
        arguments: {
          'categoryId': slug,
          'categorySlug': slug,
        },
      );
      return;
    }

    if (first == 'product-details' && segments.length >= 2) {
      if (context != null) {
        await _openProductDetails(context, segments[1]);
      } else {
        navigator.pushNamed('/eshop');
      }
      return;
    }

    if (first == 'eshop') {
      if (segments.length >= 3 && segments[1] == 'category') {
        navigator.pushNamed(
          '/eshop',
          arguments: {'categoryId': segments[2], 'categorySlug': segments[2]},
        );
        return;
      }

      if (segments.length >= 2) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => VendorStoreScreen(storeUsername: segments[1]),
          ),
        );
        return;
      }

      navigator.pushNamed('/eshop');
      return;
    }

    if (first == 'adsy-news' || first == 'news') {
      if (segments.length >= 3 && segments[1] == 'categories') {
        navigator.pushNamed('/adsy-news');
        return;
      }

      if (segments.length >= 2) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => NewsDetailScreen(slug: segments[1]),
          ),
        );
        return;
      }

      navigator.pushNamed('/adsy-news');
      return;
    }

    if (first == 'order' && segments.length >= 2) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => GigDetailsScreen(gigSlug: segments[1]),
        ),
      );
      return;
    }

    if (first == 'my-gigs') {
      if (segments.length >= 3 && segments[1] == 'details') {
        navigator.pushNamed('/my-gigs');
        return;
      }

      navigator.pushNamed('/my-gigs');
      return;
    }

    if (first == 'business-network-workspace' ||
        first == 'workspace' ||
        first == 'workspaces') {
      if (segments.length >= 2) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => workspace.GigDetailScreen(gigId: segments[1]),
          ),
        );
        return;
      }

      navigator.push(
        MaterialPageRoute(
          builder: (_) => const workspace.WorkspaceScreen(),
        ),
      );
      return;
    }

    if (first == 'workspace-orders' && segments.length >= 2) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => workspace.OrderDetailScreen(orderId: segments[1]),
        ),
      );
      return;
    }

    if (first == 'seller' && segments.length >= 2) {
      navigator.pushNamed(
        '/seller-profile',
        arguments: {'userId': segments[1]},
      );
      return;
    }

    if (first == 'sale' && segments.length >= 2) {
      if (segments[1] == 'user-profile' && segments.length >= 3) {
        navigator.pushNamed(
          '/seller-profile',
          arguments: {'userId': segments[2]},
        );
        return;
      }

      if (segments[1] == 'my-posts') {
        navigator.pushNamed(
          '/my-sale-posts',
          arguments: {'tab': uri.queryParameters['tab']},
        );
        return;
      }

      final slug = segments[1];
      navigator.pushNamed(
        '/sale/detail',
        arguments: {'slug': slug},
      );
      return;
    }

    if (first == 'food-zone') {
      navigator.pushNamed('/food-zone');
      return;
    }

    if (first == 'mobile-recharge' ||
        first == 'upgrade-to-pro' ||
        first == 'shop-manager' ||
        first == 'post-a-gig' ||
        first == 'micro-gigs' ||
        first == 'about' ||
        first == 'faq' ||
        first == 'contact-us' ||
        first == 'refer-a-friend' ||
        first == 'terms-and-conditions' ||
        first == 'privacy-policy' ||
        first == 'rideshare') {
      navigator.pushNamed('/$first');
      return;
    }

    if (first == 'pending-tasks') {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => const PendingTasksScreen(),
        ),
      );
      return;
    }
  }

  String _buildWalletRouteFromUri(Uri uri, List<String> segments) {
    final hasPaymentCallbackData =
        uri.queryParameters.containsKey('sp_order_id') ||
            uri.queryParameters.containsKey('order_id') ||
            uri.queryParameters.containsKey('merchant_invoice_no') ||
            uri.queryParameters.containsKey('payment_state');

    if (!hasPaymentCallbackData && segments[0] == 'deposit-withdraw') {
      return '/deposit-withdraw';
    }

    final callbackUrl = _buildWebCallbackUrl(uri, segments);
    return Uri(
      path: '/deposit-withdraw',
      queryParameters: {
        'payment_callback_url': callbackUrl,
      },
    ).toString();
  }

  String _buildWebCallbackUrl(Uri uri, List<String> segments) {
    if (uri.scheme == 'https') {
      return uri.toString();
    }

    return Uri.https(
      'adsyclub.com',
      '/${segments.join('/')}',
      uri.queryParameters.isEmpty ? null : uri.queryParameters,
    ).toString();
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

  Future<void> _openBusinessNetworkPost(
      BuildContext context, String postIdentifier) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: AdsyLoadingIndicator(),
      ),
    );

    try {
      final post =
          await BusinessNetworkService.getPostByIdentifier(postIdentifier);
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

  Future<void> _openProductDetails(BuildContext context, String slug) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: AdsyLoadingIndicator(),
      ),
    );

    try {
      final product = await EshopService.fetchProductDetails(slug: slug);
      if (!context.mounted) return;
      Navigator.pop(context);

      if (product == null) {
        Navigator.pushNamed(context, '/eshop');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailsScreen(product: product),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      Navigator.pop(context);
      Navigator.pushNamed(context, '/eshop');
    }
  }
}
