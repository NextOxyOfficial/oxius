import 'package:flutter/material.dart';
import '../widgets/footer.dart';
import '../widgets/mobile_drawer.dart';
import '../widgets/mobile_banner.dart';
import '../widgets/sale_category.dart';
import '../widgets/classified_services_section.dart';
import '../widgets/eshop_section.dart';
import '../widgets/micro_gigs_section.dart';
import '../services/scroll_direction_service.dart';
import '../services/user_state_service.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ScrollController _scrollController;
  final ScrollDirectionService _scrollService = ScrollDirectionService();
  bool _disposed = false;
  bool _isDropdownOpen = false; // Track dropdown menu state

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
      body: Stack(
        children: [
          Column(
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
                  // 1. Hero Banner - Main banner slider at top
                  const SizedBox(height: 8),
                  const MobileBannerWidget(
                    autoplayInterval: 5000,
                    autoplayEnabled: true,
                  ),
                  
                  // 2. Sale Category - eShop product categories
                  const SaleCategory(),
                  
                  // 3. Search Form - TODO: Implement search functionality for classified ads
                  // This is a placeholder for the search form section from Vue
                  
                  // 4. Classified Services - Service categories
                  const ClassifiedServicesSection(),
                  
                  // 5. Recent Ads Scroll - TODO: Implement AdsScroll widget
                  // This shows recent classified posts (classifiedLatestPosts)
                  
                  // 6. eShop Product Slider - Product carousel
                  const EshopSection(),
                  
                  // 7. Micro Gigs Section - Gigs with categories and pagination
                  const MicroGigsSection(),
                  
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
          
          // User Dropdown Menu Overlay
          if (_isDropdownOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isDropdownOpen = false;
                  });
                },
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
            ),
          
          // User Dropdown Menu
          if (_isDropdownOpen)
            _buildUserDropdownMenu(context),
        ],
      ),
      
      // Fixed Mobile Navigation Bar (outside of scrollable content)
      floatingActionButton: isMobile ? _buildStickyMobileNav(context) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildUserDropdownMenu(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 640; // sm breakpoint
    
    return Positioned(
      top: 68, // Below header
      right: isMobile ? 8 : 0,
      left: isMobile ? 8 : null,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.black.withOpacity(0.08),
        child: Container(
          width: isMobile ? 288 : 320, // w-72 (288px) mobile, sm:w-80 (320px) desktop
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height - 100),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0).withOpacity(0.5),
              width: 1,
            ),
          ),
          child: SingleChildScrollView(
            child: _buildDropdownContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownContent(BuildContext context) {
    final userState = UserStateService();
    final user = userState.currentUser;
    final isPro = user?.userType == 'pro' || user?.isSuperuser == true;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated gradient accent at top
        Container(
          height: 4,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF818CF8), Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF6366F1)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),
        
        // Membership Section - px-2 pb-3 (8px horizontal, 12px bottom)
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: _buildMembershipCard(context, isPro, user),
        ),
        
        // Main Navigation Grid - px-4 pt-2 pb-3
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 8, // gap-2
            mainAxisSpacing: 8, // gap-2
            childAspectRatio: 1.2,
            children: [
              _buildNavLink(context, 'Business', Icons.public_outlined, 
                const Color(0xFFF97316), false, null),
              _buildNavLink(context, 'News', Icons.newspaper_outlined, 
                const Color(0xFF8B5CF6), false, null),
              _buildNavLink(context, 'My Ads', Icons.campaign_outlined, 
                const Color(0xFF10B981), true, 'FREE'),
              _buildNavLink(context, 'eShop', Icons.shopping_bag_outlined, 
                const Color(0xFF3B82F6), true, 'PRO'),
              _buildNavLink(context, 'Wallet', Icons.account_balance_wallet_outlined, 
                const Color(0xFF10B981), false, null),
              _buildNavLink(context, 'Recharge', Icons.phone_android, 
                const Color(0xFFF97316), false, null),
            ],
          ),
        ),
        
        // Settings & Logout Section - px-4 py-3
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: const Color(0xFFF1F5F9).withOpacity(0.5)),
            ),
          ),
          child: Column(
            children: [
              // Settings & Verification Row
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      'Settings',
                      Icons.settings_outlined,
                      const Color(0xFF64748B),
                      () {
                        setState(() => _isDropdownOpen = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Navigate to Settings')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      'Verification',
                      Icons.verified_user_outlined,
                      const Color(0xFF64748B),
                      () {
                        setState(() => _isDropdownOpen = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Navigate to Verification')),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Logout Button
              _buildLogoutButton(context, userState),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipCard(BuildContext context, bool isPro, user) {
    if (!isPro) {
      // Free User Card
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Current Plan Header - px-3 py-2.5
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(
                  bottom: BorderSide(color: const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'Current Plan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'FREE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Upgrade to Pro Action - p-3.5
            InkWell(
              onTap: () {
                setState(() => _isDropdownOpen = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Upgrade to Pro'),
                    backgroundColor: Color(0xFF6366F1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14), // p-3.5
                child: Row(
                  children: [
                    // Pro Badge Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFC4B5FD).withOpacity(0.8),
                        ),
                      ),
                      child: const Center(
                        child: Text('⭐', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Upgrade Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Upgrade to Pro',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    '+',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Unlock premium features',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Toggle Switch
                    Container(
                      width: 44,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade300, Colors.grey.shade400],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
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
      );
    } else {
      // Pro User Card
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC7D2FE)),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Premium Access Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEEF2FF), Color(0xFFDEF7FD)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(
                  bottom: BorderSide(color: const Color(0xFFE0E7FF).withOpacity(0.3)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.stars, size: 16, color: Color(0xFF6366F1)),
                      SizedBox(width: 6),
                      Text(
                        'Premium Access',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.shield_outlined, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Pro Status - p-3.5
            InkWell(
              onTap: () {
                setState(() => _isDropdownOpen = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Manage Subscription'),
                    backgroundColor: Color(0xFF6366F1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14), // p-3.5
                child: Row(
                  children: [
                    // Premium Badge
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6366F1).withOpacity(0.1),
                            const Color(0xFF2563EB).withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC7D2FE).withOpacity(0.5)),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Pro Status Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pro Member',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Valid until Dec 31, 2025',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Active Toggle
                    Container(
                      width: 44,
                      height: 24,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF818CF8), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
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
      );
    }
  }

  Widget _buildNavLink(BuildContext context, String label, IconData icon, 
      Color color, bool hasBadge, String? badgeText) {
    return InkWell(
      onTap: () {
        setState(() {
          _isDropdownOpen = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigate to $label'),
            backgroundColor: color,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12), // py-3 px-2
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.15),
                  color.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36, // w-9
                  height: 36, // h-9
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20), // w-5 h-5
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          // Badge (FREE or PRO)
          if (hasBadge && badgeText != null)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: badgeText == 'PRO'
                        ? const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF2563EB)],
                          )
                        : LinearGradient(
                            colors: [Colors.grey.shade500, Colors.grey.shade600],
                          ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (badgeText == 'PRO')
                        const Icon(Icons.stars, size: 8, color: Color(0xFFFDE68A)),
                      if (badgeText == 'PRO') const SizedBox(width: 2),
                      Text(
                        badgeText,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, 
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // py-2 px-3
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, UserStateService userState) {
    return Container(
      margin: const EdgeInsets.only(top: 4), // mt-1
      child: InkWell(
        onTap: () async {
          setState(() {
            _isDropdownOpen = false;
          });
          await AuthService.logout();
          await userState.clearUser();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Logged out successfully'),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // py-2 px-3
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFECACA).withOpacity(0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_outlined,
                  size: 16,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFixedHeader(BuildContext context, bool isMobile) {
    final userState = UserStateService();
    
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
      ),
      child: ListenableBuilder(
        listenable: userState,
        builder: (context, _) {
          return Row(
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
                const SizedBox(width: 16),
                // Desktop User Actions
                _buildDesktopUserActions(context, userState),
              ],
              
              // Mobile actions
              if (isMobile) ...[
                _buildMobileActions(context),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopUserActions(BuildContext context, UserStateService userState) {
    final isAuthenticated = userState.isAuthenticated;
    final user = userState.currentUser;

    if (isAuthenticated && user != null) {
      // Logged in user actions
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Inbox Button
          IconButton(
            icon: const Icon(
              Icons.mark_email_unread_outlined,
              color: Color(0xFF3B82F6),
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
            tooltip: 'Messages',
          ),
          // QR Code Button
          IconButton(
            icon: const Icon(
              Icons.qr_code_scanner,
              color: Color(0xFF10B981),
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
            tooltip: 'QR Scanner',
          ),
          const SizedBox(width: 8),
          // User Profile Button (Desktop style)
          GestureDetector(
            onTap: () {
              setState(() {
                _isDropdownOpen = !_isDropdownOpen;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipOval(
                      child: user.profilePicture != null && user.profilePicture!.isNotEmpty
                          ? Image.network(
                              user.profilePicture!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFF10B981),
                                  child: Center(
                                    child: Text(
                                      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: const Color(0xFF10B981),
                              child: Center(
                                child: Text(
                                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // User Name (truncated)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Text(
                      user.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // Guest user - show login button
      return ElevatedButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/login');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.grey.shade800,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Login',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
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
    final userState = UserStateService();
    
    return ListenableBuilder(
      listenable: userState,
      builder: (context, _) {
        final isAuthenticated = userState.isAuthenticated;
        final user = userState.currentUser;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show user action buttons only if logged in
            if (isAuthenticated && user != null) ...[
              // Inbox Button with badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.mark_email_unread_outlined,
                      color: Color(0xFF3B82F6),
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
                  // Badge for unread messages (placeholder)
                  // Positioned(
                  //   right: 8,
                  //   top: 8,
                  //   child: Container(
                  //     padding: const EdgeInsets.all(2),
                  //     decoration: const BoxDecoration(
                  //       color: Colors.red,
                  //       shape: BoxShape.circle,
                  //     ),
                  //     constraints: const BoxConstraints(
                  //       minWidth: 16,
                  //       minHeight: 16,
                  //     ),
                  //     child: const Text(
                  //       '5',
                  //       style: TextStyle(
                  //         color: Colors.white,
                  //         fontSize: 10,
                  //         fontWeight: FontWeight.bold,
                  //       ),
                  //       textAlign: TextAlign.center,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
              // QR Code Scanner Button
              IconButton(
                icon: const Icon(
                  Icons.qr_code_scanner,
                  color: Color(0xFF10B981),
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
              // User Profile Avatar
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isDropdownOpen = !_isDropdownOpen;
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: user.profilePicture != null && user.profilePicture!.isNotEmpty
                        ? Image.network(
                            user.profilePicture!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF10B981),
                                child: Center(
                                  child: Text(
                                    user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: const Color(0xFF10B981),
                            child: Center(
                              child: Text(
                                user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ] else ...[
              // Show login button for guests
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
          ],
        );
      },
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