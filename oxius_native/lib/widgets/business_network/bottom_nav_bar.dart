import 'package:flutter/material.dart';

class BusinessNetworkBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int unreadCount;

  const BusinessNetworkBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadCount = 0,
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
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Recent
              _buildNavItem(
                context: context,
                index: 0,
                icon: Icons.schedule_rounded,
                label: 'Recent',
                color: const Color(0xFF3B82F6),
                isActive: currentIndex == 0,
              ),
              
              // Notifications
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.notifications_rounded,
                label: 'Notifications',
                color: const Color(0xFFEF4444),
                isActive: currentIndex == 1,
                badge: unreadCount > 0 ? unreadCount : null,
              ),
              
              // Create Post (Center - Elevated)
              _buildCreateButton(context),
              
              // Profile
              _buildNavItem(
                context: context,
                index: 3,
                icon: Icons.person_rounded,
                label: 'Profile',
                color: const Color(0xFFA855F7),
                isActive: currentIndex == 3,
              ),
              
              // Home/AdsyClub
              _buildNavItem(
                context: context,
                index: 4,
                icon: Icons.home_rounded,
                label: 'AdsyClub',
                color: const Color(0xFF22C55E),
                isActive: currentIndex == 4,
                useFavicon: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
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
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Icon or Favicon with gradient effect when active
                  Container(
                    width: 24,
                    height: 24,
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
                            width: 22,
                            height: 22,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                icon,
                                size: 22,
                                color: isActive ? color : Colors.grey.shade600,
                              );
                            },
                          )
                        : Icon(
                            icon,
                            size: 22,
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
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isActive ? color : Colors.grey.shade600,
                  letterSpacing: 0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Active indicator line
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(top: 1),
                  width: 24,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.5),
                        color,
                        color.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(2),
        child: Transform.translate(
          offset: const Offset(0, -6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF3B82F6),
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
