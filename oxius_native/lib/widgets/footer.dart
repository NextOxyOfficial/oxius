import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AppFooter extends StatefulWidget {
  final bool showMobileNav;
  final bool isScrollingDown;
  
  const AppFooter({
    super.key,
    this.showMobileNav = true,
    this.isScrollingDown = false,
  });

  @override
  State<AppFooter> createState() => _AppFooterState();
}

class _AppFooterState extends State<AppFooter> {
  Map<String, dynamic>? logoData;
  bool isLoading = true;
  bool _disposed = false;
  int unreadCount = 0;
  final Set<String> _loadingButtons = <String>{};
  
  // Mock user data - replace with actual user state management
  bool get isLoggedIn => DateTime.now().millisecondsSinceEpoch % 2 == 0;

  String _abs(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
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

  Future<void> _loadLogo() async {
    if (_disposed) return;
    
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/api/logo/'));
      
      if (_disposed) return;
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
    return Container(
      // Main Footer only - mobile nav will be handled separately in home screen
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withOpacity(0.7), // bg-slate-100/70
      ),
      child: Stack(
        children: [
          // Modern Subtle Background Pattern
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: CustomPaint(
                painter: PatternPainter(),
              ),
            ),
          ),
          
          // Subtle gradient accents (matching Vue)
          Positioned(
            top: -96,
            right: -96,
            child: Container(
              width: 288,
              height: 288,
              decoration: BoxDecoration(
                color: const Color(0xFF34D399).withOpacity(0.05), // bg-emerald-400
                shape: BoxShape.circle,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withOpacity(0.05),
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
          ),
          
          Positioned(
            bottom: -96,
            left: -96,
            child: Container(
              width: 288,
              height: 288,
              decoration: BoxDecoration(
                color: const Color(0xFF60A5FA).withOpacity(0.05), // bg-blue-400
                shape: BoxShape.circle,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF60A5FA).withOpacity(0.05),
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
          ),
          
          // Content with relative positioning
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Top divider (w-60 mx-auto)
                Container(
                  width: 240, // w-60 = 15rem = 240px
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
                
                // Logo section
                Column(
                  children: [
                    _buildDynamicLogo(context),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        'AdsyClub – Social Business Network: Earn Money, Connect with Society & Find the Services You Need!',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Navigation links - responsive like Vue (horizontal for desktop, vertical for mobile)
                _buildResponsiveNavigation(context),
                
                const SizedBox(height: 32),
                
                // App download and payment section
                _buildAppPaymentSection(context),
                
                const SizedBox(height: 24),
                
                // Terms navigation
                _buildTermsNavigation(context),
                
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
                
                // Copyright section
                Container(
                  padding: const EdgeInsets.only(top: 24, bottom: 80), // pb-20 for mobile nav space
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicLogo(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleNavigation('Home'),
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 48, // h-10 sm:h-12
          maxWidth: 150,
        ),
        child: isLoading
            ? Container(
                height: 40,
                width: 120,
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
                ? Image.network(
                    logoData!['image'],
                    fit: BoxFit.contain,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallbackLogo();
                    },
                  )
                : _buildFallbackLogo(),
      ),
    );
  }

  Widget _buildFallbackLogo() {
    return Image.asset(
      'assets/images/logo.png',
      height: 40,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Text(
          logoData?['text'] ?? 'AdsyClub',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        );
      },
    );
  }

  Widget _buildResponsiveNavigation(BuildContext context) {
    final navLinks = [
      {'title': t('classified_service'), 'route': '/'},
      {'title': t('earn_money'), 'route': '/'},
      {'title': t('packeges'), 'route': '/upgrade-to-pro'},
      {'title': t('refer_program'), 'route': '/refer-a-friend'},
      {'title': t('about_us'), 'route': '/about'},
      {'title': t('contact_us'), 'route': '/contact-us'},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Vertical navigation for mobile
          return Column(
            children: navLinks.map((link) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 4),
              child: InkWell(
                onTap: () => _handleNavigation(link['title']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: navLinks.map((link) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: InkWell(
                onTap: () => _handleNavigation(link['title']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
        }
      },
    );
  }

  Widget _buildAppPaymentSection(BuildContext context) {
    return Column(
      children: [
        // App download section
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Store (w-[117px])
                SizedBox(
                  width: 117,
                  child: GestureDetector(
                    onTap: () => _showComingSoon('App Store'),
                    child: Container(
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
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Google Play (w-[119px])
                SizedBox(
                  width: 119,
                  child: GestureDetector(
                    onTap: _downloadAndroidApp,
                    child: Container(
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
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Payment section
        Column(
          children: [
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
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
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

  Widget _buildTermsNavigation(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: () => _handleNavigation(t('terms_conditions')),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Text(
              t('terms_conditions'),
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.normal,
              ),
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
          onTap: () => _handleNavigation(t('privacy_policy')),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Text(
              t('privacy_policy'),
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleButtonClick(String buttonId, String destination) {
    setState(() {
      _loadingButtons.add(buttonId);
    });
    
    // Simulate navigation delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _loadingButtons.remove(buttonId);
        });
        _handleNavigation(destination);
      }
    });
  }

  void _handleNavigation(String destination) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigate to $destination'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon'),
        backgroundColor: const Color(0xFF3B82F6),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _downloadAndroidApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download Started - AdsyClub Android app is downloading...'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// Custom painter for the background pattern (matching Vue's diagonal pattern)
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    const patternSize = 60.0;
    
    for (double x = 0; x < size.width + patternSize; x += patternSize) {
      for (double y = 0; y < size.height + patternSize; y += patternSize) {
        // Draw diagonal pattern squares
        final rect1 = Rect.fromLTWH(x, y, patternSize * 0.25, patternSize * 0.25);
        final rect2 = Rect.fromLTWH(x + patternSize * 0.5, y + patternSize * 0.5, patternSize * 0.25, patternSize * 0.25);
        final rect3 = Rect.fromLTWH(x + patternSize * 0.75, y + patternSize * 0.75, patternSize * 0.25, patternSize * 0.25);
        
        canvas.drawRect(rect1, paint);
        canvas.drawRect(rect2, paint);
        canvas.drawRect(rect3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}