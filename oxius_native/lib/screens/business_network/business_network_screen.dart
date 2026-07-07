import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import '../../services/ads_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_suggestions_service.dart';
import '../../services/notification_service.dart';
import '../../services/fcm_service.dart';
import '../../widgets/ads/feed_native_ad_card.dart';
import '../../widgets/business_network/post_card.dart';
import '../../widgets/business_network/bottom_nav_bar.dart';
import '../../widgets/business_network/business_network_header.dart';
import '../../widgets/business_network/business_network_drawer.dart';
import '../../widgets/business_network/gold_sponsors_slider.dart';
import '../../widgets/business_network/user_suggestions_card.dart';
import '../../widgets/business_network/sponsored_products_card.dart';
import '../../widgets/business_network/feed_discovery_cards.dart';
import '../../widgets/common/adsy_loading.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';
import 'profile_options.dart';

class BusinessNetworkScreen extends StatefulWidget {
  const BusinessNetworkScreen({super.key});

  @override
  State<BusinessNetworkScreen> createState() => _BusinessNetworkScreenState();
}

class _BusinessNetworkScreenState extends State<BusinessNetworkScreen> {
  // The interleaved feed layout (posts + injected cards), recomputed each build.
  List<_FeedSlot> _feedSlots = const [];
  List<BusinessNetworkPost> _posts = [];
  List<Map<String, dynamic>> _shuffledSponsoredProducts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _lastCreatedAt;
  int _currentNavIndex = 0;
  String? _errorMessage;
  int _unreadNotificationCount = 0;

  final ScrollController _scrollController = ScrollController();
  bool _isChromeVisible = true;
  bool _disposed = false;
  double _lastScrollPosition = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Random _random = Random();

