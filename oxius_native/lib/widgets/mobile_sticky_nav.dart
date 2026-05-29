import 'package:flutter/material.dart';
import '../services/user_state_service.dart';
import '../services/notification_service.dart';
import '../services/translation_service.dart';
import '../screens/eshop_manager_screen.dart';
import '../screens/home_screen.dart';
import '../screens/news_screen.dart';

class MobileStickyNav extends StatefulWidget {
  final String? currentRoute;
  final ScrollController? scrollController;

  const MobileStickyNav({
    super.key,
    this.currentRoute,
    this.scrollController,
  });

  @override
  State<MobileStickyNav> createState() => _MobileStickyNavState();
}

class _MobileStickyNavState extends State<MobileStickyNav> {
  final UserStateService _userStateService = UserStateService();
  final TranslationService _translationService = TranslationService();
  int unreadCount = 0;
  bool _isVisible = true;
  ScrollController? _scrollController;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    // Listen to user state changes
    _userStateService.addListener(_onUserStateChanged);

    // Load notification count if authenticated
    if (_userStateService.isAuthenticated) {
      _loadUnreadNotificationCount();
    }

    // Attach scroll listener
    _scrollController = widget.scrollController;
    _scrollController?.addListener(_onScroll);
  }

  @override
  void dispose() {
    _userStateService.removeListener(_onUserStateChanged);
    _scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onUserStateChanged() {
    if (mounted) {
      setState(() {});
      // Refresh notification count when user state changes
      if (_userStateService.isAuthenticated) {
        _loadUnreadNotificationCount();
      } else {
        setState(() {
          unreadCount = 0;
        });
      }
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      print('📱 Mobile Sticky Nav: Fetching notification count...');
      final result = await NotificationService.getNotifications(page: 1);
      final count = result['unreadCount'] ?? 0;
      print('📱 Mobile Sticky Nav: Got notification count: $count');

      if (mounted) {
        setState(() {
          unreadCount = count;
        });
        print('📱 Mobile Sticky Nav: Updated state with count: $unreadCount');
      }
    } catch (e) {
      print('❌ Mobile Sticky Nav: Error loading notification count: $e');
    }
  }

  void _onScroll() {
    if (_scrollController == null || !mounted) return;

    final currentScrollPosition = _scrollController!.position.pixels;
    final scrollDelta = currentScrollPosition - _lastScrollPosition;

    // Only react to significant scroll movements
    if (scrollDelta.abs() < 5) return;

    // Check if user is scrolling down or up
    if (scrollDelta > 0 && currentScrollPosition > 50) {
      // Scrolling down - hide navbar
      if (_isVisible) {
        setState(() => _isVisible = false);
      }
    } else if (scrollDelta < 0) {
      // Scrolling up - show navbar
      if (!_isVisible) {
        setState(() => _isVisible = true);
      }
    }

    _lastScrollPosition = currentScrollPosition;
  }

  @override
  Widget build(BuildContext context) {
    // Parent screens wrap this widget in SafeArea. Inside that SafeArea,
    // MediaQuery.padding.bottom becomes 0 on iOS, but viewPadding.bottom still
    // contains the real home-indicator inset. Use that value so the hide
    // animation travels past the safe-area gap instead of leaving a visible
    // slice at the bottom of the screen.
    final bottomMargin = 8.0;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final hiddenYOffset =
        1.0 + ((bottomInset + bottomMargin + 12.0) / 56.0).clamp(0.25, 1.0);

    return AnimatedSlide(
      offset: _isVisible ? Offset.zero : Offset(0, hiddenYOffset),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        margin: EdgeInsets.fromLTRB(36, 0, 36, bottomMargin),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF34D399).withOpacity(0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.height * 0.008,
              horizontal: 4,
            ),
            child: _userStateService.isAuthenticated
                ? _buildLoggedInNavigation(context)
                : _buildGuestNavigation(context),
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedInNavigation(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNavItem(
          icon: Icons.home_rounded,
          label: 'Home',
          isActive: widget.currentRoute == 'Home',
          onTap: () => _handleNavigation(context, 'Home'),
          hasNotification: false,
          useFavicon: true,
        ),
        _buildNavItem(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Wallet',
          isActive: widget.currentRoute == 'Wallet',
          onTap: () => _handleNavigation(context, 'Wallet'),
          hasNotification: false,
        ),
        _buildNavItem(
          icon: Icons.phone_android_rounded,
          label: 'Recharge',
          isActive: widget.currentRoute == 'Recharge',
          onTap: () => _handleNavigation(context, 'Mobile Recharge'),
          hasNotification: false,
        ),
        _buildNavItem(
          icon: Icons.group_rounded,
          label: 'Network',
          isActive: widget.currentRoute == 'Network',
          onTap: () => _handleNavigation(context, 'Business Network'),
          hasNotification: unreadCount > 0,
          notificationCount: unreadCount,
        ),
        _buildNavItem(
          icon: Icons.article_rounded,
          label: 'News',
          isActive: widget.currentRoute == 'News',
          onTap: () => _handleNavigation(context, 'News'),
          hasNotification: false,
        ),
      ],
    );
  }

  Widget _buildGuestNavigation(BuildContext context) {
    final eshopManagerLabel = _translationService.t(
      'eshop_manager',
      fallback: 'eShop Manager',
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNavItem(
          icon: Icons.home_rounded,
          label: 'Home',
          isActive: widget.currentRoute == 'Home',
          onTap: () => _handleNavigation(context, 'Home'),
          hasNotification: false,
          useFavicon: true,
        ),
        _buildNavItem(
          icon: Icons.work_rounded,
          label: 'Gigs',
          isActive: widget.currentRoute == 'Gigs',
          onTap: () => _handleNavigation(context, 'Microgigs'),
          hasNotification: false,
        ),
        _buildNavItem(
          icon: Icons.shopping_bag_rounded,
          label: eshopManagerLabel,
          isActive: widget.currentRoute == 'eShop Manager',
          onTap: () => _handleNavigation(context, 'eShop Manager'),
          hasNotification: false,
        ),
        _buildNavItem(
          icon: Icons.group_rounded,
          label: 'Network',
          isActive: widget.currentRoute == 'Network',
          onTap: () => _handleNavigation(context, 'Business Network'),
          hasNotification: false,
        ),
        _buildNavItem(
          icon: Icons.article_rounded,
          label: 'News',
          isActive: widget.currentRoute == 'News',
          onTap: () => _handleNavigation(context, 'News'),
          hasNotification: false,
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool hasNotification,
    required bool isActive,
    int notificationCount = 0,
    bool useFavicon = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = (screenWidth * 0.065).clamp(24.0, 28.0);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height * 0.012,
            horizontal: 4,
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (useFavicon)
                Image.asset(
                  'assets/images/favicon.png',
                  width: iconSize,
                  height: iconSize,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      icon,
                      size: iconSize,
                      color: isActive
                          ? const Color(0xFF10B981)
                          : const Color(0xFF34D399),
                    );
                  },
                )
              else
                Icon(
                  icon,
                  size: iconSize,
                  color: isActive
                      ? const Color(0xFF10B981)
                      : const Color(0xFF34D399),
                ),
              if (hasNotification && notificationCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      notificationCount > 99
                          ? '99+'
                          : notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, String destination) {
    // Prevent navigation to current page
    if ((destination == 'eShop Manager' &&
            widget.currentRoute == 'eShop Manager') ||
        (destination == 'Home' && widget.currentRoute == 'Home') ||
        (destination == 'AdsyPay' && widget.currentRoute == 'Wallet') ||
        (destination == 'Wallet' && widget.currentRoute == 'Wallet') ||
        (destination == 'Mobile Recharge' &&
            widget.currentRoute == 'Recharge') ||
        (destination == 'Business Network' &&
            widget.currentRoute == 'Network') ||
        (destination == 'MindForce' && widget.currentRoute == 'MindForce') ||
        (destination == 'News' && widget.currentRoute == 'News') ||
        (destination == 'Microgigs' && widget.currentRoute == 'Gigs')) {
      return;
    }

    if (destination == 'Home') {
      // Navigate to public homepage (/) and clear all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else if (destination == 'eShop Manager') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EshopManagerScreen()),
      );
    } else if (destination == 'AdsyPay' || destination == 'Deposit/Withdraw') {
      // Navigate to AdsyPay page using named route
      Navigator.pushNamed(context, '/deposit-withdraw');
    } else if (destination == 'Mobile Recharge') {
      // Navigate to mobile recharge route.
      // CRITICAL: route name must match the one registered in `main.dart`
      // (`/mobile-recharge`). The previous value `/mobile-recharge_screen`
      // produced a "Could not find a generator for route" exception. On
      // Flutter web that exception leaves `Navigator._debugLocked == true`,
      // which silently breaks EVERY subsequent tap → push across the whole
      // app until reload. Do NOT rename without also updating `main.dart`.
      Navigator.pushNamed(context, '/mobile-recharge');
    } else if (destination == 'Business Network') {
      Navigator.pushNamed(context, '/business-network').then((_) {
        // Refresh notification count when returning from business network
        if (mounted && _userStateService.isAuthenticated) {
          _loadUnreadNotificationCount();
        }
      });
    } else if (destination == 'MindForce') {
      Navigator.pushNamed(context, '/mindforce');
    } else if (destination == 'News') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NewsScreen()),
      );
    } else if (destination == 'Microgigs') {
      Navigator.pushNamed(context, '/my-gigs');
    } else if (destination == 'Wallet') {
      Navigator.pushNamed(context, '/deposit-withdraw');
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
}
