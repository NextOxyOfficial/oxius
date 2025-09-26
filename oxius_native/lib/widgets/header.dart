import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import 'user_dropdown_menu.dart';

class AppHeader extends StatefulWidget {
  const AppHeader({super.key});

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  Map<String, dynamic>? logoData;
  bool isLoading = true;
  ScrollController? scrollController;
  bool isScrolled = false;
  bool _showUserDropdown = false;

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
      'home': 'Home',
      'business_network': 'Business Network',
      'adsy_news': 'News',
      'elearning': 'E-Learning',
      'earn_money': 'Earn Money',
      'qr_code_scanner': 'QR Code Scanner',
      'messages_inbox': 'Messages/Inbox',
      'login_profile': 'Login / Profile',
      'navigate_to': 'Navigate to',
      'coming_soon': 'coming soon!',
    };
    return translations[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _loadLogo();
  }

  @override
  void didUpdateWidget(AppHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh header when widget updates (e.g., after navigation)
    setState(() {});
  }

  // Load logo dynamically from API (matching Vue.js PublicLogo component)
  Future<void> _loadLogo() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/api/logo/'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Normalize possible relative image URLs to absolute
        if (data is Map && data['image'] != null) {
          data['image'] = _abs(data['image']);
        }
        setState(() {
          logoData = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading logo: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return GestureDetector(
      onTap: () {
        if (_showUserDropdown) {
          setState(() {
            _showUserDropdown = false;
          });
        }
      },
      child: SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      // Reduce spacing between the leading (menu) and title (logo)
      leadingWidth: isMobile ? 44 : 56,
      titleSpacing: isMobile ? 4 : 8,
      backgroundColor: Colors.white.withOpacity(0.95),
      surfaceTintColor: Colors.transparent,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200.withOpacity(0.5),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
      leading: Builder(
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
      title: Row(
        children: [
          _buildDynamicLogo(context),
          const Spacer(),
          // Desktop Navigation (matching Vue.js responsive behavior)
          if (!isMobile) ...[
            _buildDesktopNavigation(context),
          ],
          // Mobile profile/login section
          if (isMobile) ...[
            _buildMobileActions(context),
          ],
        ],
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
      // Responsive height matching Vue.js header
  toolbarHeight: isMobile ? 56 : 64,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      ),
    );
  }

  // Dynamic Logo Widget (matching Vue.js PublicLogo functionality)
  Widget _buildDynamicLogo(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to home functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Navigate to Home'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        constraints: BoxConstraints(
          minHeight: 32,
          maxHeight: MediaQuery.of(context).size.width < 768 ? 32 : 40,
          minWidth: 80,
          maxWidth: 170,
        ),
        child: isLoading
            ? _buildLoadingSkeleton()
            : _buildLogoContent(),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      height: 32,
      width: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoContent() {
    if (logoData != null && logoData!['image'] != null) {
      // Use dynamic logo from API (matching Vue.js logic)
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          logoData!['image'],
          height: MediaQuery.of(context).size.width < 768 ? 22 : 26,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackLogo();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingSkeleton();
          },
        ),
      );
    } else {
      // Fallback logo (matching Vue.js default logo.png)
      return _buildFallbackLogo();
    }
  }

  Widget _buildFallbackLogo() {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
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
          // Only show text as final fallback if image fails to load
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
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          );
        },
      ),
    );
  }

  // Desktop Navigation (matching Vue.js navigation structure)
  Widget _buildDesktopNavigation(BuildContext context) {
    final navItems = [
      {
        'titleKey': 'home',
        'icon': Icons.home,
        'color': const Color(0xFF3B82F6), // blue-500
        'route': '/',
      },
      {
        'titleKey': 'business_network',
        'icon': Icons.network_check,
        'color': const Color(0xFF10B981), // emerald-500
        'route': '/business-network',
      },
      {
        'titleKey': 'adsy_news',
        'icon': Icons.newspaper,
        'color': const Color(0xFFF59E0B), // amber-500
        'route': '/adsy-news',
      },
      {
        'titleKey': 'elearning',
        'icon': Icons.school,
        'color': const Color(0xFF8B5CF6), // purple-500
        'route': '/courses',
      },
      {
        'titleKey': 'earn_money',
        'icon': Icons.monetization_on,
        'color': const Color(0xFFEF4444), // red-500
        'route': '/#micro-gigs',
      },
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: navItems.map((item) {
        return _buildNavItem(
          context,
          t(item['titleKey'] as String), // Use translation
          item['icon'] as IconData,
          item['color'] as Color,
          item['route'] as String,
        );
      }).toList(),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${t('navigate_to')} $title'),
                backgroundColor: color,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
                // Animated underline (matching Vue.js hover effect)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  height: 2,
                  width: 0, // Will animate on hover in actual implementation
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Mobile Actions (matching Vue.js mobile behavior)
  Widget _buildMobileActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Inbox/Messages (matching Vue.js: i-material-symbols:mark-email-unread-outline)
        IconButton(
          icon: Icon(
            Icons.mark_email_unread_outlined,
            color: const Color(0xFF3B82F6), // Blue color matching Vue.js
            size: 24,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${t('messages_inbox')} ${t('coming_soon')}'),
                backgroundColor: const Color(0xFF3B82F6),
              ),
            );
          },
          tooltip: t('messages_inbox'),
        ),
        // QR Code Scanner (matching Vue.js: i-ic:twotone-qr-code-scanner)
        IconButton(
          icon: Icon(
            Icons.qr_code_scanner,
            color: const Color(0xFF10B981), // Green color matching Vue.js
            size: 24,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${t('qr_code_scanner')} ${t('coming_soon')}'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
          },
          tooltip: t('qr_code_scanner'),
        ),
        // User Profile/Login button
        _buildUserProfileButton(context),
      ],
    );
  }

  // User profile button with dropdown (using separate component)
  Widget _buildUserProfileButton(BuildContext context) {
    final currentUser = AuthService.currentUser;
    final isAuthenticated = AuthService.isAuthenticated;

    if (isAuthenticated && currentUser != null) {
      // Show user profile with custom dropdown
      return Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showUserDropdown = !_showUserDropdown;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: currentUser.userType == 'pro' || currentUser.isSuperuser
                        ? Colors.indigo.withOpacity(0.2)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Main avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: currentUser.profilePicture != null && currentUser.profilePicture!.isNotEmpty
                        ? NetworkImage(currentUser.profilePicture!)
                        : null,
                    child: currentUser.profilePicture == null || currentUser.profilePicture!.isEmpty
                        ? Icon(
                            Icons.person,
                            color: Colors.grey.shade600,
                            size: 20,
                          )
                        : null,
                  ),
                  
                  // PRO Badge (positioned like Vue mobile - top right)
                  if (currentUser.userType == 'pro' || currentUser.isSuperuser)
                    Positioned(
                      top: -10,
                      right: -14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], // indigo to violet
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shield,
                              color: Colors.white,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Pro',
                              style: GoogleFonts.roboto(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Verification badge (positioned like Vue mobile - bottom right)
                  if (currentUser.isActive)
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.verified,
                            color: Colors.blue.shade600,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Custom Dropdown Menu
          UserDropdownMenu(
            user: currentUser,
            isOpen: _showUserDropdown,
            onClose: () {
              setState(() {
                _showUserDropdown = false;
              });
            },
            onLogout: () => _handleLogout(context),
            onUpgradeToPro: () => _handleUpgradeToPro(context),
            onManageSubscription: () => _handleManageSubscription(context),
            onNavigate: (route) => _handleNavigation(context, route),
          ),
        ],
      );
    } else {
      // Show login button
      return IconButton(
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
        tooltip: t('login_profile'),
      );
    }
  }

  // Handle navigation to different routes
  void _handleNavigation(BuildContext context, String route) {
    setState(() {
      _showUserDropdown = false;
    });
    
    switch (route) {
      case '/business-network':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('business_network')} ${t('coming_soon')}')),
        );
        break;
      case '/adsy-news':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('adsy_news')} ${t('coming_soon')}')),
        );
        break;
      case '/my-classified-services':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('My Services coming soon!')),
        );
        break;
      case '/shop-manager':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('eShop Manager coming soon!')),
        );
        break;
      case '/deposit-withdraw':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adsy Pay coming soon!')),
        );
        break;
      case '/mobile-recharge':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mobile Recharge coming soon!')),
        );
        break;
      case '/settings':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings coming soon!')),
        );
        break;
      case '/upload-center':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification center coming soon!')),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigation to $route ${t('coming_soon')}')),
        );
        break;
    }
  }

  // Handle upgrade to pro
  void _handleUpgradeToPro(BuildContext context) {
    setState(() {
      _showUserDropdown = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upgrade to Pro coming soon!')),
    );
  }

  // Handle manage subscription
  void _handleManageSubscription(BuildContext context) {
    setState(() {
      _showUserDropdown = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manage subscription coming soon!')),
    );
  }

  // Handle logout
  void _handleLogout(BuildContext context) async {
    try {
      await AuthService.logout();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Logged out successfully',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Refresh the header to show login button
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }
}