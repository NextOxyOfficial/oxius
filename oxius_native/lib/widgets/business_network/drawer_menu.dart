import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../screens/business_network/create_post_screen.dart';
import '../../screens/business_network/profile_screen.dart';
import '../../screens/business_network/notifications_screen.dart';
import '../../screens/business_network/mindforce_screen.dart';

class DrawerMenu extends StatelessWidget {
  final String? currentRoute;
  
  const DrawerMenu({
    super.key,
    this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50.withOpacity(0.3),
            Colors.purple.shade50.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create Post Button (only for logged-in users)
          if (user != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreatePostScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Create Post',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // Menu Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFFA855F7)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.menu,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'MENU',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          
          // Menu Items
          _buildMenuItem(
            context: context,
            icon: Icons.bolt,
            label: 'Recent',
            route: '/business-network',
            isActive: currentRoute == '/business-network',
            color: const Color(0xFF3B82F6),
            onTap: () {
              Navigator.pop(context); // Close drawer
              // If already on business network screen, just close drawer
              // Otherwise navigate to it
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/business-network',
                (route) => route.settings.name == '/',
              );
            },
          ),
          
          if (user != null)
            _buildMenuItem(
              context: context,
              icon: Icons.person,
              label: 'Profile',
              route: '/business-network/profile/${user.id}',
              isActive: currentRoute?.contains('/business-network/profile/') ?? false,
              color: const Color(0xFFA855F7),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(userId: user.id),
                  ),
                );
              },
            ),
          
          _buildMenuItem(
            context: context,
            icon: Icons.tag,
            label: 'MindForce',
            route: '/business-network/mindforce',
            isActive: currentRoute == '/business-network/mindforce',
            color: const Color(0xFF10B981),
            badge: 'NEW',
            badgeColor: Colors.pink,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MindForceScreen(),
                ),
              );
            },
          ),
          
          // TODO: Workspaces - Hidden for next release
          // _buildMenuItem(
          //   context: context,
          //   icon: Icons.star,
          //   label: 'Workspaces',
          //   route: '/business-network/workspaces',
          //   isActive: currentRoute == '/business-network/workspaces',
          //   color: const Color(0xFFF59E0B),
          //   badge: 'BETA',
          //   badgeColor: Colors.orange,
          // ),
          
          _buildMenuItem(
            context: context,
            icon: Icons.notifications,
            label: 'Notifications',
            route: '/business-network/notifications',
            isActive: currentRoute == '/business-network/notifications',
            color: const Color(0xFFEF4444),
            notificationCount: 0, // TODO: Get from API
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          
          _buildMenuItem(
            context: context,
            icon: Icons.settings,
            label: 'Settings',
            route: '/settings',
            isActive: currentRoute == '/settings',
            color: const Color(0xFF6B7280),
            onTap: () {
              Navigator.pop(context); // Close drawer
              // Navigate to settings screen
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
    required Color color,
    String? badge,
    Color? badgeColor,
    int? notificationCount,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {
            Navigator.pop(context);
            Navigator.pushNamed(context, route);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Left indicator
                Container(
                  width: 6,
                  height: 24,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isActive ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                
                // Icon
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isActive ? color : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        icon,
                        size: 16,
                        color: isActive ? Colors.white : color,
                      ),
                    ),
                    
                    // Notification badge on icon
                    if (notificationCount != null && notificationCount > 0)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
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
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(width: 8),
                
                // Label
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isActive ? color : Colors.grey.shade800,
                    ),
                  ),
                ),
                
                // Badge (NEW/BETA)
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: badgeColor == Colors.pink
                            ? [Colors.pink.shade500, Colors.red.shade400]
                            : [Colors.orange.shade500, Colors.amber.shade500],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                
                // Notification count badge
                if (notificationCount != null && notificationCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      notificationCount.toString(),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
