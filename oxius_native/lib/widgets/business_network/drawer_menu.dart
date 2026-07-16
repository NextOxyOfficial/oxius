import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/fcm_service.dart';
import '../../screens/business_network/create_post_screen.dart';
import '../../screens/business_network/profile_screen.dart';
import '../../screens/business_network/notifications_screen.dart';
import '../../screens/business_network/mindforce_screen.dart';
import '../../screens/workspace/workspace_screen.dart';

class DrawerMenu extends StatelessWidget {
  final String? currentRoute;

  const DrawerMenu({
    super.key,
    this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Create Post Button (only for logged-in users)
        if (user != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 6),
            child: Material(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatePostScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 15, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Create Post',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],

        // Menu Items
        _buildItem(
          context,
          icon: Icons.bolt_rounded,
          label: 'Recent',
          isActive: currentRoute == '/business-network',
          onTap: () {
            Navigator.pop(context);
            final rootNavigator =
                FCMService.navigatorKey.currentState ?? Navigator.of(context);
            rootNavigator.pushNamedAndRemoveUntil(
              '/business-network',
              (route) => route.isFirst,
            );
          },
        ),
        if (user != null)
          _buildItem(
            context,
            icon: Icons.person_rounded,
            label: 'Profile',
            isActive:
                currentRoute?.contains('/business-network/profile/') ?? false,
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
        _buildItem(
          context,
          icon: Icons.psychology_rounded,
          label: 'MindForce',
          isActive: currentRoute == '/business-network/mindforce',
          badge: 'NEW',
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
        _buildItem(
          context,
          icon: Icons.workspaces_rounded,
          label: 'Workspaces',
          isActive: currentRoute == '/business-network/workspaces',
          badge: 'NEW',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkspaceScreen(),
              ),
            );
          },
        ),
        _buildItem(
          context,
          icon: Icons.notifications_rounded,
          label: 'Notifications',
          isActive: currentRoute == '/business-network/notifications',
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
        _buildItem(
          context,
          icon: Icons.settings_rounded,
          label: 'Settings',
          isActive: currentRoute == '/settings',
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/settings');
          },
        ),
      ],
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    String? badge,
  }) {
    // Single neutral treatment: dark icon + label normally, a subtle
    // light-slate highlight with a brand-blue icon/label when active.
    const brand = Color(0xFF2563EB);
    const neutral = Color(0xFF334155);
    final foreground = isActive ? brand : neutral;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFF1F5F9) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: foreground,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