  static const ScrollPhysics _feedScrollPhysics =
      AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadSponsoredProducts();
    _loadUnreadNotificationCount();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkCommunityGuidelines());
  }

  /// Apple Guideline 1.2 — Block first-time users from UGC until they
  /// explicitly accept the community guidelines / EULA. Persists acceptance
  /// in SharedPreferences so returning users don't see it again.
  Future<void> _checkCommunityGuidelines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'bn_guidelines_accepted_v1';
      final accepted = prefs.getBool(key) ?? false;
      if (accepted || !mounted) return;

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => PopScope(
          canPop: false,
          child: Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 20),
            backgroundColor: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Community Guidelines',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome to the Business Network, a community for professional and respectful interaction.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.55,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'By continuing, you agree to our End User License Agreement (EULA) and confirm that you will:',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.55,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildGuidelineItem(
                            'Not post content that is objectionable, abusive, harassing, hateful, sexually explicit, discriminatory, or illegal.'),
                        const SizedBox(height: 10),
                        _buildGuidelineItem(
                            'Not impersonate others, spread misinformation, or infringe intellectual property.'),
                        const SizedBox(height: 10),
                        _buildGuidelineItem(
                            'Respect other users. You can block or report any user or post at any time.'),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            'We have zero tolerance for abusive content. Reported content and users are reviewed within 24 hours and removed if guidelines are violated. Your account may be terminated for violations.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.55,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogCtx).pop(false),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFDC2626),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                child: const Text(
                                  'Decline',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(dialogCtx).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                child: const Text(
                                  'I Agree',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      if (result == true) {
        await prefs.setBool(key, true);
      } else if (mounted) {
        // User declined — leave the Business Network.
        Navigator.of(context).maybePop();
      }
    } catch (_) {
      // Non-fatal: if prefs fail, don't block the user.
    }
  }

  Widget _buildGuidelineItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 7),
          decoration: const BoxDecoration(
            color: Color(0xFF2563EB),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade900,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadSponsoredProducts() async {
    try {
      final products =
          await UserSuggestionsService.getSponsoredProducts(limit: 20);
      if (mounted) {
        setState(() {
          _shuffledSponsoredProducts = List<Map<String, dynamic>>.from(products)
            ..shuffle(_random);
        });
      }
    } catch (e) {
      debugPrint('Error loading sponsored products: $e');
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    if (!AuthService.isAuthenticated) return;

    try {
      final result = await NotificationService.getNotifications(page: 1);
      if (mounted) {
        setState(() {
          _unreadNotificationCount = result['unreadCount'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading notification count: $e');
    }
  }

  List<Map<String, dynamic>> _getSponsoredProductsForSlot(
      int slotIndex, int count) {
    if (_shuffledSponsoredProducts.isEmpty) {
      return [];
    }

    final safeCount = count.clamp(0, _shuffledSponsoredProducts.length);
    if (safeCount == 0) {
      return [];
    }

    final startIndex =
        (slotIndex * safeCount) % _shuffledSponsoredProducts.length;
    final selectedProducts = <Map<String, dynamic>>[];

    for (int offset = 0; offset < safeCount; offset++) {
      final productIndex =
          (startIndex + offset) % _shuffledSponsoredProducts.length;
      selectedProducts.add(_shuffledSponsoredProducts[productIndex]);
    }

    return selectedProducts;
  }

  List<BusinessNetworkPost> _getVisiblePosts() {
    return _posts;
  }

  // Server-config driven: insert a MAX native ad after every N posts, at
  // slots that don't collide with suggestions (every 10th) or sponsored
  // products (every 5th).
  bool get _feedAdsActive => AdsService.placementActive('bn_feed_native');
  int get _feedAdFrequency => AdsService.feedFrequency('bn_feed_native');

  bool _isAdSlot(int i) =>
      _feedAdsActive &&
      i > 0 &&
      i % _feedAdFrequency == 0 &&
      i % 5 != 0 &&
      i % 10 != 0;

  // Single source of truth for the interleaved feed. Both the item count and
  // each item are read off this list, so injected cards can never desync from
  // the post positions. Discovery cards (micro gigs / news / workspace gigs)
  // are woven in at spaced, mostly-non-colliding offsets so the feed stays
  // informative without feeling spammy; empty ones render as zero-height.
  List<_FeedSlot> _composeSlots(List<BusinessNetworkPost> posts) {
    final slots = <_FeedSlot>[const _FeedSlot(_FeedSlotType.topHeader)];
    int sponsoredSlot = 0;
    int newsSlot = 0;
    for (int i = 0; i < posts.length; i++) {
      if (i > 0 && i % 10 == 0 && AuthService.isAuthenticated) {
        slots.add(const _FeedSlot(_FeedSlotType.userSuggestions));
      }
      if (i > 0 && i % 5 == 0 && i % 10 != 0) {
        slots.add(_FeedSlot(_FeedSlotType.sponsored, slotIndex: sponsoredSlot++));
      }
      if (_isAdSlot(i)) {
        slots.add(_FeedSlot(_FeedSlotType.nativeAd, slotIndex: i));
      }
      // Discovery rows — different periods/offsets keep them apart.
      if (i > 0 && i % 7 == 3) {
        slots.add(const _FeedSlot(_FeedSlotType.microGigs));
      }
      if (i > 0 && i % 9 == 6) {
        // slotIndex → which story this occurrence shows (rotates the list).
        slots.add(_FeedSlot(_FeedSlotType.news, slotIndex: newsSlot++));
      }
      if (i > 0 && i % 11 == 8) {
        slots.add(const _FeedSlot(_FeedSlotType.workspaceGigs));
      }
      slots.add(_FeedSlot(_FeedSlotType.post, postIndex: i));
    }
    slots.add(const _FeedSlot(_FeedSlotType.footer));
    return slots;
  }

  @override
  void dispose() {
    _disposed = true;
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_disposed || !mounted) return;

    final currentScrollPosition = _scrollController.position.pixels;
    final scrollDelta = currentScrollPosition - _lastScrollPosition;

    // Prefetch the next page well before the end (~1000px) so the user never
    // hits an empty gap while scrolling.
    if (currentScrollPosition >=
        _scrollController.position.maxScrollExtent - 1000) {
      if (!_isLoadingMore && _hasMore) {
        _loadMorePosts();
      }
    }

    // Only react to significant scroll movements (threshold of 5px)
    if (scrollDelta.abs() < 5) {
      _lastScrollPosition = currentScrollPosition;
      return;
    }

    // Check if user is scrolling down or up
    if (scrollDelta > 0 && currentScrollPosition > 100) {
      // Scrolling down - hide header/footer
      if (_isChromeVisible) {
        setState(() {
          _isChromeVisible = false;
        });
      }
    } else if (scrollDelta < 0) {
      // Scrolling up - show header/footer
      if (!_isChromeVisible) {
        setState(() {
          _isChromeVisible = true;
        });
      }
    }

    _lastScrollPosition = currentScrollPosition;
  }

  Future<void> _loadPosts({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await BusinessNetworkService.getPosts(
        page: 1, pageSize: 5, forceRefresh: forceRefresh);

    if (mounted) {
      setState(() {
        _posts = result['posts'] as List<BusinessNetworkPost>;
        _hasMore = result['hasMore'] as bool;
        _isLoading = false;

        // Check for errors
        if (result.containsKey('error')) {
          if (result['error'] == 'unauthorized') {
            _errorMessage = 'Please log in to view business network posts';
          } else {
            _errorMessage = 'Failed to load posts. Please try again.';
          }
        }

        if (_posts.isNotEmpty) {
          _lastCreatedAt = _posts.last.createdAt;
        }
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    _currentPage++;
    final result = await BusinessNetworkService.getPosts(
      page: _currentPage,
      pageSize: 5,
      olderThan: _lastCreatedAt,
    );

    if (mounted) {
      final newPosts = result['posts'] as List<BusinessNetworkPost>;
      setState(() {
        if (newPosts.isNotEmpty) {
          _posts.addAll(newPosts);
          _lastCreatedAt = newPosts.last.createdAt;
        }
        _hasMore = result['hasMore'] as bool;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshPosts() async {
    _currentPage = 1;
    _lastCreatedAt = null;
    await Future.wait([
      _loadPosts(forceRefresh: true),
      _loadSponsoredProducts(),
    ]);
  }

  /// Scroll the feed to the top and pull fresh posts — used when the user taps
  /// the already-active "Recent" feed tab (standard "tap active tab" behaviour).
  void _scrollToTopAndRefresh() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    _refreshPosts();
  }

  void _openCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    ).then((newPost) {
      if (newPost != null && newPost is BusinessNetworkPost) {
        setState(() {
          _posts.insert(0, newPost);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final visiblePosts = _getVisiblePosts();
    // Compose the interleaved feed once per build (cheap), then drive both the
    // item count and each item off it.
    _feedSlots = _composeSlots(visiblePosts);
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + kToolbarHeight;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF9FAFB),
        drawer: isMobile
            ? const BusinessNetworkDrawer(currentRoute: '/business-network')
            : null,
        body: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: 672), // max-w-3xl (768px - padding)
                child: AdsyRefreshIndicator(
                  onRefresh: _refreshPosts,
                  color: const Color(0xFF3B82F6),
                  edgeOffset: headerHeight,
                  child: _isLoading
                      ? _buildLoadingState(headerHeight, isMobile)
                      : _errorMessage != null
                          ? _buildRefreshableState(
                              child: _buildErrorState(),
                              headerHeight: headerHeight,
                              isMobile: isMobile,
                            )
                          : visiblePosts.isEmpty
                              ? _buildRefreshableState(
                                  child: _buildEmptyState(),
                                  headerHeight: headerHeight,
                                  isMobile: isMobile,
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  physics: _feedScrollPhysics,
                                  // Build ~1.5 screens ahead so images decode
                                  // before they scroll into view (smoother feed).
                                  cacheExtent: 1200,
                                  padding: EdgeInsets.fromLTRB(
                                    1,
                                    headerHeight + 8,
                                    1,
                                    isMobile ? 80 : 16,
                                  ),
                                  itemCount: _feedSlots.length,
                                  itemBuilder: (context, index) {
                                    // RepaintBoundary isolates each card so one
                                    // card repainting doesn't repaint the list.
                                    return RepaintBoundary(
                                      child: _buildFeedSlot(
                                          _feedSlots[index], visiblePosts),
                                    );
                                  },
                                ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                transform: Matrix4.translationValues(
                  0,
                  _isChromeVisible ? 0 : -(headerHeight + 16),
                  0,
                ),
                curve: Curves.easeInOut,
                child: BusinessNetworkHeader(
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  onSearchTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                  onProfileTap: () {
                    final currentUser = AuthService.currentUser;
                    if (currentUser != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfileScreen(userId: currentUser.id),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
            if (isMobile)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  transform: Matrix4.translationValues(
                    0,
                    _isChromeVisible ? 0 : 120,
                    0,
                  ),
                  curve: Curves.easeInOut,
                  child: BusinessNetworkBottomNavBar(
                    currentIndex: _currentNavIndex,
                    isLoggedIn: AuthService.isAuthenticated,
                    onTap: (index) {
                      if (index == 2) {
                        // Create post button
                        _openCreatePost();
                      } else {
                        _handleNavTap(index);
                      }
                    },
                    unreadCount: _unreadNotificationCount,
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: !isMobile
            ? FloatingActionButton(
                onPressed: _openCreatePost,
                backgroundColor: const Color(0xFF3B82F6),
                elevation: 4,
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              )
            : null,
      ),
    );
  }

  void _handleNavTap(int index) {
    final isLoggedIn = AuthService.isAuthenticated;

    switch (index) {
      case 0:
        // "Recent" feed tab. Tapping it (even when already selected) now
        // scrolls to top and reloads fresh posts instead of doing nothing.
        setState(() => _currentNavIndex = 0);
        _scrollToTopAndRefresh();
        break;
      case 1:
        if (isLoggedIn) {
          // Notifications (for logged-in users)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsScreen(),
            ),
          ).then((_) {
            // Reset index when coming back
            if (mounted) setState(() => _currentNavIndex = 0);
          });
        } else {
          // Login (for logged-out users)
          Navigator.pushNamed(context, '/login').then((_) {
            // Reset index when coming back
            if (mounted) setState(() => _currentNavIndex = 0);
          });
        }
        break;
      case 3:
        if (isLoggedIn) {
          // Profile - Navigate to ProfileOptionsScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileOptionsScreen(),
            ),
          ).then((_) {
            if (mounted) setState(() => _currentNavIndex = 0);
          });
        } else {
          Navigator.pushNamed(context, '/login');
        }
        break;
      case 4:
        // AdsyClub / Home - Navigate to main home screen
        final rootNavigator =
            FCMService.navigatorKey.currentState ?? Navigator.of(context);
        rootNavigator.pushNamedAndRemoveUntil('/', (route) => false);
        break;
    }
  }

  Widget _buildFeedTopHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: GoldSponsorsSlider(),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildFeedSlot(
      _FeedSlot slot, List<BusinessNetworkPost> visiblePosts) {
    switch (slot.type) {
      case _FeedSlotType.topHeader:
        return _buildFeedTopHeader();

      case _FeedSlotType.userSuggestions:
        return const UserSuggestionsCard();

      case _FeedSlotType.sponsored:
        return SponsoredProductsCard(
          key: ValueKey('sponsored_products_${slot.slotIndex}'),
          // Carousel row — hand it more products than the old 2-up grid.
          products: _getSponsoredProductsForSlot(slot.slotIndex ?? 0, 8),
        );

      case _FeedSlotType.nativeAd:
        return FeedNativeAdCard(key: ValueKey('feed_ad_${slot.slotIndex}'));

      case _FeedSlotType.microGigs:
        return const FeedMicroGigsCard();

      case _FeedSlotType.news:
        // Different story per slot so scrolling shows fresh news each time.
        return FeedNewsCard(
          key: ValueKey('feed_news_${slot.slotIndex}'),
          index: slot.slotIndex ?? 0,
        );

      case _FeedSlotType.workspaceGigs:
        return const FeedWorkspaceGigsCard();

      case _FeedSlotType.post:
        final post = visiblePosts[slot.postIndex!];
        return PostCard(
          key: ValueKey('post_${post.id}'),
          post: post,
          onPostUpdated: _handlePostUpdated,
          onCommentAdded: (comment) =>
              _handleCommentAddedByPostId(post.id, comment),
          onPostDeleted: () => _handlePostDeletedByPostId(post.id),
          onUserBlocked: _handleUserBlocked,
        );

      case _FeedSlotType.footer:
        if (_isLoadingMore) return _buildLoadingMoreIndicator();
        if (!_hasMore && visiblePosts.isNotEmpty) {
          return _buildEndOfFeedIndicator();
        }
        return const SizedBox(height: 80);
    }
  }

  Widget _buildRefreshableState({
    required Widget child,
    required double headerHeight,
    required bool isMobile,
  }) {
    final bottomPadding = isMobile ? 80.0 : 16.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight =
            max(0.0, constraints.maxHeight - headerHeight - bottomPadding - 8);

        return SingleChildScrollView(
          physics: _feedScrollPhysics,
          padding: EdgeInsets.fromLTRB(1, headerHeight + 8, 1, bottomPadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(double headerHeight, bool isMobile) {
    return ListView.builder(
      physics: _feedScrollPhysics,
      padding: EdgeInsets.fromLTRB(4, headerHeight + 8, 4, isMobile ? 80 : 16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 10,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 14,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Posts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshPosts,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.business_center,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share something!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openCreatePost,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Create Post'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Column(
      children: List.generate(2, (index) => _buildSkeletonPost()),
    );
  }

  Widget _buildSkeletonPost() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Row(
            children: [
              _buildShimmerBox(40, 40, borderRadius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(12, 120),
                    const SizedBox(height: 6),
                    _buildShimmerBox(10, 80),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Content skeleton
          _buildShimmerBox(14, double.infinity),
          const SizedBox(height: 6),
          _buildShimmerBox(14, double.infinity),
          const SizedBox(height: 6),
          _buildShimmerBox(14, 200),

          const SizedBox(height: 12),

          // Image skeleton
          _buildShimmerBox(180, double.infinity, borderRadius: 8),

          const SizedBox(height: 12),

          // Actions skeleton
          Row(
            children: [
              _buildShimmerBox(28, 60, borderRadius: 6),
              const SizedBox(width: 12),
              _buildShimmerBox(28, 60, borderRadius: 6),
              const Spacer(),
              _buildShimmerBox(28, 60, borderRadius: 6),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox(double height, double width, {double? borderRadius}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-1.0, 0.0),
          end: Alignment(1.0, 0.0),
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(borderRadius ?? 4),
      ),
    );
  }

  Widget _buildEndOfFeedIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF3B82F6),
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You\'ve seen all posts',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePostUpdated(BusinessNetworkPost updatedPost) {
    if (!mounted) return;

    final index = _posts.indexWhere((p) => p.id == updatedPost.id);
    if (index < 0) return;

    setState(() {
      _posts[index] = updatedPost;
    });
  }

  void _handleCommentAddedByPostId(int postId, BusinessNetworkComment comment) {
    if (mounted) {
      setState(() {
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index < 0) return;

        final post = _posts[index];
        _posts[index] = post.copyWith(
          commentsCount: post.commentsCount + 1,
          comments: [...post.comments, comment],
        );
      });
    }
  }

  void _handlePostDeletedByPostId(int postId) {
    if (mounted) {
      setState(() {
        _posts.removeWhere((p) => p.id == postId);
      });
    }
  }

  void _handleUserBlocked(String userId) {
    setState(() {
      _posts.removeWhere((post) {
        final postUserIds = {
          post.user.uuid,
          post.user.id.toString(),
        }.whereType<String>();
        return postUserIds.contains(userId);
      });
    });
  }
}

/// The kinds of rows the interleaved feed can render.
enum _FeedSlotType {
  topHeader,
  post,
  userSuggestions,
  sponsored,
  nativeAd,
  microGigs,
  news,
  workspaceGigs,
  footer,
}

/// A single resolved feed row: its type plus the index it maps to.
class _FeedSlot {
  final _FeedSlotType type;
  final int? postIndex; // for a post row
  final int? slotIndex; // for sponsored / native-ad rows

  const _FeedSlot(this.type, {this.postIndex, this.slotIndex});
}
