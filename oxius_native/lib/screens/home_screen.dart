import 'package:flutter/material.dart';
import '../widgets/footer.dart';
import '../widgets/mobile_drawer.dart';
import '../widgets/hero_banner.dart';
import '../widgets/sale_category.dart';
import '../widgets/classified_services_section.dart';
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
                  const HeroBanner(),
                  const SaleCategory(),
                  const ClassifiedServicesSection(),
                  
                  // Footer - always show the main footer content
                  const SizedBox(height: 32),
                  AppFooter(
                    showMobileNav: isMobile, // Show mobile nav only on mobile
                    isScrollingDown: _scrollService.isScrollingDown,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // No bottom navigation bar since AppFooter handles mobile navigation
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
}