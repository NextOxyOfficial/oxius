import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'adsypay_qr_modal.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 640;

    return AppBar(
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
          
          // Logo
          InkWell(
            onTap: () {
              // Navigate to home
            },
            child: Row(
              children: [
                Container(
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
                ),
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
          onPressed: widget.onSearchTap,
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
                      // Navigate to login
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
                      // Navigate to login
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
}
