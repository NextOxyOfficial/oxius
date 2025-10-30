import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/footer.dart';
import '../widgets/mobile_drawer.dart';
import '../widgets/hero_banner.dart';
import '../widgets/sale_category.dart';
import '../widgets/classified_services_section.dart';
import '../widgets/eshop_section.dart';
import '../widgets/micro_gigs_section.dart';
import '../widgets/home/account_balance_section.dart';
import '../widgets/home/mobile_recharge_section.dart';
import '../widgets/mobile_sticky_nav.dart';
import '../widgets/ads_scroll_widget.dart';
import '../services/scroll_direction_service.dart';
import '../services/user_state_service.dart';
import '../services/auth_service.dart';
import '../services/translation_service.dart';
import '../services/classified_post_service.dart';
import '../services/api_service.dart';
import '../models/classified_post.dart';
import 'wallet/wallet_screen.dart';
import 'settings_screen.dart';
import 'inbox_screen.dart';
import 'eshop_screen.dart';
import 'news_screen.dart';
import 'verification_screen.dart';
import '../widgets/business_network/adsypay_qr_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ScrollController _scrollController;
  late ClassifiedPostService _postService;
  final ScrollDirectionService _scrollService = ScrollDirectionService();
  final TranslationService _translationService = TranslationService();
  bool _disposed = false;
  bool _isDropdownOpen = false; // Track dropdown menu state
  List<ClassifiedPost>? _recentPosts;
  bool _isLoadingPosts = false;

  // Header animation
  bool _isHeaderVisible = true;
  double _lastScrollPosition = 0;

  // Double-tap back to exit
  DateTime? _lastBackPressTime;

  // Helper method to translate keys
  String t(String key) {
    return _translationService.translate(key);
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
      }
    });
    _fetchRecentPosts();
  }

  Future<void> _fetchRecentPosts() async {
    if (_isLoadingPosts) return;

    print('🔍 HomeScreen: Fetching recent posts...');
    setState(() => _isLoadingPosts = true);

    try {
      final posts = await _postService.fetchRecentPosts(limit: 10);

      print('✅ HomeScreen: Fetched ${posts.length} recent posts');

      if (mounted && !_disposed) {
        setState(() {
          _recentPosts = posts;
          _isLoadingPosts = false;
          print('📊 HomeScreen: _recentPosts now has ${_recentPosts?.length ?? 0} items');
        });
      }
    } catch (e) {
      print('❌ Error fetching recent posts: $e');
      if (mounted && !_disposed) {
        setState(() {
          _recentPosts = [];
          _isLoadingPosts = false;
        });
      }
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

    // Check if user is scrolling down or up
    if (scrollDelta > 0 && currentScrollPosition > 100) {
      // Scrolling down - hide header
      if (_isHeaderVisible) {
        setState(() {
          _isHeaderVisible = false;
        });
      }
    } else if (scrollDelta < 0) {
      // Scrolling up - show header
      if (!_isHeaderVisible) {
        setState(() {
          _isHeaderVisible = true;
        });
      }
    }

    _lastScrollPosition = currentScrollPosition;
  }

  @override
  void dispose() {
    _disposed = true;
    _scrollController.removeListener(_onScroll);
    // Dispose scroll service before disposing the controller
    _scrollService.dispose();
    _scrollController.dispose();
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
                const Expanded(
                  child: Text(
                    'Press back again to exit',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
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
          // Scrollable content area
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
                children: [
                  // Add spacing for header
                  SizedBox(height: MediaQuery.of(context).padding.top + 56 + 8),
                  // 1. Hero Banner - Main banner slider + service menu grid
                  const HeroBanner(),
                  
                  // 2. Sale Category - eShop product categories
                  const SaleCategory(),
                  
                  // 3. Search Form - TODO: Implement search functionality for classified ads
                  // This is a placeholder for the search form section from Vue
                  
                  // 4. Classified Services - Service categories
                  const ClassifiedServicesSection(),
                  
                  // 5. Recent Ads Scroll - Horizontal scrolling carousel of recent posts
                  if (_isLoadingPosts)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
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
                    // Debug: Show message if no posts
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.info_outline, size: 40, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              'No recent posts available',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            Text(
                              'Posts loaded: ${_recentPosts?.length ?? 0}',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // 6. eShop Product Slider - Product carousel
                  const EshopSection(),
                  
                  // 7. Micro Gigs Section (with Account Balance & Mobile Recharge inside)
                  const MicroGigsSection(),
                  
                  // Footer - always show the main footer content
                  const SizedBox(height: 32),
                  const AppFooter(
                    showMobileNav: false,
                  ),
                ],
              ),
            ),
          
          // Animated Header positioned at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              transform: Matrix4.translationValues(
                0,
                _isHeaderVisible ? 0 : -100, // Slide up by 100px when hidden
                0,
              ),
              curve: Curves.easeInOut,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200.withOpacity(0.5),
                      width: 0.5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
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
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
            ),
          
          // User Dropdown Menu
          if (_isDropdownOpen)
            _buildUserDropdownMenu(context),
          
          // Mobile Sticky Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MobileStickyNav(
              currentRoute: 'Home',
              scrollController: _scrollController,
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
    
    return Positioned(
      top: 68, // Below header (top-12)
      right: isMobile ? 8 : 16,
      child: Container(
        width: isMobile ? 288 : 320, // w-72 (288px) mobile, sm:w-80 (320px) desktop
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height - 100),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12), // rounded-xl
          border: Border.all(
            color: const Color(0xFFCBD5E1).withOpacity(0.5), // border-slate-200/50
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
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
    final isPro = user?.userType == 'pro' || user?.isSuperuser == true;
    
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
        
        // Membership Section - px-2 pb-3 (8px horizontal, 12px bottom)
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: _buildMembershipCard(context, isPro, user),
        ),
        
        // Main Navigation Grid - px-4 pt-2 pb-3
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 8) / 2; // Split width evenly minus gap
              return Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _buildNavLink(context, t('business_network'), Icons.public_outlined, 
                          const Color(0xFFF97316), false, null),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: cardWidth,
                        child: _buildNavLink(context, t('adsy_news'), Icons.newspaper_outlined, 
                          const Color(0xFF8B5CF6), false, null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _buildNavLink(context, t('ad'), Icons.campaign_outlined, 
                          const Color(0xFF10B981), true, t('free')),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: cardWidth,
                        child: _buildNavLink(context, t('eshop'), Icons.shopping_bag_outlined, 
                          const Color(0xFF3B82F6), true, t('pro')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _buildNavLink(context, 'AdsyPay', Icons.account_balance_wallet_outlined, 
                          const Color(0xFF10B981), false, null),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: cardWidth,
                        child: _buildNavLink(context, t('mobile_recharge'), Icons.phone_android, 
                          const Color(0xFFF97316), false, null),
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
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
                          MaterialPageRoute(builder: (context) => const VerificationScreen()),
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
          border: Border.all(color: const Color(0xFFE2E8F0)), // border-slate-200
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Current Plan Header - px-3 py-2.5
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC), // bg-slate-50
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)), // border-slate-200
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            // Upgrade to Pro Action - p-3.5
            InkWell(
              onTap: () {
                setState(() => _isDropdownOpen = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t('upgrade_pro')),
                    backgroundColor: const Color(0xFF6366F1),
                  ),
                );
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
                          colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFC4B5FD).withOpacity(0.8),
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
                                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
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
                    // Toggle Switch
                    Container(
                      width: 48,
                      height: 26,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade300, Colors.grey.shade400],
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
                                color: Colors.black.withOpacity(0.1),
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(
                  bottom: BorderSide(color: const Color(0xFFE0E7FF).withOpacity(0.3)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars, size: 16, color: Color(0xFF6366F1)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, size: 12, color: Colors.white),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Manage Subscription'),
                    backgroundColor: Color(0xFF6366F1),
                  ),
                );
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
                            const Color(0xFF6366F1).withOpacity(0.1),
                            const Color(0xFF2563EB).withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC7D2FE).withOpacity(0.5)),
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
                                color: Colors.black.withOpacity(0.1),
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

  Widget _buildNavLink(BuildContext context, String label, IconData icon, 
      Color color, bool hasBadge, String? badgeText) {
    return InkWell(
      onTap: () {
        setState(() {
          _isDropdownOpen = false;
        });
        
        // Handle navigation based on label
        if (label == 'AdsyPay' || label == t('deposit_withdraw')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WalletScreen(),
            ),
          );
        } else if (label == t('eshop')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EshopScreen(),
            ),
          );
        } else if (label == t('ad')) {
          // Navigate to My Classified Posts
          Navigator.pushNamed(context, '/my-classified-posts');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigate to $label'),
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
                  color.withOpacity(0.08),
                  color.withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.15),
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
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    label,
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
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: badgeText == 'PRO'
                        ? const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF2563EB)],
                          )
                        : LinearGradient(
                            colors: [Colors.grey.shade400, Colors.grey.shade500],
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (badgeText == 'PRO') ...[
                        const Icon(Icons.stars, size: 9, color: Color(0xFFFDE68A)),
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), // Minimal horizontal padding
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
              child: Icon(icon, size: 14, color: const Color(0xFF64748B)), // text-slate-500
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
          print('🔵 LOGOUT BUTTON TAPPED');
          
          // Close dropdown first
          if (mounted) {
            setState(() {
              _isDropdownOpen = false;
            });
            print('🔵 Dropdown closed');
          }
          
          // Wait for dropdown animation to complete and ensure widget is mounted
          await Future.delayed(const Duration(milliseconds: 250));
          
          if (!mounted) {
            print('⚠️ Widget not mounted, cancelling logout');
            return;
          }
          
          print('🔵 Showing confirmation dialog...');
          
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
                            onPressed: () => Navigator.of(dialogContext).pop(false),
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
                            onPressed: () => Navigator.of(dialogContext).pop(true),
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
          print('🔴 USER CONFIRMED LOGOUT');
          
          // Check if widget is still mounted before showing snackbar
          if (!mounted) {
            print('⚠️ Widget not mounted after dialog, cancelling logout');
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
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                              color: Colors.white.withOpacity(0.8),
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
            print('🔄 EMERGENCY LOGOUT - Clearing all data manually...');
            
            // Clear SharedPreferences directly
            final prefs = await SharedPreferences.getInstance();
            final keys = prefs.getKeys();
            print('📦 Found ${keys.length} keys in SharedPreferences');
            
            // Remove ALL auth-related keys
            for (final key in keys) {
              if (key.contains('adsyclub') || key.contains('token') || key.contains('user') || key.contains('auth')) {
                print('🗑️ Removing key: $key');
                await prefs.remove(key);
              }
            }
            
            print('🔄 Calling AuthService.logout()...');
            await AuthService.logout();
            print('✅ AuthService.logout() completed');
            
            print('🔄 Calling userState.clearUser()...');
            await userState.clearUser();
            print('✅ userState.clearUser() completed');
            
            // Force a small delay to ensure everything is cleared
            await Future.delayed(const Duration(milliseconds: 500));
            
            if (mounted) {
              print('🔄 Navigating to home and clearing stack...');
              // Navigate to home and clear entire navigation stack
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
              print('✅ Navigation completed');
              
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
                            color: Colors.white.withOpacity(0.2),
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
                                  color: Colors.white.withOpacity(0.8),
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
            print('❌ LOGOUT ERROR: $e');
            print('Stack trace: ${StackTrace.current}');
            // Show professional error message if logout fails
            if (mounted) {
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
                            color: Colors.white.withOpacity(0.2),
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
                                  color: Colors.white.withOpacity(0.8),
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
          print('❌ USER CANCELLED LOGOUT');
        } else {
          print('⚠️ LOGOUT DIALOG RETURNED NULL');
        }
        } catch (e, stackTrace) {
          print('❌ LOGOUT BUTTON ERROR: $e');
          print('Stack trace: $stackTrace');
          
          // Try to show error message if context is still valid
          if (mounted) {
            try {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('An error occurred: ${e.toString()}'),
                  backgroundColor: const Color(0xFFEF4444),
                  duration: const Duration(seconds: 2),
                ),
              );
            } catch (snackbarError) {
              print('❌ Could not show error snackbar: $snackbarError');
            }
          }
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // py-2 px-3
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
      padding: EdgeInsets.only(left: 4, right: 12),
      child: ListenableBuilder(
        listenable: userState,
        builder: (context, _) {
          return Row(
            children: [
              // Menu Button
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: Colors.grey.shade700,
                    size: 24,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'Menu',
                  padding: EdgeInsets.all(8),
                  constraints: BoxConstraints(),
                ),
              ),
              
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
            return Text(
              'AdsyClub',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
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
      // Guest user - show login button
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/login'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade200),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.grey.shade600,
                size: 20,
              ),
            ),
          ),
        ],
      );
    }

    // Logged in user
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Inbox button
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InboxScreen()),
            );
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_unread_outlined,
              color: Color(0xFF3B82F6),
              size: 24,
            ),
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
                title: '${user.firstName ?? user.username ?? "User"}\'s QR',
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
    final displayName = user.firstName ?? user.displayName ?? user.username ?? 'U';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    
    // Debug: Print profile picture URL
    if (profilePic.isNotEmpty) {
      print('🖼️ User Profile Picture URL: $profilePic');
    } else {
      print('⚠️ No profile picture found for user: ${user.username}');
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isDropdownOpen = !_isDropdownOpen;
        });
      },
      child: Container(
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
                      color: Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
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
                        color: Color(0xFF6366F1).withOpacity(0.4),
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
                        color: Colors.black.withOpacity(0.1),
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

  void _handleNavigation(BuildContext context, String destination) {
    if (destination == 'eshop') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EshopScreen()),
      );
    } else if (destination == 'AdsyPay' || destination == 'Deposit/Withdraw') {
      Navigator.pushNamed(context, '/deposit-withdraw');
    } else if (destination == 'Mobile Recharge') {
      Navigator.pushNamed(context, '/mobile-recharge');
    } else if (destination == 'Business Network') {
      Navigator.pushNamed(context, '/business-network');
    } else if (destination == 'News') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NewsScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigate to $destination'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Widget _buildStickyMobileNav(BuildContext context) {
    // Mock user data - replace with actual user state management
    final bool isLoggedIn = DateTime.now().millisecondsSinceEpoch % 2 == 0;
    final Set<String> loadingButtons = <String>{};
    int unreadCount = 0;

    return Positioned(
      left: 24, // mx-6 = 24px
      right: 24,
      bottom: 8, // bottom-2 = 8px
      child: Container(
        width: MediaQuery.of(context).size.width - 48, // Full width minus margins
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9), // bg-white/90
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF34D399).withOpacity(0.1), // border-emerald-100
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8), // py-2 for better touch targets
              child: isLoggedIn 
                  ? _buildLoggedInNavigation(loadingButtons, unreadCount)
                  : _buildGuestNavigation(loadingButtons),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedInNavigation(Set<String> loadingButtons, int unreadCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMobileNavItem(
          child: Image.asset(
            'assets/images/favicon.png',
            width: 26,
            height: 26,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.home,
                size: 26,
                color: Color(0xFF34D399),
              );
            },
          ),
          onTap: () => _handleButtonClick('mobile_home', 'Home', loadingButtons),
          buttonId: 'mobile_home',
          loadingButtons: loadingButtons,
        ),
        _buildMobileNavItem(
          child: const Icon(Icons.account_balance_wallet, size: 28, color: Color(0xFF34D399)),
          onTap: () => _handleButtonClick('mobile_deposit', 'AdsyPay', loadingButtons),
          buttonId: 'mobile_deposit',
          loadingButtons: loadingButtons,
        ),
        _buildMobileNavItem(
          child: const Icon(Icons.phone_android, size: 28, color: Color(0xFF34D399)),
          onTap: () => _handleButtonClick('mobile_recharge', 'Mobile Recharge', loadingButtons),
          buttonId: 'mobile_recharge',
          loadingButtons: loadingButtons,
        ),
        _buildMobileNavItem(
          child: Stack(
            children: [
              const Icon(Icons.network_check, size: 28, color: Color(0xFF34D399)),
              if (unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onTap: () => _handleButtonClick('mobile_business', 'Business Network', loadingButtons),
          buttonId: 'mobile_business',
          loadingButtons: loadingButtons,
        ),
        _buildMobileNavItem(
          child: const Icon(Icons.newspaper, size: 28, color: Color(0xFF34D399)),
          onTap: () => _handleButtonClick('mobile_news', 'News', loadingButtons),
          buttonId: 'mobile_news',
          loadingButtons: loadingButtons,
        ),
      ],
    );
  }

  Widget _buildGuestNavigation(Set<String> loadingButtons) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMobileNavItem(
          child: Image.asset(
            'assets/images/favicon.png',
            width: 26,
            height: 26,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.home,
                size: 26,
                color: Color(0xFF34D399),
              );
            },
          ),
          onTap: () => _handleButtonClick('guest_home', 'Home', loadingButtons),
          buttonId: 'guest_home',
          loadingButtons: loadingButtons,
        ),
        _buildMobileNavItem(
          child: const Icon(Icons.work, size: 28, color: Color(0xFF34D399)),
          onTap: () => _handleButtonClick('guest_microgigs', 'Microgigs', loadingButtons),
          buttonId: 'guest_microgigs',
          loadingButtons: loadingButtons,
        ),
        _buildMobileNavItem(
          child: const Icon(Icons.shopping_bag, size: 28, color: Color(0xFF34D399)),
          onTap: () => _handleButtonClick('guest_eshop', 'eShop', loadingButtons),
          buttonId: 'guest_eshop',
          loadingButtons: loadingButtons,
        ),
        _buildMobileNavItem(
          child: const Icon(Icons.network_check, size: 28, color: Color(0xFF34D399)),
          onTap: () => _handleButtonClick('guest_business', 'Business Network', loadingButtons),
          buttonId: 'guest_business',
          loadingButtons: loadingButtons,
        ),
        _buildMobileNavItem(
          child: const Icon(Icons.newspaper, size: 28, color: Color(0xFF34D399)),
          onTap: () => _handleButtonClick('guest_news', 'News', loadingButtons),
          buttonId: 'guest_news',
          loadingButtons: loadingButtons,
        ),
      ],
    );
  }

  Widget _buildMobileNavItem({
    required Widget child,
    required VoidCallback onTap,
    required String buttonId,
    required Set<String> loadingButtons,
  }) {
    final isLoading = loadingButtons.contains(buttonId);
    
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: isLoading
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                ),
              )
            : child,
      ),
    );
  }

  void _handleButtonClick(String buttonId, String destination, Set<String> loadingButtons) {
    setState(() {
      loadingButtons.add(buttonId);
    });
    
    // Simulate navigation delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          loadingButtons.remove(buttonId);
        });
        _handleNavigation(context, destination);
      }
    });
  }
}