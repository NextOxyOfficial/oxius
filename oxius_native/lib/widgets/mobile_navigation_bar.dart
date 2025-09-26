import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/scroll_direction_service.dart';
import '../services/auth_service.dart';

class MobileNavigationBar extends StatefulWidget {
  final ScrollDirectionService? scrollService;
  
  const MobileNavigationBar({
    super.key,
    this.scrollService,
  });

  @override
  State<MobileNavigationBar> createState() => _MobileNavigationBarState();
}

class _MobileNavigationBarState extends State<MobileNavigationBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late ScrollDirectionService _scrollService;
  final Set<String> _loadingButtons = <String>{};

  @override
  void initState() {
    super.initState();
    
    // Use provided scroll service or create a new one
    _scrollService = widget.scrollService ?? ScrollDirectionService();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 2), // Slide down by 2x height
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scrollService.addListener(_onScrollDirectionChanged);
  }

  @override
  void dispose() {
    _scrollService.removeListener(_onScrollDirectionChanged);
    // Only dispose if we created the scroll service
    if (widget.scrollService == null) {
      _scrollService.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onScrollDirectionChanged() {
    if (_scrollService.isVisible) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 640;
    
    if (!isMobile) return const SizedBox.shrink();

    return Positioned(
      left: 24,
      right: 24,
      bottom: 8,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.1),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
              ),
              child: AuthService.isAuthenticated 
                  ? _buildLoggedInNavigation(context)
                  : _buildGuestNavigation(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedInNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            context,
            'mobile_home',
            _buildLogoIcon(),
            '/',
            'Home',
          ),
          _buildNavItem(
            context,
            'mobile_deposit',
            const Icon(Icons.account_balance_wallet, size: 24),
            '/deposit-withdraw',
            'Wallet',
          ),
          _buildNavItem(
            context,
            'mobile_recharge',
            const Icon(Icons.phone_android, size: 24),
            '/mobile-recharge',
            'Recharge',
          ),
          _buildNavItem(
            context,
            'mobile_business',
            _buildBusinessIcon(),
            '/business-network',
            'Network',
            hasNotification: true,
            notificationCount: 5, // This would come from a service
          ),
          _buildNavItem(
            context,
            'mobile_news',
            const Icon(Icons.newspaper, size: 24),
            '/adsy-news',
            'News',
          ),
        ],
      ),
    );
  }

  Widget _buildGuestNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            context,
            'guest_home',
            _buildLogoIcon(),
            '/',
            'Home',
          ),
          _buildNavItem(
            context,
            'guest_microgigs',
            const Icon(Icons.work_outline, size: 24),
            '/#microgigs',
            'Earn',
          ),
          _buildNavItem(
            context,
            'guest_eshop',
            const Icon(Icons.shopping_bag_outlined, size: 24),
            '/eshop',
            'Shop',
          ),
          _buildNavItem(
            context,
            'guest_business',
            const Icon(Icons.network_cell, size: 24),
            '/business-network',
            'Network',
          ),
          _buildNavItem(
            context,
            'guest_news',
            const Icon(Icons.newspaper_outlined, size: 24),
            '/adsy-news',
            'News',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String buttonId,
    Widget icon,
    String route,
    String label, {
    bool hasNotification = false,
    int notificationCount = 0,
  }) {
    final isLoading = _loadingButtons.contains(buttonId);
    
    return Expanded(
      child: InkWell(
        onTap: () => _handleNavigation(context, buttonId, route, label),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with loading state and notification badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    child: isLoading
                        ? _buildLoadingSpinner()
                        : Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconTheme(
                              data: const IconThemeData(
                                color: Color(0xFF16A34A),
                                size: 20,
                              ),
                              child: icon,
                            ),
                          ),
                  ),
                  
                  // Notification badge
                  if (hasNotification && notificationCount > 0 && !isLoading)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.red.shade500,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Center(
                          child: Text(
                            notificationCount > 99 ? '99+' : notificationCount.toString(),
                            style: GoogleFonts.roboto(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Label
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoIcon() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF10B981), // emerald-500
            Color(0xFF059669), // emerald-600
          ],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          'A',
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessIcon() {
    return Stack(
      children: [
        const Icon(Icons.network_cell, size: 24),
      ],
    );
  }

  Widget _buildLoadingSpinner() {
    return Container(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          const Color(0xFF16A34A),
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, String buttonId, String route, String label) {
    setState(() {
      _loadingButtons.add(buttonId);
    });

    // Simulate navigation delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _loadingButtons.remove(buttonId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigate to $label'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });
  }
}