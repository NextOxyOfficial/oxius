import 'package:flutter/material.dart';

class BusinessNetworkBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int unreadCount;
  final bool isLoggedIn;

  const BusinessNetworkBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadCount = 0,
    this.isLoggedIn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.grey.shade50.withOpacity(0.95),
            Colors.white.withOpacity(0.95),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200.withOpacity(0.4),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        minimum: EdgeInsets.zero,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: isLoggedIn ? _buildLoggedInNav(context) : _buildLoggedOutNav(context),
          ),
        ),
      ),
    );
  }

  // Logged IN users: Recent | Notifications | Create Post | Profile | AdsyClub
  List<Widget> _buildLoggedInNav(BuildContext context) {
    return [
      // Recent
      _buildNavItem(
        context,
        index: 0,
        icon: Icons.schedule_rounded,
        label: 'Recent',
        color: const Color(0xFF3B82F6),
        isActive: currentIndex == 0,
      ),
      
      // Notifications
      _buildNavItem(
        context,
        index: 1,
        icon: Icons.notifications_rounded,
        label: 'Notifications',
        color: const Color(0xFFEF4444),
        isActive: currentIndex == 1,
        badge: unreadCount > 0 ? unreadCount : null,
      ),
      
      // Create Post (Center - Elevated)
      _buildCreateButton(context, enabled: true),
      
      // Profile
      _buildNavItem(
        context,
        index: 3,
        icon: Icons.person_rounded,
        label: 'Profile',
        color: const Color(0xFFA855F7),
        isActive: currentIndex == 3,
      ),
      
      // AdsyClub
      _buildNavItem(
        context,
        index: 4,
        icon: Icons.home_rounded,
        label: 'AdsyClub',
        color: const Color(0xFF22C55E),
        isActive: currentIndex == 4,
        useFavicon: true,
      ),
    ];
  }

  // Logged OUT users: Recent | Login | Create Post (disabled) | Earn | AdsyClub
  List<Widget> _buildLoggedOutNav(BuildContext context) {
    return [
      // Recent
      _buildNavItem(
        context,
        index: 0,
        icon: Icons.schedule_rounded,
        label: 'Recent',
        color: const Color(0xFF3B82F6),
        isActive: currentIndex == 0,
      ),
      
      // Login
      _buildNavItem(
        context,
        index: 1,
        icon: Icons.login_rounded,
        label: 'Login',
        color: const Color(0xFFA855F7),
        isActive: currentIndex == 1,
      ),
      
      // Create Post (Disabled - grayed out)
      _buildCreateButton(context, enabled: false),
      
      // Earn
      _buildNavItem(
        context,
        index: 3,
        icon: Icons.attach_money_rounded,
        label: 'Earn',
        color: const Color(0xFFF59E0B),
        isActive: currentIndex == 3,
      ),
      
      // AdsyClub
      _buildNavItem(
        context,
        index: 4,
        icon: Icons.home_rounded,
        label: 'AdsyClub',
        color: const Color(0xFF22C55E),
        isActive: currentIndex == 4,
        useFavicon: true,
      ),
    ];
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
    int? badge,
    bool useFavicon = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Icon or Favicon with gradient effect when active
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? RadialGradient(
                              colors: [
                                color.withOpacity(0.15),
                                Colors.transparent,
                              ],
                            )
                          : null,
                      shape: BoxShape.circle,
                    ),
                    child: useFavicon
                        ? Image.asset(
                            'assets/images/favicon.png',
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                icon,
                                size: 20,
                                color: isActive ? color : Colors.grey.shade600,
                              );
                            },
                          )
                        : Icon(
                            icon,
                            size: 20,
                            color: isActive ? color : Colors.grey.shade600,
                          ),
                  ),
                  
                  // Badge for notifications
                  if (badge != null && badge > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          badge > 99 ? '99+' : badge.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  
                  // Ping animation for active state
                  if (isActive)
                    Positioned.fill(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1.2),
                        duration: const Duration(milliseconds: 2500),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.withOpacity(0.1 * (1.2 - value)),
                              ),
                            ),
                          );
                        },
                        onEnd: () {},
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isActive ? color : Colors.grey.shade600,
                  letterSpacing: 0,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Active indicator line
              if (isActive) const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context, {required bool enabled}) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? () => onTap(2) : null,
        child: Transform.translate(
          offset: const Offset(0, -6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: enabled
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF3B82F6),
                            Color(0xFF6366F1),
                            Color(0xFF8B5CF6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: enabled ? null : const Color(0xFFCBD5E1).withOpacity(0.3),
                  shape: BoxShape.circle,
                  boxShadow: enabled
                      ? [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Icon(
                  Icons.add,
                  color: enabled ? Colors.white : Colors.grey.shade300,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
