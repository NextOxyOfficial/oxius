import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../screens/eshop_screen.dart';
import '../config/app_config.dart';
import '../utils/url_launcher_utils.dart';

class AppFooter extends StatefulWidget {
  final bool showMobileNav;
  
  const AppFooter({
    super.key,
    this.showMobileNav = true,
  });

  @override
  State<AppFooter> createState() => _AppFooterState();
}

class _AppFooterState extends State<AppFooter> with AutomaticKeepAliveClientMixin {
  Map<String, dynamic>? logoData;
  List<dynamic> footerBanners = [];
  bool isLoading = true;
  bool isLoadingBanners = true;
  bool _disposed = false;
  ScrollController? _scrollController;
  bool isScrollingDown = false;
  int unreadCount = 0;

  // Keep the widget alive to prevent disposal issues
  @override
  bool get wantKeepAlive => true;

  String _abs(String? url) {
    return AppConfig.getAbsoluteUrl(url);
  }

  // Translation helper (matching Vue.js translations)
  String t(String key) {
    final translations = {
      'classified_service': 'Classified Service',
      'earn_money': 'Earn Money',
      'mobile_recharge': 'Mobile Recharge',
      'packeges': 'Packages',
      'refer_program': 'Refer Program',
      'about_us': 'About Us',
      'faq': 'FAQ',
      'contact_us': 'Contact Us',
      'download_app': 'Download App',
      'we_accept': 'We Accept',
      'terms_conditions': 'Terms & Conditions',
      'privacy_policy': 'Privacy Policy',
      'coming_soon': 'Coming Soon',
    };
    return translations[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) {
        _loadLogo();
        _loadFooterBanners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _scrollController?.dispose();
    super.dispose();
  }

  // Load footer banners from API
  Future<void> _loadFooterBanners() async {
    if (_disposed) return;
    
    try {
      final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/banner-images/'));
      
      if (_disposed) return;
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> banners = data is List ? data : (data['results'] ?? []);
        
        if (!_disposed && mounted) {
          setState(() {
            footerBanners = banners;
            isLoadingBanners = false;
          });
        }
      } else {
        if (!_disposed && mounted) {
          setState(() {
            isLoadingBanners = false;
          });
        }
      }
    } catch (e) {
      print('Error loading footer banners: $e');
      if (!_disposed && mounted) {
        setState(() {
          isLoadingBanners = false;
        });
      }
    }
  }

