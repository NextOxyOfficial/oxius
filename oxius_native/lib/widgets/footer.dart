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
        color: const Color(0xFFF9FAFB), // gray-50
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 4, // 4px side padding
          vertical: isMobile ? 16 : 20,
        ),
        child: Column(
          children: [
            // Logo and description
            _buildLogoSection(context, isMobile),
            
            const SizedBox(height: 16),
            
            // Navigation links
            _buildNavigationSection(context, isMobile),
            
            const SizedBox(height: 16),
            
            // Payment section
            _buildAppPaymentSection(context, isMobile),
            
            const SizedBox(height: 12),
            
            // Divider
            Container(
              height: 1,
              color: Colors.grey.shade200,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            
            const SizedBox(height: 12),
            
            // Terms and privacy
            _buildTermsSection(context),
            
            const SizedBox(height: 8),
            
            // Copyright
            _buildCopyrightSection(context, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context, bool isMobile) {
    return Column(
      children: [
        // Dynamic Logo
        _buildDynamicLogo(context, isMobile),
        const SizedBox(height: 12),
        
        // Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Earn Money, Connect with Society & Find the Services You Need!',
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationSection(BuildContext context, bool isMobile) {
    final navLinks = [
      {'title': t('classified_service'), 'route': '/'},
      {'title': t('earn_money'), 'route': '/micro-gigs'},
      {'title': t('mobile_recharge'), 'route': '/mobile-recharge'},
      {'title': t('packeges'), 'route': '/upgrade-to-pro'},
      {'title': t('refer_program'), 'route': '/refer-a-friend'},
      {'title': t('about_us'), 'route': '/about'},
      {'title': t('faq'), 'route': '/faq'},
      {'title': t('contact_us'), 'route': '/contact-us'},
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: isMobile ? 12 : 20,
      runSpacing: 6,
      children: navLinks.map((link) => InkWell(
        onTap: () => _handleNavigation(context, link['title']!),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Text(
            link['title']!,
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      )).toList(),
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

  Widget _buildAppDownloadSection(BuildContext context, bool isMobile) {
    // If loading, show skeleton
    if (isLoadingBanners) {
      return Column(
        children: [
          if (!isMobile)
            Text(
              t('download_app'),
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          if (!isMobile) const SizedBox(height: 16),
          Row(
            mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Container(
                width: 117,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 119,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // If we have banners, show them
    if (footerBanners.isNotEmpty) {
      return Column(
        children: [
          if (!isMobile)
            Text(
              t('download_app'),
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          if (!isMobile) const SizedBox(height: 16),
          Row(
            mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: footerBanners.take(2).map((banner) {
              final imageUrl = _abs(banner['image']);
              final link = banner['link'];
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    if (link != null && link.isNotEmpty) {
                      _handleNavigation(context, link);
                    }
                  },
                  child: Container(
                    width: 117,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    // Fallback to static images if no banners
    return Column(
      children: [
        if (!isMobile)
          Text(
            t('download_app'),
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        if (!isMobile) const SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            // App Store
            GestureDetector(
              onTap: () => _showComingSoon(context, 'App Store'),
              child: Container(
                width: 117,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/apple.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.black,
                        child: const Center(
                          child: Text(
                            'App Store',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Google Play
            GestureDetector(
              onTap: () => _downloadAndroidApp(context),
              child: Container(
                width: 119,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/google.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.black,
                        child: const Center(
                          child: Text(
                            'Google Play',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentSection(BuildContext context, bool isMobile) {
    return Column(
      children: [
        Text(
          t('we_accept'),
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        
        Container(
          constraints: const BoxConstraints(maxWidth: 370),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/payment.png',
              fit: BoxFit.contain,
              height: 70,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPaymentBadge('VISA', const Color(0xFF1A1F71)),
                      _buildPaymentBadge('MC', Colors.orange),
                      _buildPaymentBadge('PayPal', const Color(0xFF0070BA)),
                      _buildMobileBankingBadge(),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMobileBankingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.phone_android,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 2),
          Text(
            'Mobile',
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: () => _handleNavigation(context, t('terms_conditions')),
          child: Text(
            t('terms_conditions'),
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '|',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ),
        
        InkWell(
          onTap: () => _handleNavigation(context, t('privacy_policy')),
          child: Text(
            t('privacy_policy'),
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicLogo(BuildContext context, bool isMobile) {
    return GestureDetector(
      onTap: () => _handleNavigation(context, 'Home'),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: 32,
          maxWidth: 110,
        ),
        child: isLoading
            ? Container(
                height: 32,
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey.shade500,
                      ),
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
                      height: 32,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildFallbackLogo(context, isMobile);
                      },
                    ),
                  )
                : _buildFallbackLogo(context, isMobile),
      ),
    );
  }

  Widget _buildFallbackLogo(BuildContext context, bool isMobile) {
    return Image.asset(
      'assets/images/logo.png',
      height: 32,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Only show text as final fallback if logo image fails to load
        return Text(
          logoData?['text'] ?? 'AdsyClub',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        );
      },
    );
  }

  Widget _buildCopyrightSection(BuildContext context, bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isMobile ? 72 : 8, // Extra bottom padding for mobile nav
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.roboto(
            fontSize: 11,
            color: Colors.grey.shade500,
            height: 1.4,
          ),
          children: [
            const TextSpan(text: 'Developed With '),
            WidgetSpan(
              child: Icon(
                Icons.favorite,
                color: Colors.red.shade400,
                size: 12,
              ),
            ),
            TextSpan(
              text: ' By Lyricz Softwares & Technology Limited \u00A9 ${DateTime.now().year}',
            ),
          ],
        ),
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
      case 'classified service':
        Navigator.pushReplacementNamed(
          context,
          '/',
          arguments: const {'scrollTo': 'classified'},
        );
        return;
      case 'earn money':
        route = '/micro-gigs';
        break;
      case 'microgigs':
        route = '/micro-gigs';
        break;
      case 'packages':
      case 'packeges':
        route = '/upgrade-to-pro';
        break;
      case 'refer program':
        route = '/refer-a-friend';
        break;
      case 'about us':
        route = '/about';
        break;
      case 'faq':
        route = '/faq';
        break;
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
    if (route != null) {
      Navigator.pushNamed(context, route);
    }
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