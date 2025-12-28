import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/auth_service.dart';
import '../../services/business_network_service.dart';
import '../../services/adsyconnect_service.dart';
import '../../screens/business_network/search_screen.dart';
import 'dart:async';

class BusinessNetworkHeader extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;
  
  const BusinessNetworkHeader({
    super.key,
    this.onMenuTap,
    this.onSearchTap,
    this.onProfileTap,
  });

  @override
  State<BusinessNetworkHeader> createState() => _BusinessNetworkHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _BusinessNetworkHeaderState extends State<BusinessNetworkHeader> {
  String? _businessNetworkLogoUrl;
  int _totalNotificationCount = 0;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _loadBusinessNetworkLogo();
    _loadNotificationCount();
    
    // Poll for notification updates every 10 seconds
    _notificationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && AuthService.isAuthenticated) {
        _loadNotificationCount();
      }
    });
  }

  Future<void> _loadBusinessNetworkLogo() async {
    final logoUrl = await BusinessNetworkService.getBusinessNetworkLogo();
    if (mounted) {
      setState(() {
        _businessNetworkLogoUrl = logoUrl;
      });
    }
  }

  Future<void> _loadNotificationCount() async {
    if (!AuthService.isAuthenticated) {
      if (mounted) {
        setState(() {
          _totalNotificationCount = 0;
        });
      }
      return;
    }
    
    try {
      // Get unread message count from chat rooms (like home screen)
      final chatRooms = await AdsyConnectService.getChatRooms(page: 1);
      
      int totalUnread = 0;
      for (var room in chatRooms) {
        totalUnread += (room['unread_count'] as int?) ?? 0;
      }
      
      if (mounted) {
        setState(() {
          _totalNotificationCount = totalUnread;
        });
      }
    } catch (e) {
      print('Error loading notification count: $e');
    }
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

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
                      _businessNetworkLogoUrl != null && _businessNetworkLogoUrl!.isNotEmpty
                          ? (_businessNetworkLogoUrl!.toLowerCase().contains('.svg')
                              ? SvgPicture.network(
                                  _businessNetworkLogoUrl!,
                                  height: 32,
                                  fit: BoxFit.contain,
                                  placeholderBuilder: (context) {
                                    return const Text(
                                      'Business Network',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                        letterSpacing: -0.3,
                                      ),
                                    );
                                  },
                                )
                              : Image.network(
                                  _businessNetworkLogoUrl!,
                                  height: 32,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Text(
                                      'Business Network',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                        letterSpacing: -0.3,
                                      ),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Text(
                                      'Business Network',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                        letterSpacing: -0.3,
                                      ),
                                    );
                                  },
                                ))
                          : const Text(
                              'Business Network',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                                letterSpacing: -0.3,
                              ),
                            ),
                      const SizedBox(width: 16),
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
              Navigator.pushNamed(context, '/eshop');
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
              Navigator.pushNamed(context, '/news');
            },
          ),
        ],
        
        // User Section
        if (user != null) ...[
          // Inbox Button with Notification Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  // Navigate to Inbox
                  Navigator.pushNamed(context, '/inbox');
                },
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/chat_icon.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.chat_bubble_outline,
                          size: 24,
                          color: Color(0xFF3B82F6),
                        );
                      },
                    ),
                  ),
                ),
                tooltip: 'Inbox',
              ),
              // Notification Badge
              if (_totalNotificationCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        _totalNotificationCount > 99 ? '99+' : _totalNotificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          // User Profile Button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                widget.onProfileTap?.call();
              },
              borderRadius: BorderRadius.circular(20),
              child: _buildMobileUserAvatar(user),
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


}