  // Load logo dynamically from API (matching Vue.js PublicLogo component)
  Future<void> _loadLogo() async {
    if (_disposed) return;
    
    try {
      final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/logo/'));
      
      if (_disposed) return;
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Normalize possible relative image URLs to absolute
        if (data is Map && data['image'] != null) {
          data['image'] = _abs(data['image']);
        }
        if (!_disposed && mounted) {
          setState(() {
            logoData = data;
            isLoading = false;
          });
        }
      } else {
        if (!_disposed && mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading logo: $e');
      if (!_disposed && mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return _buildMainFooter(context, isMobile);
  }

  Widget _buildMainFooter(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
        ),
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        child: Column(
          children: [
            // Logo and tagline
            _buildLogoSection(context, isMobile),
            const SizedBox(height: 12),
            // Quick links
            _buildNavigationSection(context, isMobile),
            const SizedBox(height: 12),
            // Payment methods
            _buildAppPaymentSection(context, isMobile),
            const SizedBox(height: 10),
            // Divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.grey.shade300, Colors.transparent],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Bottom row: Terms + Copyright
            _buildBottomRow(context, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context, bool isMobile) {
    return Column(
      children: [
        _buildDynamicLogo(context, isMobile),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Earn Money • Connect • Find Services',
            style: GoogleFonts.roboto(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationSection(BuildContext context, bool isMobile) {
    final navLinks = [
      {'title': 'Services', 'route': '/'},
      {'title': 'Earn', 'route': '/micro-gigs'},
      {'title': 'Recharge', 'route': '/mobile-recharge'},
      {'title': 'Pro', 'route': '/upgrade-to-pro'},
      {'title': 'Refer', 'route': '/refer-a-friend'},
      {'title': 'About', 'route': '/about'},
      {'title': 'FAQ', 'route': '/faq'},
      {'title': 'Contact', 'route': '/contact-us'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: navLinks.map((link) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handleNavigation(context, link['title']!),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade200, width: 0.5),
                ),
                child: Text(
                  link['title']!,
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    color: const Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAppPaymentSection(BuildContext context, bool isMobile) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: Center(
        child: _buildPaymentSection(context, isMobile),
      ),
    );
  }

  Widget _buildPaymentSection(BuildContext context, bool isMobile) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_rounded, size: 12, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text(
              'Secure Payments',
              style: GoogleFonts.roboto(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxWidth: 280),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/payment.png',
              fit: BoxFit.contain,
              height: 45,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPaymentBadge('VISA', const Color(0xFF1A1F71)),
                      const SizedBox(width: 6),
                      _buildPaymentBadge('MC', Colors.orange),
                      const SizedBox(width: 6),
                      _buildPaymentBadge('bKash', const Color(0xFFE2136E)),
                      const SizedBox(width: 6),
                      _buildPaymentBadge('Nagad', const Color(0xFFF6921E)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTermsSection(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _handleNavigation(context, t('terms_conditions')),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              'Terms',
              style: GoogleFonts.roboto(
                fontSize: 9,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        Text('•', style: TextStyle(fontSize: 8, color: Colors.grey.shade400)),
        InkWell(
          onTap: () => _handleNavigation(context, t('privacy_policy')),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              'Privacy',
              style: GoogleFonts.roboto(
                fontSize: 9,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow(BuildContext context, bool isMobile) {
    return Column(
      children: [
        _buildTermsSection(context),
        const SizedBox(height: 6),
        _buildCopyrightSection(context, isMobile),
      ],
    );
  }

  Widget _buildDynamicLogo(BuildContext context, bool isMobile) {
    return GestureDetector(
      onTap: () => _handleNavigation(context, 'Home'),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 40, maxWidth: 120),
        child: isLoading
            ? Container(
                height: 40,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
                    ),
                  ),
                ),
              )
            : logoData != null && logoData!['image'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      logoData!['image'],
                      fit: BoxFit.contain,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) => _buildFallbackLogo(context, isMobile),
                    ),
                  )
                : _buildFallbackLogo(context, isMobile),
      ),
    );
  }

  Widget _buildFallbackLogo(BuildContext context, bool isMobile) {
    return Image.asset(
      'assets/images/logo.png',
      height: 40,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            logoData?['text'] ?? 'AdsyClub',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCopyrightSection(BuildContext context, bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 70 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          
          Text(
            'Developed with ❤️ by Lyricz Softwares & Technology Limited © ${DateTime.now().year}',
            style: GoogleFonts.roboto(
              fontSize: 9,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNavigationBar(BuildContext context) {
    // Mock user data - replace with actual user state management
    final bool isLoggedIn = true; // Replace with actual user state
    
    return Positioned(
      left: 24,
      right: 24,
      bottom: 8,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        transform: Matrix4.translationValues(
          0, 
          isScrollingDown ? 80 : 0, 
          0
        ),
        child: Container(
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
              child: isLoggedIn 
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
          onTap: () => _handleNavigation(context, 'Home'),
          hasNotification: false,
        ),
        _buildNavItem(
          icon: Icons.account_balance_wallet,
          onTap: () => _handleNavigation(context, 'AdsyPay'),
          hasNotification: false,
        ),
        _buildNavItem(
          icon: Icons.phone_android,
          onTap: () => _handleNavigation(context, 'Mobile Recharge'),
          hasNotification: false,
        ),
        _buildNavItem(
          icon: Icons.network_check,
          onTap: () => _handleNavigation(context, 'Business Network'),
          hasNotification: unreadCount > 0,
          notificationCount: unreadCount,
        ),
        _buildNavItem(
          icon: Icons.newspaper,
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
          onTap: () => _handleNavigation(context, 'Home'),
          hasNotification: false,
        ),
        _buildNavItem(
          icon: Icons.work,
          onTap: () => _handleNavigation(context, 'Microgigs'),
          hasNotification: false,
        ),
        _buildNavItem(
          icon: Icons.shopping_bag,
          onTap: () => _handleNavigation(context, 'eShop'),
          hasNotification: false,
        ),
        _buildNavItem(
          icon: Icons.network_check,
          onTap: () => _handleNavigation(context, 'Business Network'),
          hasNotification: false,
        ),
        _buildNavItem(
          icon: Icons.newspaper,
          onTap: () => _handleNavigation(context, 'News'),
          hasNotification: false,
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required VoidCallback onTap,
    required bool hasNotification,
    int notificationCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
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

  // Helper methods
  void _handleNavigation(BuildContext context, String destination) {
    if (destination.startsWith('http://') || destination.startsWith('https://')) {
      UrlLauncherUtils.launchExternalUrl(destination);
      return;
    }

    if (destination == '/#classified-services') {
      Navigator.pushReplacementNamed(
        context,
        '/',
        arguments: const {'scrollTo': 'classified'},
      );
      return;
    }

    if (destination == '/#micro-gigs') {
      Navigator.pushNamed(context, '/micro-gigs');
      return;
    }

    // Map destinations to routes
    String? route;
    
    switch (destination.toLowerCase()) {
      case 'home':
        route = '/';
        break;
      case 'eshop':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EshopScreen()),
        );
        return;
      case 'terms & conditions':
      case 'terms_conditions':
        route = '/terms-and-conditions';
        break;
      case 'privacy policy':
      case 'privacy_policy':
        route = '/privacy-policy';
        break;
      case 'mobile recharge':
        route = '/mobile-recharge';
        break;
      case 'services':
      case 'classified service':
        Navigator.pushReplacementNamed(
          context,
          '/',
          arguments: const {'scrollTo': 'classified'},
        );
        return;
      case 'earn':
      case 'earn money':
        route = '/micro-gigs';
        break;
      case 'microgigs':
        route = '/micro-gigs';
        break;
      case 'recharge':
        route = '/mobile-recharge';
        break;
      case 'pro':
      case 'packages':
      case 'packeges':
        route = '/upgrade-to-pro';
        break;
      case 'refer':
      case 'refer program':
        route = '/refer-a-friend';
        break;
      case 'about':
      case 'about us':
        route = '/about';
        break;
      case 'contact':
      case 'contact us':
        route = '/contact-us';
        break;
      case 'business network':
        route = '/business-network';
        break;
      case 'news':
        route = '/adsy-news';
        break;
      case 'adsypay':
      case 'adsy pay':
        route = '/deposit-withdraw';
        break;
      default:
        // For any unhandled routes, show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigate to $destination'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 1),
          ),
        );
        return;
    }
    
    // Navigate using named route
    Navigator.pushNamed(context, route);
    }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - ${t('coming_soon')}'),
        backgroundColor: const Color(0xFF3B82F6),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _downloadAndroidApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download Started - AdsyClub Android app is downloading...'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );
  }
}