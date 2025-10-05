import 'package:flutter/material.dart';
import '../widgets/footer.dart';
import '../widgets/mobile_drawer.dart';
import '../widgets/mobile_banner.dart';
import '../widgets/hot_deals_section.dart';
import '../widgets/hot_arrivals_section.dart';
import '../widgets/sale_category.dart';
import '../widgets/classified_services_section.dart';
import '../widgets/eshop_section.dart'; // Add the eShop section import
import '../services/scroll_direction_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ScrollController _scrollController;
  final ScrollDirectionService _scrollService = ScrollDirectionService();
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Don't initialize the scroll service immediately - wait for the widget to be built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_disposed) {
        _scrollService.initialize(_scrollController);
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    // Dispose scroll service before disposing the controller
    _scrollService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isMobile = screenWidth < 768;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: const MobileDrawer(),
      body: Column(
        children: [
          // Fixed Header at top
          Container(
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
              child: _buildFixedHeader(context, isMobile),
            ),
          ),
          
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // 1. Mobile Banner (replaces HeroBanner)
                  const SizedBox(height: 8),
                  const MobileBannerWidget(
                    autoplayInterval: 5000,
                    autoplayEnabled: true,
                  ),
                  
                  // 2. Hot Deals Section
                  const HotDealsSection(),
                  
                  // 3. Hot Arrivals Section
                  const HotArrivalsSection(),
                  
                  // 4. Sale Category
                  const SaleCategory(),
                  
                  // 5. Classified Services Section
                  const ClassifiedServicesSection(),
                  
                  // 6. eShop section
                  const EshopSection(),
                  
                  // Footer - always show the main footer content
                  const SizedBox(height: 32),
                  AppFooter(
                    showMobileNav: isMobile, // Show mobile nav only on mobile
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Fixed Mobile Navigation Bar (outside of scrollable content)
      floatingActionButton: isMobile ? _buildStickyMobileNav(context) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildFixedHeader(BuildContext context, bool isMobile) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
      ),
      child: Row(
        children: [
          // Menu Button
          Builder(
            builder: (context) => IconButton(
              icon: Icon(
                Icons.menu,
                color: Colors.grey.shade800,
                size: isMobile ? 24 : 28,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Open Menu',
            ),
          ),
          SizedBox(width: isMobile ? 4 : 8),
          
          // Logo (extracted from header widget)
          _buildDynamicLogo(context),
          
          const Spacer(),
          
          // Desktop Navigation
          if (!isMobile) ...[
            _buildDesktopNavigation(context),
          ],
          
          // Mobile actions
          if (isMobile) ...[
            _buildMobileActions(context),
          ],
        ],
      ),
    );
  }

  // Extract logo building logic from AppHeader
  Widget _buildDynamicLogo(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 768;
    
    return GestureDetector(
      onTap: () {
        if (!_disposed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Navigate to Home'),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      child: Container(
        constraints: BoxConstraints(
          minHeight: 32,
          maxHeight: isMobile ? 32 : 40,
          minWidth: 80,
          maxWidth: 170,
        ),
        child: Container(
          height: isMobile ? 30 : 34,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 6 : 8,
            vertical: 2,
          ),
          child: Image.asset(
            'assets/images/logo.png',
            height: isMobile ? 26 : 30,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 12,
                  vertical: isMobile ? 5 : 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'AdsyClub',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopNavigation(BuildContext context) {
    final navItems = [
      {
        'title': 'Home',
        'icon': Icons.home,
        'color': const Color(0xFF3B82F6),
        'route': '/',
      },
      {
        'title': 'Business Network',
        'icon': Icons.network_check,
        'color': const Color(0xFF10B981),
        'route': '/business-network',
      },
      {
        'title': 'News',
        'icon': Icons.newspaper,
        'color': const Color(0xFFF59E0B),
        'route': '/adsy-news',
      },
      {
        'title': 'E-Learning',
        'icon': Icons.school,
        'color': const Color(0xFF8B5CF6),
        'route': '/courses',
      },
      {
        'title': 'Earn Money',
        'icon': Icons.monetization_on,
        'color': const Color(0xFFEF4444),
        'route': '/#micro-gigs',
      },
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: navItems.map((item) {
        return _buildNavItem(
          context,
          item['title'] as String,
          item['icon'] as IconData,
          item['color'] as Color,
          item['route'] as String,
        );
      }).toList(),
    );
  }

  Widget _buildNavItem(BuildContext context, String title, IconData icon, Color color, String route) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => _handleNavigation(context, title),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.mark_email_unread_outlined,
            color: const Color(0xFF3B82F6),
            size: 24,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Messages/Inbox coming soon'),
                backgroundColor: Color(0xFF3B82F6),
              ),
            );
          },
          tooltip: 'Messages/Inbox',
        ),
        IconButton(
          icon: Icon(
            Icons.qr_code_scanner,
            color: const Color(0xFF10B981),
            size: 24,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('QR Code Scanner coming soon'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          },
          tooltip: 'QR Code Scanner',
        ),
        IconButton(
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.person,
              color: Colors.grey.shade600,
              size: 18,
            ),
          ),
          onPressed: () {
            Navigator.of(context).pushNamed('/login');
          },
          tooltip: 'Login / Profile',
        ),
      ],
    );
  }

  void _handleNavigation(BuildContext context, String destination) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to $destination'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 1),
      ),
    );
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
          onTap: () => _handleButtonClick('mobile_deposit', 'Deposit/Withdraw', loadingButtons),
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