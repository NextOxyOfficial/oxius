import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../services/user_state_service.dart';
import '../screens/eshop_screen.dart';
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

class _MobileStickyNavState extends State<MobileStickyNav> with SingleTickerProviderStateMixin {
  final UserStateService _userStateService = UserStateService();
  int unreadCount = 0;
  bool _isVisible = true;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;
  ScrollController? _scrollController;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    // Listen to user state changes
    _userStateService.addListener(_onUserStateChanged);
    
    // Initialize animation controller with slower duration
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600), // Much slower animation
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 2), // Slide down by 2x height
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Add opacity animation to fade out completely when hidden
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Attach scroll listener
    _scrollController = widget.scrollController;
    _scrollController?.addListener(_onScroll);
  }

  @override
  void dispose() {
    _userStateService.removeListener(_onUserStateChanged);
    _scrollController?.removeListener(_onScroll);
    _animationController.dispose();
    super.dispose();
  }

  void _onUserStateChanged() {
    if (mounted) {
      setState(() {});
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
        setState(() {
          _isVisible = false;
        });
        _animationController.forward();
      }
    } else if (scrollDelta < 0) {
      // Scrolling up - show navbar
      if (!_isVisible) {
        setState(() {
          _isVisible = true;
        });
        _animationController.reverse();
      }
    }
    
    _lastScrollPosition = currentScrollPosition;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      transform: Matrix4.translationValues(
        0, 
        _isVisible ? 0 : 100, // Slide down by 100px when hidden
        0
      ),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF34D399).withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: Colors.white.withOpacity(0.9),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SafeArea(
              bottom: false, // Disable bottom padding to prevent extra white space
              child: _userStateService.isAuthenticated
                  ? _buildLoggedInNavigation(context)
                  : _buildGuestNavigation(context),
            ),
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
          label: 'eShop Manager',
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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            if (useFavicon)
              Image.asset(
                'assets/images/favicon.png',
                width: 28,
                height: 28,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    icon,
                    size: 28,
                    color: const Color(0xFF34D399),
                  );
                },
              )
            else
              Icon(
                icon,
                size: 28,
                color: const Color(0xFF34D399),
              ),
            if (hasNotification && notificationCount > 0)
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
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    notificationCount > 99 ? '99+' : notificationCount.toString(),
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
      ),
    );
  }

  void _handleNavigation(BuildContext context, String destination) {
    // Prevent navigation to current page
    if ((destination == 'eShop Manager' && widget.currentRoute == 'eShop Manager') ||
        (destination == 'Home' && widget.currentRoute == 'Home') ||
        (destination == 'AdsyPay' && widget.currentRoute == 'Wallet') ||
        (destination == 'Wallet' && widget.currentRoute == 'Wallet') ||
        (destination == 'Mobile Recharge' && widget.currentRoute == 'Recharge') ||
        (destination == 'Business Network' && widget.currentRoute == 'Network') ||
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
      // Navigate to mobile recharge route
      Navigator.pushNamed(context, '/mobile-recharge_screen');
    } else if (destination == 'Business Network') {
      Navigator.pushNamed(context, '/business-network');
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
