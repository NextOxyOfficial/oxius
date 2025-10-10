import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../services/user_state_service.dart';
import '../screens/eshop_screen.dart';
import '../screens/home_screen.dart';

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
      duration: const Duration(milliseconds: 800), // Much slower animation
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
      duration: const Duration(milliseconds: 800),
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
          icon: Icons.home,
          label: 'Home',
          isActive: widget.currentRoute == 'Home',
          onTap: () => _handleNavigation(context, 'Home'),
          hasNotification: false,
          useFavicon: true,
        ),
        _buildNavItem(
          icon: Icons.account_balance_wallet,
          label: 'Wallet',
          isActive: widget.currentRoute == 'Wallet',
          onTap: () => _handleNavigation(context, 'Wallet'),
          hasNotification: false,
        ),
        _buildNavItem(
          icon: Icons.phone_android,
          label: 'Recharge',
          isActive: widget.currentRoute == 'Recharge',
          onTap: () => _handleNavigation(context, 'Mobile Recharge'),
          hasNotification: false,
        ),
        _buildNavItem(
          icon: Icons.network_check,
          label: 'Network',
          isActive: widget.currentRoute == 'Network',
          onTap: () => _handleNavigation(context, 'Business Network'),
          hasNotification: unreadCount > 0,
          notificationCount: unreadCount,
        ),
        _buildNavItem(
          icon: Icons.newspaper,
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
          icon: Icons.home,
          label: 'Home',
          isActive: widget.currentRoute == 'Home',
          onTap: () => _handleNavigation(context, 'Home'),
          hasNotification: false,
          useFavicon: true,
        ),
        _buildNavItem(
          icon: Icons.work,
          label: 'Gigs',
          isActive: widget.currentRoute == 'Gigs',
          onTap: () => _handleNavigation(context, 'Microgigs'),
          hasNotification: false,
        ),
        _buildNavItem(
          icon: Icons.shopping_bag,
          label: 'eShop',
          isActive: widget.currentRoute == 'eShop',
          onTap: () => _handleNavigation(context, 'eShop'),
          hasNotification: false,
        ),
        _buildNavItem(
          icon: Icons.network_check,
          label: 'Network',
          isActive: widget.currentRoute == 'Network',
          onTap: () => _handleNavigation(context, 'Business Network'),
          hasNotification: false,
        ),
        _buildNavItem(
          icon: Icons.newspaper,
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
    if ((destination == 'eShop' && widget.currentRoute == 'eShop') ||
        (destination == 'Home' && widget.currentRoute == 'Home') ||
        (destination == 'Deposit/Withdraw' && widget.currentRoute == 'Wallet') ||
        (destination == 'Mobile Recharge' && widget.currentRoute == 'Recharge') ||
        (destination == 'Business Network' && widget.currentRoute == 'Network') ||
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
    } else if (destination == 'eShop') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EshopScreen()),
      );
    } else if (destination == 'Deposit/Withdraw') {
      // Navigate to deposit/withdraw page using named route
      Navigator.pushNamed(context, '/deposit-withdraw');
    } else if (destination == 'Mobile Recharge') {
      // Navigate to mobile recharge route
      Navigator.pushNamed(context, '/mobile-recharge');
    } else if (destination == 'Business Network') {
      // Show coming soon for now
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business Network - Coming Soon!'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 1),
        ),
      );
    } else if (destination == 'News') {
      // Show coming soon for now
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('News - Coming Soon!'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 1),
        ),
      );
    } else if (destination == 'Microgigs') {
      // Show coming soon for now
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microgigs - Coming Soon!'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 1),
        ),
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
}
