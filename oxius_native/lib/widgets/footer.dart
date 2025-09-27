import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AppFooter extends StatefulWidget {
  final bool showMobileNav;
  
  const AppFooter({
    super.key,
    this.showMobileNav = true,
  });

  @override
  State<AppFooter> createState() => _AppFooterState();
}

class _AppFooterState extends State<AppFooter> {
  Map<String, dynamic>? logoData;
  bool isLoading = true;
  bool _disposed = false;
  bool isScrollingDown = false;
  int unreadCount = 0;

  String _abs(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    // Derive origin from the logo API endpoint
    const origin = 'http://localhost:8000';
    final u = url.startsWith('/') ? url : '/$url';
    return '$origin$u';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_disposed) {
        _loadLogo();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Load logo dynamically from API (matching Vue.js PublicLogo component)
  Future<void> _loadLogo() async {
    if (_disposed) return;
    
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/api/logo/'));
      
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Stack(
      children: [
        // Main Footer
        _buildMainFooter(context, isMobile),
        
        // Mobile Navigation Bar
        if (widget.showMobileNav && isMobile)
          _buildMobileNavigationBar(context),
      ],
    );
  }

  Widget _buildMainFooter(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withOpacity(0.7), // slate-100/70
      ),
      child: Stack(
        children: [
          // Background Pattern
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/pattern.png'), // You'll need to add this
                  repeat: ImageRepeat.repeat,
                  opacity: 0.1,
                ),
              ),
            ),
          ),
          
          // Subtle gradient accents
          Positioned(
            top: -96,
            right: -96,
            child: Container(
              width: 288,
              height: 288,
              decoration: BoxDecoration(
                color: const Color(0xFF34D399).withOpacity(0.05), // emerald-400
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF34D399).withOpacity(0.05),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          
          Positioned(
            bottom: -96,
            left: -96,
            child: Container(
              width: 288,
              height: 288,
              decoration: BoxDecoration(
                color: const Color(0xFF60A5FA).withOpacity(0.05), // blue-400
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF60A5FA).withOpacity(0.05),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          
          // Footer Content
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                margin: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 48),
                child: Column(
                  children: [
                    // Top divider
                    Container(
                      width: 240,
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.grey.shade300,
                            Colors.transparent,
                          ],
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 24),
                    ),
                    
                    // Logo and description
                    _buildLogoSection(context, isMobile),
                    
                    const SizedBox(height: 32),
                    
                    // Navigation links
                    _buildNavigationSection(context, isMobile),
                    
                    const SizedBox(height: 32),
                    
                    // App download and payment section
                    _buildAppPaymentSection(context, isMobile),
                    
                    const SizedBox(height: 24),
                    
                    // Terms and privacy
                    _buildTermsSection(context),
                    
                    const SizedBox(height: 16),
                    
                    // Final divider
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.grey.shade300.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    
                    // Copyright
                    _buildCopyrightSection(context, isMobile),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context, bool isMobile) {
    return Column(
      children: [
        // Dynamic Logo
        _buildDynamicLogo(context, isMobile),
        const SizedBox(height: 24),
        
        // Description
        Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            'AdsyClub – Social Business Network: Earn Money, Connect with Society & Find the Services You Need!',
            style: GoogleFonts.roboto(
              fontSize: isMobile ? 14 : 16,
              color: Colors.grey.shade600,
              height: 1.5,
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
      {'title': t('earn_money'), 'route': '/'},
      {'title': t('mobile_recharge'), 'route': '/mobile-recharge'},
      {'title': t('packeges'), 'route': '/upgrade-to-pro'},
      {'title': t('refer_program'), 'route': '/refer-a-friend'},
      {'title': t('about_us'), 'route': '/about'},
      {'title': t('faq'), 'route': '/faq'},
      {'title': t('contact_us'), 'route': '/contact-us'},
    ];

    if (isMobile) {
      // Vertical navigation for mobile
      return Column(
        children: navLinks.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _handleNavigation(context, link['title']!),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text(
                link['title']!,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        )).toList(),
      );
    } else {
      // Horizontal navigation for desktop
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 32,
        runSpacing: 16,
        children: navLinks.map((link) => InkWell(
          onTap: () => _handleNavigation(context, link['title']!),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Text(
              link['title']!,
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        )).toList(),
      );
    }
  }

  Widget _buildAppPaymentSection(BuildContext context, bool isMobile) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: isMobile
          ? Column(
              children: [
                _buildAppDownloadSection(context, true),
                const SizedBox(height: 32),
                _buildPaymentSection(context, true),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildAppDownloadSection(context, false)),
                const SizedBox(width: 48),
                Expanded(child: _buildPaymentSection(context, false)),
              ],
            ),
    );
  }

  Widget _buildAppDownloadSection(BuildContext context, bool isMobile) {
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
        if (!isMobile)
          Text(
            t('we_accept'),
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        if (!isMobile) const SizedBox(height: 16),
        
        Container(
          constraints: const BoxConstraints(maxWidth: 370),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/payment.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
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
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          width: 1,
          height: 16,
          color: Colors.grey.shade400,
        ),
        
        InkWell(
          onTap: () => _handleNavigation(context, t('privacy_policy')),
          child: Text(
            t('privacy_policy'),
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.normal,
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
          maxHeight: isMobile ? 40 : 48,
          maxWidth: isMobile ? 120 : 150,
        ),
        child: isLoading
            ? Container(
                height: isMobile ? 32 : 40,
                width: isMobile ? 100 : 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              )
            : logoData != null && logoData!['image'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      logoData!['image'],
                      fit: BoxFit.contain,
                      height: isMobile ? 32 : 40,
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
      height: isMobile ? 32 : 40,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Only show text as final fallback if logo image fails to load
        return Text(
          logoData?['text'] ?? 'AdsyClub',
          style: GoogleFonts.roboto(
            fontSize: isMobile ? 16 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        );
      },
    );
  }

  Widget _buildCopyrightSection(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        bottom: isMobile ? 80 : 24, // Extra bottom padding for mobile nav
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          children: [
            const TextSpan(text: 'Developed With '),
            WidgetSpan(
              child: Icon(
                Icons.favorite,
                color: Colors.red.shade500,
                size: 16,
              ),
            ),
            TextSpan(
              text: ' By Lyricz Softwares & Technology Limited © ${DateTime.now().year}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavigationBar(BuildContext context) {
    // Mock user data - replace with actual user state management
    final bool isLoggedIn = DateTime.now().millisecondsSinceEpoch % 2 == 0; // Dynamic condition
    
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
            child: isLoggedIn 
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
          onTap: () => _handleNavigation(context, 'Home'),
          hasNotification: false,
        ),
        _buildNavItem(
          icon: Icons.account_balance_wallet,
          onTap: () => _handleNavigation(context, 'Deposit/Withdraw'),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to $destination'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 1),
      ),
    );
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