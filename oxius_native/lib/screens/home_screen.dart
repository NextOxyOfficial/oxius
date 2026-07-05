import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/footer.dart';
import '../widgets/profile_completion_sheet.dart';
import '../widgets/mandatory_profile_sheet.dart';
import '../widgets/mobile_drawer.dart';
import '../widgets/hero_banner.dart';
import '../widgets/sale_category.dart';
import '../widgets/classified_services_section.dart';
import '../widgets/food_zone/food_zone_section.dart';
import '../widgets/eshop_section.dart';
import '../widgets/micro_gigs_section.dart';
import '../widgets/mobile_sticky_nav.dart';
import '../widgets/ads_scroll_widget.dart';
import '../widgets/business_network/gold_sponsors_slider.dart';
import '../services/scroll_direction_service.dart';
import '../services/user_state_service.dart';
import '../services/auth_service.dart';
import '../services/translation_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_text.dart';
import '../services/classified_post_service.dart';
import '../services/api_service.dart';
import '../services/home_popup_service.dart';
import '../services/offline_cache_service.dart';
import '../utils/network_error_handler.dart';
import '../models/classified_post.dart';
import 'wallet/wallet_screen.dart';
import 'settings_screen.dart';
import '../widgets/ios_web_redirect_screen.dart';
import 'inbox_screen.dart';
import 'news_screen.dart';
import 'verification_screen.dart';
import '../widgets/business_network/adsypay_qr_modal.dart';
import '../services/adsyconnect_service.dart';
import 'dart:async';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';
import '../widgets/home/home_popup_dialog.dart';

class HomeScreen extends StatefulWidget {
  final bool autoRefreshOnOpen;

