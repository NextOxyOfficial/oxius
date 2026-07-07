import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  /// Transient full-screen surfaces (e.g. the AdsyConnect chat overlay, which
  /// lives in a root OverlayEntry ABOVE the root navigator) register a
  /// dismisser here. Internal deep links push onto the ROOT navigator, so
  /// without this the destination would render UNDER such an overlay and only
  /// become visible after the user manually closes it. We dismiss the overlay
  /// first so a tapped link navigates immediately, on top.
  static VoidCallback? dismissTransientOverlay;

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _initialized = false;
  Uri? _pendingUri;
  int _pendingRetryCount = 0;
  static const Set<String> _adsyHosts = {
    'adsyclub.com',
    'www.adsyclub.com',
  };

  static const Map<String, String> _singleSegmentRouteAliases = {
    '': '/',
    'home': '/',
    'eshop': '/eshop',
    'e-shop': '/eshop',
    'shop': '/eshop',
    'business-network': '/business-network',
    'business_network': '/business-network',
    'network': '/business-network',
    'bn': '/business-network',
    'adsy-news': '/adsy-news',
    'news': '/adsy-news',
    'rideshare': '/rideshare',
    'ride-share': '/rideshare',
    'ride_share': '/rideshare',
    'sale': '/sale',
    'sale-marketplace': '/sale',
    'marketplace': '/sale',
    'buy-sell': '/sale',
    'classified': '/classified',
    'classified-services': '/classified',
    'classified-categories': '/classified',
    'classified-category': '/classified',
    'amar-sheba': '/classified',
    'my-services': '/classified',
    'services': '/classified',
    'micro-gigs': '/micro-gigs',
    'microgigs': '/micro-gigs',
    'earn-money': '/micro-gigs',
    'mobile-recharge': '/mobile-recharge',
    'recharge': '/mobile-recharge',
    'adsy-pay': '/deposit-withdraw',
    'wallet': '/deposit-withdraw',
    'deposit-withdraw': '/deposit-withdraw',
    'mindforce': '/mindforce',
    'elearning': '/elearning',
    'e-learning': '/elearning',
    'courses': '/elearning',
    'food-zone': '/food-zone',
    'membership': '/upgrade-to-pro',
    'packages': '/upgrade-to-pro',
    'upgrade-to-pro': '/upgrade-to-pro',
    // Account / profile / KYC — target for the "complete profile" & "verify KYC"
    // nudges (web /my-account → the app's Settings/account screen).
    'my-account': '/settings',
    'account': '/settings',
    'settings': '/settings',
  };

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

  Future<void> openInternalLink(String link) async {
    var trimmed = link.trim();
    if (trimmed.isEmpty) return;

    // Close any chat/overlay sitting above the root navigator so the
    // destination we're about to push becomes visible immediately.
    final dismiss = dismissTransientOverlay;
    if (dismiss != null) {
      dismiss();
      // Let the overlay teardown settle before the root push.
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }

    trimmed = _withSchemeForAdsyHost(trimmed);
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) {
      await _handleUri(parsed);
      return;
    }

    final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    final internalUri = Uri.parse('https://adsyclub.com$path');
    await _handleUri(internalUri);
  }

  String _withSchemeForAdsyHost(String target) {
    final lower = target.toLowerCase();
    if (lower.startsWith('//adsyclub.com') ||
        lower.startsWith('//www.adsyclub.com')) {
      return 'https:$target';
    }
    for (final host in _adsyHosts) {
      if (lower == host ||
          lower.startsWith('$host/') ||
          lower.startsWith('$host?') ||
          lower.startsWith('$host#')) {
        return 'https://$target';
      }
    }
    return target;
  }

  Future<void> _handleUri(Uri uri) async {
    final host = uri.host.toLowerCase();
    final isWebLink = (uri.scheme == 'https' || uri.scheme == 'http') &&
        _adsyHosts.contains(host);
    final isCustomScheme = uri.scheme == 'adsyclub';

    if (!isWebLink && !isCustomScheme) return;

    final List<String> segments;
    if (isCustomScheme) {
      final embeddedUrl = uri.queryParameters['url'];
      if ((uri.host == 'open' || uri.host == 'link') &&
          embeddedUrl != null &&
          embeddedUrl.isNotEmpty) {
        await openInternalLink(embeddedUrl);
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

    final navigator = FCMService.navigatorKey.currentState;
    final context = FCMService.navigatorKey.currentContext;
    if (navigator == null) {
      _pendingUri = uri;
      _pendingRetryCount = 0;
      _retryPending();
      return;
    }

    if (segments.isEmpty) {
      navigator.pushNamed('/');
      return;
    }

    final first = segments[0].toLowerCase();

    // Web-only pages that have NO in-app screen (e.g. the donation page, which
    // lives only on the website). The app's app-link filter is a catch-all for
    // adsyclub.com, so these links land here — bounce them to an in-app browser
    // tab (Custom Tab / SafariVC) so they always open in a browser instead of a
    // blank/unknown app screen. Re-launching via externalApplication would loop
    // (the app is the verified handler), so we use inAppBrowserView.
    const webOnlyFirstSegments = {'donate'};
    if (isWebLink && webOnlyFirstSegments.contains(first)) {
      try {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (_) {
        try {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }
      return;
    }

    if (segments.length == 1) {
      final route = _singleSegmentRouteAliases[first];
      if (route != null) {
        navigator.pushNamed(route);
        return;
      }
    }

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
        final gigId = uri.queryParameters['id'] ??
            uri.queryParameters['gig_id'] ??
            uri.queryParameters['gigId'];
        if (segments[1] == 'workspace-details' &&
            gigId != null &&
            gigId.isNotEmpty) {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => workspace.GigDetailScreen(gigId: gigId),
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

    if (first == 'details') {
      if (segments.length >= 3 && segments[1] == 'classified-categories') {
        final categorySlug = segments[2];
        navigator.pushNamed(
          '/classified-category',
          arguments: {
            'categoryId': categorySlug,
            'categorySlug': categorySlug,
          },
        );
        return;
      }

      if (segments.length >= 2) {
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

    if ((first == 'sale' ||
            first == 'sale-marketplace' ||
            first == 'marketplace' ||
            first == 'buy-sell') &&
        segments.length >= 2) {
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

    // Fallback: an internal link we have no dedicated native screen for. Before
    // this existed, such links (e.g. a notification "Visit" button pointing at a
    // path we don't map) silently did nothing. Now we open the real web page so
    // the action always goes somewhere; if that fails, land on home.
    if (isWebLink) {
      final opened = await _launchExternal(uri.toString());
      if (!opened) navigator.pushNamed('/');
    } else {
      navigator.pushNamed('/');
    }
  }

  Future<bool> _launchExternal(String url) async {
    final parsed = Uri.tryParse(url);
    if (parsed == null) return false;
    try {
      return await launchUrl(parsed, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
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
    // Up to 40 tries × 300ms ≈ 12s. A deep link tapped from a fully-closed app
    // fires before the root navigator exists; on a slow cold start the old 3s
    // window expired and the tap silently did nothing (e.g. the Mindforce promo
    // not opening). 12s comfortably covers first-launch initialisation, and we
    // still navigate the instant the navigator is ready — so fast starts are
    // unaffected.
    if (_pendingRetryCount >= 40) {
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
