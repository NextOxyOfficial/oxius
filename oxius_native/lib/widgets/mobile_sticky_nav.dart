import 'package:flutter/material.dart';
import '../services/user_state_service.dart';
import '../screens/eshop_screen.dart';

class MobileStickyNav extends StatefulWidget {
  final String? currentRoute;
  
  const MobileStickyNav({
    super.key,
    this.currentRoute,
  });

  @override
  State<MobileStickyNav> createState() => _MobileStickyNavState();
}

class _MobileStickyNavState extends State<MobileStickyNav> {
  final UserStateService _userStateService = UserStateService();
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    // Listen to user state changes
    _userStateService.addListener(_onUserStateChanged);
  }

  @override
  void dispose() {
    _userStateService.removeListener(_onUserStateChanged);
    super.dispose();
  }

  void _onUserStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        (destination == 'Home' && widget.currentRoute == 'Home')) {
      return;
    }

    if (destination == 'eShop') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EshopScreen()),
      );
    } else if (destination == 'Home') {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else if (destination == 'Wallet') {
      Navigator.pushNamed(context, '/wallet');
    } else if (destination == 'Mobile Recharge') {
      Navigator.pushNamed(context, '/mobile-recharge');
    } else if (destination == 'Business Network') {
      Navigator.pushNamed(context, '/business-network');
    } else if (destination == 'News') {
      Navigator.pushNamed(context, '/news');
    } else if (destination == 'Microgigs') {
      Navigator.pushNamed(context, '/microgigs');
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
