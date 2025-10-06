import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class AppHeader extends StatefulWidget {
  final String identifier;
  
  const AppHeader({
    super.key, 
    required this.identifier,
  });

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

    return SliverToBoxAdapter(
      key: ValueKey('header_sliver_${widget.identifier}'),
      child: GestureDetector(
        key: ValueKey('header_gesture_${widget.identifier}'),
        onTap: () {
          if (_showUserDropdown) {
            setState(() {
              _showUserDropdown = false;
            });
          }
        },
        child: Container(
          height: 64,
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
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 16,
              ),
              child: Row(
                children: [
                  // Menu Button
                  Builder(
                    key: ValueKey('menu_builder_${widget.identifier}'),
                    builder: (context) => IconButton(
                      key: ValueKey('menu_button_${widget.identifier}'),
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
                  // Logo
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
            ),
          ),
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



  // Mobile Actions (matching Vue.js mobile behavior)
  Widget _buildMobileActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Inbox/Messages (matching Vue.js: i-material-symbols:mark-email-unread-outline)
        IconButton(
          key: ValueKey('messages_button_${widget.identifier}'),
          icon: Icon(
            Icons.mark_email_unread_outlined,
            color: const Color(0xFF3B82F6), // Blue color matching Vue.js
            size: 24,
          ),
          onPressed: () {
            Navigator.pushNamed(context, '/inbox');
          },
          tooltip: t('messages_inbox'),
        ),
        // QR Code Scanner (matching Vue.js: i-ic:twotone-qr-code-scanner)
        IconButton(
          key: ValueKey('qr_button_${widget.identifier}'),
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
        key: ValueKey('user_stack_${widget.identifier}'),
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            key: ValueKey('user_gesture_${widget.identifier}'),
            onTap: () {
              setState(() {
                _showUserDropdown = !_showUserDropdown;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main avatar container
                  Container(
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
                    child: CircleAvatar(
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
                  ),
                  
                  // PRO Badge (positioned like Vue - small overlap on top right)
                  if (currentUser.userType == 'pro' || currentUser.isSuperuser)
                    Positioned(
                      top: -2,
                      right: -8,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 28),
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], // indigo to violet
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 1,
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
                              size: 6,
                            ),
                            const SizedBox(width: 1),
                            Text(
                              'PRO',
                              style: GoogleFonts.roboto(
                                fontSize: 6,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Verification badge (positioned like Vue - small overlap on bottom right)
                  if (currentUser.isActive)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 1,
                              offset: const Offset(0, 0.5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.verified,
                            color: Colors.blue.shade600,
                            size: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Custom Dropdown Menu - inline to avoid widget conflicts
          if (_showUserDropdown) _buildDropdownMenu(context, currentUser),
        ],
      );
    } else {
      // Show login button
      return IconButton(
        key: ValueKey('login_button_${widget.identifier}'),
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

  // Build inline dropdown menu to avoid widget conflicts
  Widget _buildDropdownMenu(BuildContext context, User currentUser) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 640;
    final dropdownWidth = (isSmallScreen ? 280 : 320).toDouble();
    final isPro = currentUser.userType == 'pro' || currentUser.isSuperuser;

    return Positioned(
      key: ValueKey('dropdown_positioned_${widget.identifier}'),
      top: 52,
      right: 4,
      child: Material(
        key: ValueKey('dropdown_material_${widget.identifier}'),
        color: Colors.transparent,
        child: Container(
          key: ValueKey('dropdown_container_${widget.identifier}'),
          width: dropdownWidth,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated gradient accent
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF818CF8), // primary-400
                      Color(0xFF6366F1), // indigo-500
                      Color(0xFF8B5CF6), // primary-600
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
              ),
              
              // Membership Section
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPro 
                        ? const Color(0xFFC7D2FE) // indigo-200
                        : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Current Plan Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isPro 
                            ? const Color(0xFFEEF2FF) // indigo-50
                            : const Color(0xFFF8FAFC), // slate-50
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: isPro 
                                ? const Color(0xFFE0E7FF) // indigo-100
                                : Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isPro ? Icons.star : Icons.person,
                                  size: 16,
                                  color: isPro 
                                    ? const Color(0xFF4F46E5) // indigo-600
                                    : Colors.grey.shade500,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isPro ? 'Premium Access' : 'Current Plan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isPro 
                                      ? const Color(0xFF3730A3) // indigo-700
                                      : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: isPro 
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF6366F1), // indigo-500
                                        Color(0xFF2563EB), // blue-600
                                      ],
                                    )
                                  : null,
                                color: isPro ? null : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isPro ? 'PRO' : 'FREE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: isPro ? Colors.white : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Upgrade/Manage Section
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showUserDropdown = false;
                          });
                          isPro ? _handleManageSubscription(context) : _handleUpgradeToPro(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isPro 
                                    ? const Color(0xFF6366F1).withOpacity(0.1)
                                    : const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isPro 
                                      ? const Color(0xFF6366F1).withOpacity(0.3)
                                      : const Color(0xFFC7D2FE).withOpacity(0.8),
                                  ),
                                ),
                                child: Icon(
                                  isPro ? Icons.shield_outlined : Icons.star,
                                  size: 14,
                                  color: isPro 
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFF8B5CF6),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isPro ? 'Pro Member' : 'Upgrade to Pro',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      isPro ? 'Premium active' : 'Unlock features',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 36,
                                height: 20,
                                decoration: BoxDecoration(
                                  gradient: isPro 
                                    ? const LinearGradient(
                                        colors: [Color(0xFF6366F1), Color(0xFF2563EB)],
                                      )
                                    : LinearGradient(
                                        colors: [Colors.grey.shade200, Colors.grey.shade300],
                                      ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Align(
                                    alignment: isPro ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Navigation Grid
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1.4,
                  children: [
                    _buildNavItem(context, 'Business Network', Icons.network_check, const Color(0xFFEA580C), '/business-network'),
                    _buildNavItem(context, 'Adsy News', Icons.newspaper, const Color(0xFF9333EA), '/adsy-news'),
                    _buildNavItem(context, 'Ad Services', Icons.campaign, const Color(0xFF059669), '/classified', badge: 'FREE'),
                    _buildNavItem(context, 'eShop Manager', Icons.shopping_bag, const Color(0xFF2563EB), '/shop-manager', badge: 'PRO'),
                    _buildNavItem(context, 'Adsy Pay', Icons.payments, const Color(0xFF059669), '/deposit-withdraw'),
                    _buildNavItem(context, 'Mobile Recharge', Icons.phone_android, const Color(0xFFEA580C), '/mobile-recharge'),
                  ],
                ),
              ),

              // Settings & Logout
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade100, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(context, 'Settings', Icons.settings, '/settings'),
                        _buildActionButton(context, 'Verification', Icons.upload_file, '/upload-center'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(context, 'Inbox', Icons.mark_email_unread_outlined, '/inbox'),
                        _buildActionButton(context, 'My Gigs', Icons.list_rounded, '/my-gigs'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(context, 'Post A Gig', Icons.add_circle_outline, '/post-a-gig'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showUserDropdown = false;
                        });
                        _handleLogout(context);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, size: 14, color: Colors.red.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.red.shade600,
                              ),
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
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String label, IconData icon, Color color, String route, {String? badge}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showUserDropdown = false;
        });
        _handleNavigation(context, route);
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Stack(
          children: [
            if (badge != null)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: badge == 'PRO' ? const Color(0xFF6366F1) : Colors.grey.shade500,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    child: Icon(icon, size: 12, color: Colors.white),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, String route) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showUserDropdown = false;
        });
        _handleNavigation(context, route);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(icon, size: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.black87)),
          ],
        ),
      ),
    );
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
        Navigator.pushNamed(context, '/settings');
        break;
      case '/upload-center':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification center coming soon!')),
        );
        break;
      case '/inbox':
        Navigator.pushNamed(context, '/inbox');
        break;
      case '/my-gigs':
        Navigator.pushNamed(context, '/my-gigs');
        break;
      case '/post-a-gig':
        Navigator.pushNamed(context, '/post-a-gig');
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