  const HomeScreen({super.key, this.autoRefreshOnOpen = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ScrollController _scrollController;
  late ClassifiedPostService _postService;
  final ScrollDirectionService _scrollService = ScrollDirectionService();
  final TranslationService _translationService = TranslationService();
  final GlobalKey<AdsyRefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<AdsyRefreshIndicatorState>();
  final GlobalKey _classifiedSectionKey = GlobalKey();
  final GlobalKey _microGigsSectionKey = GlobalKey();
  bool _handledInitialScroll = false;
  bool _disposed = false;
  bool _isDropdownOpen = false; // Track dropdown menu state
  List<ClassifiedPost>? _recentPosts;
  bool _isLoadingPosts = false;
  int _unreadMessageCount = 0;
  int _homeRefreshEpoch = 0;

  Timer? _messageCountTimer;
  bool _isHomePopupOpen = false;

  // Header animation
  // ValueNotifier (not setState): toggling header visibility during scroll
  // must repaint ONLY the header overlay. A setState here rebuilt the entire
  // homepage Column mid-scroll, dropping frames ("shaking") on low-end devices.
  final ValueNotifier<bool> _isHeaderVisible = ValueNotifier<bool>(true);
  double _lastScrollPosition = 0;

  // Double-tap back to exit
  DateTime? _lastBackPressTime;

  static const Map<String, String> _translationKeyAliases = {
    'adsypay': 'adsy_pay',
  };

  // Helper method to translate keys
  String t(String key, {String? fallback}) {
    final normalizedKey = _translationKeyAliases[key] ?? key;
    return _translationService.translate(normalizedKey, fallback: fallback);
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _postService = ClassifiedPostService(baseUrl: ApiService.baseUrl);

    // Add scroll listener for header animation
    _scrollController.addListener(_onScroll);

    // Don't initialize the scroll service immediately - wait for the widget to be built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_disposed) {
        _scrollService.initialize(_scrollController);
        _handleInitialScrollIfNeeded();
        // Mandatory identity fields first (blocking), then the soft completion
        // nudge for everything else.
        () async {
          await MandatoryProfileSheet.maybeShow(context);
          if (mounted && !_disposed && context.mounted) {
            ProfileCompletionSheet.maybeShowPending(context);
          }
        }();
        if (widget.autoRefreshOnOpen) {
          _refreshIndicatorKey.currentState?.show();
        }
        _maybeShowHomePopup();
      }
    });
    _fetchRecentPosts();
    _startMessageCountPolling();
  }

  void _handleInitialScrollIfNeeded() {
    if (_handledInitialScroll) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final scrollTo = args['scrollTo']?.toString();
      if (scrollTo != null && scrollTo.isNotEmpty) {
        _handledInitialScroll = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _disposed) return;
          _scrollToSection(scrollTo);
        });
        return;
      }
    }
    _handledInitialScroll = true;
  }

  Future<void> _scrollToSection(String section) async {
    final key = switch (section) {
      'classified' => _classifiedSectionKey,
      'micro-gigs' => _microGigsSectionKey,
      _ => null,
    };

    if (key == null) return;
    if (!_scrollController.hasClients) return;

    final ctx = key.currentContext;
    if (ctx == null) return;

    final box = ctx.findRenderObject();
    if (box is! RenderBox) return;

    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + 56;

    final targetY = box.localToGlobal(Offset.zero).dy;
    final targetOffset =
        (_scrollController.offset + targetY - headerHeight).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    await _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  void _startMessageCountPolling() {
    // Only start polling if user is authenticated
    if (!AuthService.isAuthenticated) {
      return;
    }

    // Initial load
    _fetchUnreadMessageCount();

    // Poll every 10 seconds
    _messageCountTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !_disposed && AuthService.isAuthenticated) {
        _fetchUnreadMessageCount();
      } else if (!AuthService.isAuthenticated) {
        // Stop polling if user logs out
        timer.cancel();
      }
    });
  }

  Future<void> _fetchUnreadMessageCount() async {
    // Don't fetch if user is not authenticated
    if (!AuthService.isAuthenticated) {
      if (mounted && !_disposed) {
        setState(() {
          _unreadMessageCount = 0;
        });
        // Remove app badge when not authenticated
        _updateAppBadge(0);
      }
      return;
    }

    try {
      // AdsyConnect header icon shows the combined unread across all three
      // inbox tabs: chats + updates (admin notices) + support tickets.
      final results = await Future.wait([
        _fetchChatUnread(),
        _fetchUpdatesUnread(),
        _fetchSupportUnread(),
      ]);
      final totalUnread = results.fold<int>(0, (s, c) => s + c);

      if (mounted && !_disposed) {
        setState(() {
          _unreadMessageCount = totalUnread;
        });
        // Update app badge with unread count
        _updateAppBadge(totalUnread);
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  Future<int> _fetchChatUnread() async {
    try {
      final chatRooms = await AdsyConnectService.getChatRooms(page: 1);
      int total = 0;
      for (var room in chatRooms) {
        total += (room['unread_count'] as int?) ?? 0;
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Unread admin notices (the "Updates" tab).
  Future<int> _fetchUpdatesUnread() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse(ApiService.getApiUrl('admin-notice/?page=1')),
        headers: headers,
      );
      if (response.statusCode != 200) return 0;
      final data = json.decode(response.body);
      final List items = data is List ? data : (data['results'] ?? []);
      return items.where((n) => (n['is_read'] ?? false) != true).length;
    } catch (_) {
      return 0;
    }
  }

  /// Support tickets with unread replies (the "Support" tab).
  Future<int> _fetchSupportUnread() async {
    try {
      final headers = await ApiService.getHeaders();
      final response = await http.get(
        Uri.parse(ApiService.getApiUrl('tickets/?page=1')),
        headers: headers,
      );
      if (response.statusCode != 200) return 0;
      final data = json.decode(response.body);
      final List items = data is List ? data : (data['results'] ?? []);
      return items.where((t) => (t['is_unread'] ?? false) == true).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _updateAppBadge(int count) async {
    if (kIsWeb) {
      return;
    }

    try {
      // Check if app badge is supported on this device
      final isSupported = await AppBadgePlus.isSupported();

      if (isSupported) {
        if (count > 0) {
          // Update badge with count
          await AppBadgePlus.updateBadge(count);
        } else {
          // Remove badge when count is 0
          await AppBadgePlus.updateBadge(0);
        }
      }
    } on MissingPluginException {
      return;
    } catch (e) {
      debugPrint('Error updating app badge: $e');
    }
  }

  Future<void> _fetchRecentPosts({bool forceRefresh = false}) async {
    if (_isLoadingPosts && !forceRefresh) return;

    debugPrint('🔍 HomeScreen: Fetching recent posts...');

    if (mounted && !_disposed) {
      setState(() => _isLoadingPosts = true);
    }

    try {
      final posts = await _postService.fetchRecentPosts(limit: 10);

      debugPrint('✅ HomeScreen: Fetched ${posts.length} recent posts');

      // Cache the posts for offline viewing
      final postsJson = posts.map((post) => post.toJson()).toList();
      await OfflineCacheService.cacheSalePosts(postsJson);

      if (mounted && !_disposed) {
        setState(() {
          _recentPosts = posts;
          _isLoadingPosts = false;
          debugPrint(
              '📊 HomeScreen: _recentPosts now has ${_recentPosts?.length ?? 0} items');
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching recent posts: $e');

      // Try to load from cache when network fails
      final cachedPosts = await OfflineCacheService.getCachedSalePosts();

      if (mounted && !_disposed) {
        if (cachedPosts != null && cachedPosts.isNotEmpty) {
          // Convert cached data back to ClassifiedPost objects
          final posts =
              cachedPosts.map((json) => ClassifiedPost.fromJson(json)).toList();
          setState(() {
            _recentPosts = posts;
            _isLoadingPosts = false;
          });

          // Show offline indicator
          if (NetworkErrorHandler.isNetworkError(e)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    const Text('Showing cached content',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
                backgroundColor: const Color(0xFF6B7280),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          setState(() {
            _recentPosts = [];
            _isLoadingPosts = false;
          });

          // Show network error with professional message
          NetworkErrorHandler.showErrorSnackbar(
            context,
            e,
            onRetry: () => _fetchRecentPosts(forceRefresh: true),
          );
        }
      }
    }
  }

  Future<void> _handleRefresh() async {
    debugPrint('🔄 HomeScreen: Pull to refresh triggered');

    if (mounted && !_disposed) {
      setState(() {
        _homeRefreshEpoch++;
      });
    }

    // Force refresh recent posts (bypass loading check)
    await _fetchRecentPosts(forceRefresh: true);

    // Refresh unread message count if authenticated
    if (AuthService.isAuthenticated) {
      await _fetchUnreadMessageCount();
    }

    await _maybeShowHomePopup(force: true);

    debugPrint('✅ HomeScreen: Refresh completed');
  }

  Future<void> _refreshFromHomeNav() async {
    if (_scrollController.hasClients && _scrollController.offset > 0) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }

    await _refreshIndicatorKey.currentState?.show();
    await _maybeShowHomePopup(force: true);
  }

  Future<void> _maybeShowHomePopup({bool force = false}) async {
    if (_isHomePopupOpen) return;
    if (kDebugMode) {
      debugPrint('HomeScreen: checking home popup force=$force');
    }
    if (!force) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
    }
    if (!mounted || _disposed) return;

    final popup = await HomePopupService.fetchActiveMobilePopup();
    if (popup == null || !mounted || _disposed) {
      if (kDebugMode) {
        debugPrint('HomeScreen: no popup to show');
      }
      return;
    }
    _isHomePopupOpen = true;
    if (kDebugMode) {
      debugPrint('HomeScreen: showing popup ${popup.id}');
    }
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => HomePopupDialog(popup: popup),
      );
    } finally {
      _isHomePopupOpen = false;
    }
  }

  void _onScroll() {
    if (_disposed || !mounted) return;

    final currentScrollPosition = _scrollController.position.pixels;
    final scrollDelta = currentScrollPosition - _lastScrollPosition;

    // Only react to significant scroll movements
    if (scrollDelta.abs() < 5) {
      _lastScrollPosition = currentScrollPosition;
      return;
    }

    // Check if user is scrolling down or up. Setting the notifier repaints
    // only the header overlay (ValueListenableBuilder) — never the sections.
    if (scrollDelta > 0 && currentScrollPosition > 100) {
      // Scrolling down - hide header
      _isHeaderVisible.value = false;
    } else if (scrollDelta < 0) {
      // Scrolling up - show header
      _isHeaderVisible.value = true;
    }

    _lastScrollPosition = currentScrollPosition;
  }

  @override
  void dispose() {
    _disposed = true;
    _messageCountTimer?.cancel();
    _scrollController.dispose();
    _scrollService.dispose();
    _isHeaderVisible.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    final backButtonHasNotBeenPressedOrSnackBarHasBeenClosed =
        _lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2);

    if (backButtonHasNotBeenPressedOrSnackBarHasBeenClosed) {
      _lastBackPressTime = now;

      // Show toast message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t('press_back_to_exit'),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF374151),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      return false; // Don't exit
    }
    return true; // Exit app
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final refreshEdgeOffset = topPadding + 56;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          SystemNavigator.pop();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: Colors.grey.shade50,
          drawer: const MobileDrawer(),
          body: Stack(
            children: [
              // Scrollable content area with pull-to-refresh
              AdsyRefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: _handleRefresh,
                color: const Color(0xFF3B82F6),
                backgroundColor: Colors.white,
                edgeOffset: refreshEdgeOffset,
                displacement: 24,
                triggerMode: RefreshIndicatorTriggerMode.anywhere,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  child: Column(
                    children: [
                      // Add spacing for header
                      SizedBox(height: topPadding + 56 + 8),
                      // 1. Hero Banner - Main banner slider + service menu grid
                      HeroBanner(key: ValueKey('hero-$_homeRefreshEpoch')),

                      // 2. Gold Sponsors - existing business network sponsor slider
                      Padding(
                        key: ValueKey('gold-sponsors-$_homeRefreshEpoch'),
                        // Section self-pads 12px horizontally — keep only vertical
                        // gap here so all sections align to the same 12px gutter.
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: const GoldSponsorsSlider(margin: EdgeInsets.zero),
                      ),

                      // 3. Sale Category - eShop product categories
                      SaleCategory(
                        key: ValueKey('sale-category-$_homeRefreshEpoch'),
                        margin: const EdgeInsets.only(bottom: 4),
                      ),

                      // 4. Food Zone Section - FoodPanda style food listings
                      FoodZoneSection(
                        key: ValueKey('food-zone-$_homeRefreshEpoch'),
                        baseUrl: ApiService.baseUrl,
                      ),

                      // 5. Classified Services - Service categories
                      Container(
                        key: _classifiedSectionKey,
                        child: ClassifiedServicesSection(
                          key: ValueKey(
                              'classified-services-$_homeRefreshEpoch'),
                        ),
                      ),

                      // 6. Recent Ads Scroll - Horizontal scrolling carousel of recent posts
                      if (_isLoadingPosts)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 24, horizontal: 12),
                          child: Center(
                            child: AdsyLoadingIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF10B981),
                              ),
                            ),
                          ),
                        )
                      else if (_recentPosts != null && _recentPosts!.isNotEmpty)
                        AdsScrollWidget(
                          ads: _recentPosts,
                          sectionTitle: t('recent_post'),
                        )
                      else
                        // Flat empty state (no card) when there are no posts.
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 24, horizontal: 12),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 36, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text(
                                  t('no_recent_posts'),
                                  style: AppText.bodyText(),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // 7. eShop Product Slider - Product carousel
                      EshopSection(key: ValueKey('eshop-$_homeRefreshEpoch')),

                      // 8. Micro Gigs Section (with Account Balance & Mobile Recharge inside)
                      Container(
                        key: _microGigsSectionKey,
                        child: MicroGigsSection(
                          key: ValueKey('micro-gigs-$_homeRefreshEpoch'),
                        ),
                      ),

                      // Footer - always show the main footer content
                      const SizedBox(height: 32),
                      const AppFooter(
                        showMobileNav: false,
                      ),
                      // Space so the floating bottom nav doesn't cover content
                      const SizedBox(height: 96),
                    ],
                  ),
                ),
              ),

              // Animated Header positioned at top with proper elevation.
              // ValueListenableBuilder scopes the show/hide repaint to this
              // overlay only — the heavy section Column below never rebuilds.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isHeaderVisible,
                  builder: (context, headerVisible, child) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      transform: Matrix4.translationValues(
                        0,
                        headerVisible ? 0 : -(topPadding + 56.0),
                        0,
                      ),
                      curve: Curves.easeInOut,
                      child: child,
                    );
                  },
                  child: Material(
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.15),
                    color: Colors.white,
                    child: SafeArea(
                      bottom: false,
                      child: _buildFixedHeader(context),
                    ),
                  ),
                ),
              ),

              // User Dropdown Menu Overlay
              if (_isDropdownOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDropdownOpen = false;
                      });
                    },
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                ),

              // User Dropdown Menu
              if (_isDropdownOpen) _buildUserDropdownMenu(context),

              // Mobile Sticky Navigation — SafeArea guarantees correct inset on
              // iOS (home indicator) AND Android (gesture / 3-button nav bar).
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  left: false,
                  right: false,
                  child: MobileStickyNav(
                    currentRoute: 'Home',
                    scrollController: _scrollController,
                    onHomeRefresh: _refreshFromHomeNav,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserDropdownMenu(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 640; // sm breakpoint
    // Anchor below the fixed header: status-bar inset + 56px header + 4px gap.
    final topOffset = MediaQuery.of(context).padding.top + 56 + 4;

    return Positioned(
      top: topOffset,
      right: isMobile ? 8 : 16,
      child: Container(
        width: isMobile
            ? 288
            : 320, // w-72 (288px) mobile, sm:w-80 (320px) desktop
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height - 100),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12), // rounded-xl
          border: Border.all(
            color:
                const Color(0xFFCBD5E1).withValues(alpha: 0.5), // border-slate-200/50
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            child: _buildDropdownContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownContent(BuildContext context) {
    final userState = UserStateService();
    final user = userState.currentUser;
    final isPro = user?.isPro == true || user?.isSuperuser == true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated gradient accent at top (h-1 = 4px)
        Container(
          height: 4,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF818CF8), // primary-400
                Color(0xFF6366F1), // indigo-500
                Color(0xFF6366F1), // primary-600
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),

        // Membership Section shown on all platforms (upgrade action remains hidden on iOS).
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: _buildMembershipCard(context, isPro, user),
        ),

        // Main Navigation Grid - px-4 pt-2 pb-3
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 8) /
                  2; // Split width evenly minus gap
              return Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _buildNavLink(
                            context,
                            'business_network',
                            Icons.public_outlined,
                            const Color(0xFFF97316),
                            false,
                            null),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: cardWidth,
                        child: _buildNavLink(
                            context,
                            'adsy_news',
                            Icons.newspaper_outlined,
                            const Color(0xFF8B5CF6),
                            false,
                            null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _buildNavLink(
                            context,
                            'ad',
                            Icons.campaign_outlined,
                            const Color(0xFF10B981),
                            true,
                            t('free')),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: cardWidth,
                        child: _buildNavLink(
                            context,
                            'shop_manager',
                            Icons.shopping_bag_outlined,
                            const Color(0xFF3B82F6),
                            true,
                            t('pro')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _buildNavLink(
                            context,
                            'adsypay',
                            Icons.account_balance_wallet_outlined,
                            const Color(0xFF10B981),
                            false,
                            null),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: cardWidth,
                        child: _buildNavLink(
                            context,
                            'mobile_recharge',
                            Icons.phone_android,
                            const Color(0xFFF97316),
                            false,
                            null),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),

        // Settings & Logout Section - px-4 py-3
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFF1F5F9)), // border-slate-100
            ),
          ),
          child: Column(
            children: [
              // Settings & Verification Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: _buildActionButton(
                      context,
                      t('settings'),
                      Icons.settings_outlined,
                      const Color(0xFF64748B),
                      () {
                        setState(() => _isDropdownOpen = false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: _buildActionButton(
                      context,
                      t('verification'),
                      Icons.drive_folder_upload_outlined,
                      const Color(0xFF64748B),
                      () {
                        setState(() => _isDropdownOpen = false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const VerificationScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // Logout Button
              _buildLogoutButton(context, userState),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipCard(BuildContext context, bool isPro, user) {
    if (!isPro) {
      // Free User Card
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFFE2E8F0)), // border-slate-200
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Current Plan Header - px-3 py-2.5
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC), // bg-slate-50
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                border: const Border(
                  bottom:
                      BorderSide(color: Color(0xFFE2E8F0)), // border-slate-200
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        t('current_plan'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      t('free'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Upgrade to Pro Action - p-3.5 (hidden on iOS)
            if (!isIOSPlatform)
              InkWell(
                onTap: () {
                  setState(() => _isDropdownOpen = false);
                  Navigator.pushNamed(context, '/upgrade-to-pro');
                },
                child: Container(
                  padding: const EdgeInsets.all(14), // p-3.5
                  child: Row(
                    children: [
                      // Pro Badge Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFC4B5FD).withValues(alpha: 0.8),
                          ),
                        ),
                        child: const Center(
                          child: Text('⭐', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Upgrade Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  t('upgrade_pro'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFFBBF24),
                                        Color(0xFFF59E0B)
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '+',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t('upgrade_pro_text'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Toggle Switch - OFF state (free user)
                      Container(
                        width: 48,
                        height: 26,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade300,
                              Colors.grey.shade400
                            ],
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        padding: const EdgeInsets.all(2.5),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 21,
                            height: 21,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      // Pro User Card
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC7D2FE)),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Premium Access Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEEF2FF), Color(0xFFDEF7FD)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(
                  bottom: BorderSide(
                      color: const Color(0xFFE0E7FF).withValues(alpha: 0.3)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars,
                          size: 16, color: Color(0xFF6366F1)),
                      const SizedBox(width: 6),
                      Text(
                        t('premium_access'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          t('pro'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Pro Status - p-3.5
            InkWell(
              onTap: () {
                setState(() => _isDropdownOpen = false);
                // Navigate to settings or show subscription details
                Navigator.pushNamed(context, '/settings');
              },
              child: Container(
                padding: const EdgeInsets.all(14), // p-3.5
                child: Row(
                  children: [
                    // Premium Badge
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6366F1).withValues(alpha: 0.1),
                            const Color(0xFF2563EB).withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFC7D2FE).withValues(alpha: 0.5)),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Pro Status Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('pro_member'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Valid until Dec 31, 2025',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Active Toggle
                    Container(
                      width: 48,
                      height: 26,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF818CF8), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(13)),
                      ),
                      padding: const EdgeInsets.all(2.5),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 21,
                          height: 21,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildNavLink(BuildContext context, String key, IconData icon,
      Color color, bool hasBadge, String? badgeText) {
    return InkWell(
      onTap: () {
        debugPrint('🔵 Navigation tapped: $key');
        setState(() {
          _isDropdownOpen = false;
        });

        // Handle navigation based on key
        switch (key) {
          case 'adsypay':
          case 'deposit_withdraw':
            debugPrint('✅ Navigating to WalletScreen');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WalletScreen(),
              ),
            );
            break;
          case 'shop_manager':
          case 'eshop':
            debugPrint('✅ Navigating to /shop-manager');
            Navigator.pushNamed(context, '/shop-manager');
            break;
          case 'ad':
            debugPrint('✅ Navigating to /my-classified-posts');
            Navigator.pushNamed(context, '/my-classified-posts');
            break;
          case 'business_network':
            debugPrint('✅ Navigating to /business-network');
            Navigator.pushNamed(context, '/business-network');
            break;
          case 'adsy_news':
            debugPrint('✅ Navigating to NewsScreen');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewsScreen()),
            );
            break;
          case 'mobile_recharge':
            debugPrint('✅ Navigating to /mobile-recharge');
            Navigator.pushNamed(context, '/mobile-recharge');
            break;
          default:
            debugPrint('❌ Unknown navigation key: $key');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${t('navigate_to')} ${t(key)}'),
                backgroundColor: color,
                duration: const Duration(seconds: 1),
              ),
            );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity, // Fill the allocated width
            height: 90, // Increased height to prevent overflow
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.08),
                  color.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    t(key),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155),
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Badge (FREE or PRO)
          if (hasBadge && badgeText != null)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: badgeText == 'PRO'
                        ? const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF2563EB)],
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey.shade400,
                              Colors.grey.shade500
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (badgeText == 'PRO') ...[
                        const Icon(Icons.stars,
                            size: 9, color: Color(0xFFFDE68A)),
                        const SizedBox(width: 2),
                      ],
                      Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 4, vertical: 8), // Minimal horizontal padding
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9), // bg-slate-100
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 14, color: const Color(0xFF64748B)), // text-slate-500
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF334155), // text-slate-700
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, UserStateService userState) {
    return InkWell(
      onTap: () async {
        try {
          debugPrint('🔵 LOGOUT BUTTON TAPPED');

          // Close dropdown first
          if (mounted) {
            setState(() {
              _isDropdownOpen = false;
            });
            debugPrint('🔵 Dropdown closed');
          }

          // Wait for dropdown animation to complete and ensure widget is mounted
          await Future.delayed(const Duration(milliseconds: 250));

          if (!mounted || !context.mounted) {
            debugPrint('⚠️ Widget not mounted, cancelling logout');
            return;
          }

          debugPrint('🔵 Showing confirmation dialog...');

          // Show clean professional confirmation dialog
          final bool? confirmed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.all(24),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Simple icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFEF4444),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Message
                    Text(
                      'Are you sure you want to logout?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        // Cancel button
                        Expanded(
                          child: TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Logout button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );

          // If user confirmed logout
          if (confirmed == true) {
            debugPrint('🔴 USER CONFIRMED LOGOUT');

            // Check if widget is still mounted before showing snackbar
            if (!mounted || !context.mounted) {
              debugPrint('⚠️ Widget not mounted after dialog, cancelling logout');
              return;
            }

            // Show professional loading message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: AdsyLoadingIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Logging out...',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Please wait a moment',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                backgroundColor: const Color(0xFF6366F1),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
                elevation: 6,
                duration: const Duration(seconds: 2),
              ),
            );

            try {
              debugPrint('🔄 EMERGENCY LOGOUT - Clearing all data manually...');

              // Clear SharedPreferences directly
              final prefs = await SharedPreferences.getInstance();
              final keys = prefs.getKeys();
              debugPrint('📦 Found ${keys.length} keys in SharedPreferences');

              // Remove ALL auth-related keys
              for (final key in keys) {
                if (key.contains('adsyclub') ||
                    key.contains('token') ||
                    key.contains('user') ||
                    key.contains('auth')) {
                  debugPrint('🗑️ Removing key: $key');
                  await prefs.remove(key);
                }
              }

              debugPrint('🔄 Calling AuthService.logout()...');
              await AuthService.logout();
              debugPrint('✅ AuthService.logout() completed');

              debugPrint('🔄 Calling userState.clearUser()...');
              await userState.clearUser();
              debugPrint('✅ userState.clearUser() completed');

              // Force a small delay to ensure everything is cleared
              await Future.delayed(const Duration(milliseconds: 500));

              if (mounted && context.mounted) {
                debugPrint('🔄 Navigating to home and clearing stack...');
                // Navigate to home and clear entire navigation stack
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
                debugPrint('✅ Navigation completed');

                // Show professional success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Logged out successfully',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'See you again soon!',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                    elevation: 6,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              debugPrint('❌ LOGOUT ERROR: $e');
              debugPrint('Stack trace: ${StackTrace.current}');
              // Show professional error message if logout fails
              if (mounted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.error_outline_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Logout failed',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Please try again',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    backgroundColor: const Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                    elevation: 6,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          } else if (confirmed == false) {
            debugPrint('❌ USER CANCELLED LOGOUT');
          } else {
            debugPrint('⚠️ LOGOUT DIALOG RETURNED NULL');
          }
        } catch (e, stackTrace) {
          debugPrint('❌ LOGOUT BUTTON ERROR: $e');
          debugPrint('Stack trace: $stackTrace');

          // Try to show error message if context is still valid
          if (mounted && context.mounted) {
            try {
              AdsyToast.error(context, 'কিছু একটা সমস্যা হয়েছে');
            } catch (snackbarError) {
              debugPrint('❌ Could not show error snackbar: $snackbarError');
            }
          }
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8), // py-2 px-3
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2), // bg-red-50
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                size: 16,
                color: Color(0xFFEF4444), // text-red-500
              ),
            ),
            const SizedBox(width: 8),
            Text(
              t('logout'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFDC2626), // text-red-600
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedHeader(BuildContext context) {
    final userState = UserStateService();

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListenableBuilder(
        listenable: userState,
        builder: (context, _) {
          return Row(
            children: [
              // Menu Button
              Builder(
                builder: (context) => Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: Color(0xFF1F2937),
                      size: 22,
                    ),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    tooltip: 'Menu',
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Logo
              _buildDynamicLogo(context),

              const Spacer(),

              // Right side actions
              _buildHeaderActions(context, userState),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDynamicLogo(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to home
        Navigator.pushNamed(context, '/');
      },
      child: Container(
        height: 28,
        constraints: BoxConstraints(
          maxWidth: 120,
        ),
        child: Image.asset(
          'assets/images/logo.png',
          height: 28,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'AdsyClub',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderActions(BuildContext context, UserStateService userState) {
    final isAuthenticated = userState.isAuthenticated;
    final user = userState.currentUser;

    if (!isAuthenticated || user == null) {
      // Guest user - show login button (no background, icon + label)
      return GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/login'),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_outline_rounded,
                color: Color(0xFF3B82F6),
                size: 22,
              ),
              const SizedBox(width: 6),
              const Text(
                'Login/Signup',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Logged in user
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Inbox button with badge
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InboxScreen()),
            );
            // Refresh count when returning from inbox
            _fetchUnreadMessageCount();
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/chat_icon.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.forum_outlined,
                        color: Color(0xFF3B82F6),
                        size: 24,
                      );
                    },
                  ),
                ),
              ),
              // Unread count badge
              if (_unreadMessageCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _unreadMessageCount > 9 ? 5 : 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadMessageCount > 99
                          ? '99+'
                          : _unreadMessageCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),

        SizedBox(width: 4),

        // QR Code button
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AdsyPayQrModal(
                qrData: 'adsypay://pay/${user.id}',
                title: '${user.firstName ?? user.username}\'s QR',
              ),
            );
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_scanner,
              color: Colors.green.shade600,
              size: 24,
            ),
          ),
        ),

        SizedBox(width: 4),

        // User profile with Pro/Verified badges
        _buildUserProfile(context, user),
      ],
    );
  }

  Widget _buildUserProfile(BuildContext context, dynamic user) {
    final isPro = user.isPro ?? false;
    final isVerified = user.isVerified ?? false;
    final profilePic = user.profilePicture ?? '';
    final displayName =
        user.firstName ?? user.displayName ?? user.username ?? 'U';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: () {
        setState(() {
          _isDropdownOpen = !_isDropdownOpen;
        });
      },
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPro ? Color(0xFF6366F1) : Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  if (isPro)
                    BoxShadow(
                      color: Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: profilePic.isNotEmpty
                    ? Image.network(
                        profilePic,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Color(0xFF10B981),
                            child: Center(
                              child: Text(
                                initial,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Color(0xFF10B981),
                        child: Center(
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            // Pro badge (top-right)
            if (isPro)
              Positioned(
                top: -6,
                right: -10,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF6366F1).withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield,
                        size: 10,
                        color: Colors.white,
                      ),
                      SizedBox(width: 2),
                      Text(
                        'Pro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Verified badge (bottom-right)
            if (isVerified)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.verified,
                    size: 18,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }


}
