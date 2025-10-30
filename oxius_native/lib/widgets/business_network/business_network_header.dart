import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/business_network_service.dart';
import 'adsypay_qr_modal.dart';
import '../../screens/business_network/search_screen.dart';

class BusinessNetworkHeader extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onQRCodeTap;
  final VoidCallback? onProfileTap;
  
  const BusinessNetworkHeader({
    super.key,
    this.onMenuTap,
    this.onSearchTap,
    this.onQRCodeTap,
    this.onProfileTap,
  });

  @override
  State<BusinessNetworkHeader> createState() => _BusinessNetworkHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _BusinessNetworkHeaderState extends State<BusinessNetworkHeader> {
  bool _showUserMenu = false;
  String? _businessNetworkLogoUrl;

  @override
  void initState() {
    super.initState();
    _loadBusinessNetworkLogo();
  }

  Future<void> _loadBusinessNetworkLogo() async {
    final logoUrl = await BusinessNetworkService.getBusinessNetworkLogo();
    if (mounted) {
      setState(() {
        _businessNetworkLogoUrl = logoUrl;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 640;

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            // Close dropdown when tapping outside
            if (_showUserMenu) {
              setState(() {
                _showUserMenu = false;
              });
            }
          },
          child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        toolbarHeight: kToolbarHeight,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      title: Row(
              children: [
                // Sidebar Toggle (Mobile Only)
                if (isMobile) ...[
                  InkWell(
                    onTap: widget.onMenuTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 18,
                              height: 2,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade700,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 14,
                              height: 2,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade700,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 18,
                              height: 2,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade700,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                // Logo (Dynamic with Fallback)
                InkWell(
                  onTap: () {
                    // Navigate to business network home
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/business-network',
                      (route) => route.settings.name == '/',
                    );
                  },
                  child: Row(
                    children: [
                      _businessNetworkLogoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _businessNetworkLogoUrl!,
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildFallbackLogo();
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.blue.shade500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : _buildFallbackLogo(),
                      const SizedBox(width: 8),
                      if (!isMobile)
                        const Text(
                          'Business Network',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: -0.3,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
      actions: [
              // Search Button
              IconButton(
                onPressed: () {
                  print('Search button tapped - opening SearchScreen');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.search, size: 22),
                color: Colors.grey.shade700,
                tooltip: 'Search',
              ),
        
        // AdsyClub Button (Desktop Only)
        if (!isMobile) ...[
          const SizedBox(width: 4),
          _buildNavButton(
            label: 'AdsyClub',
            icon: Icons.bar_chart_rounded,
            gradient: LinearGradient(
              colors: [Colors.blue.shade500, Colors.indigo.shade600],
            ),
            onTap: () {
              // Navigate to AdsyClub
            },
          ),
        ],
        
        // AdsyNews Button (Desktop Only)
        if (!isMobile) ...[
          const SizedBox(width: 4),
          _buildNavButton(
            label: 'AdsyNews',
            icon: Icons.newspaper,
            gradient: LinearGradient(
              colors: [Colors.amber.shade500, Colors.orange.shade600],
            ),
            onTap: () {
              // Navigate to AdsyNews
            },
          ),
        ],
        
        // User Section
        if (user != null) ...[
          // QR Code Button
          IconButton(
            onPressed: () {
              // Show AdsyPay QR modal
              showDialog(
                context: context,
                builder: (context) => AdsyPayQrModal(
                  qrData: 'adsypay://pay/${user.id}',
                  title: '${user.firstName ?? user.username ?? "User"}\'s Payment QR',
                ),
              );
            },
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade50,
              ),
              child: Icon(
                Icons.qr_code_scanner,
                size: 20,
                color: Colors.green.shade600,
              ),
            ),
            tooltip: 'QR Code',
          ),
          
          // User Profile Button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                if (isMobile) {
                  widget.onProfileTap?.call();
                } else {
                  setState(() {
                    _showUserMenu = !_showUserMenu;
                  });
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: isMobile
                  ? _buildMobileUserAvatar(user)
                  : _buildDesktopUserButton(user),
            ),
          ),
        ] else ...[
          // Login Button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: isMobile
                ? IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                : OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'Login/Register',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
          ),
        ],
      ],
          ),
        ),
        // Show dropdown menu
        if (_showUserMenu && user != null)
          _buildUserDropdown(context, user),
      ],
    );
  }

  Widget _buildUserDropdown(BuildContext context, dynamic user) {
    return Positioned(
      top: 60,
      right: 8,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User Info Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.indigo.shade50],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: user.image != null
                          ? NetworkImage(user.image)
                          : null,
                      child: user.image == null
                          ? Icon(Icons.person, color: Colors.grey.shade400)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.firstName ?? user.username ?? 'User',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.email ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation Grid
              Container(
                padding: const EdgeInsets.all(12),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.1,
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
                      onTap: () async {
                        setState(() {
                          _showUserMenu = false;
                        });
                        await AuthService.logout();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
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
          _showUserMenu = false;
        });
        Navigator.pushNamed(context, route);
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
          _showUserMenu = false;
        });
        Navigator.pushNamed(context, route);
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

  Widget _buildNavButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileUserAvatar(dynamic user) {
    final isPro = user.isPro ?? false;
    final isVerified = user.isVerified ?? false;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isPro ? Colors.indigo.shade500 : Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isPro
                    ? Colors.indigo.shade200.withOpacity(0.5)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: ClipOval(
            child: user.profilePicture != null
                ? Image.network(
                    user.profilePicture!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.grey.shade400,
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.person,
                      size: 20,
                      color: Colors.grey.shade400,
                    ),
                  ),
          ),
        ),
        
        // Pro Badge
        if (isPro)
          Positioned(
            top: -8,
            right: -12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade500, Colors.purple.shade600],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield, size: 10, color: Colors.white),
                  const SizedBox(width: 2),
                  const Text(
                    'Pro',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Verified Badge
        if (isVerified)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified,
                size: 14,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopUserButton(dynamic user) {
    final isPro = user.isPro ?? false;
    final isVerified = user.isVerified ?? false;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pro Badge
          if (isPro)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade500, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  const Text(
                    'Pro',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          
          if (isPro) const SizedBox(width: 6),
          
          // Verified Icon
          if (isVerified) ...[
            const Icon(
              Icons.verified,
              size: 16,
              color: Color(0xFF3B82F6),
            ),
            const SizedBox(width: 4),
          ],
          
          // Avatar
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipOval(
              child: user.profilePicture != null
                  ? Image.network(
                      user.profilePicture!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(width: 6),
          
          // Dropdown Icon
          Icon(
            _showUserMenu ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            size: 16,
            color: Colors.grey.shade600,
          ),
          
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildFallbackLogo() {
    return Container(
      width: 32,
      height: 32,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade500,
            Colors.indigo.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.business_center,
        size: 18,
        color: Colors.white,
      ),
    );
  }
}
