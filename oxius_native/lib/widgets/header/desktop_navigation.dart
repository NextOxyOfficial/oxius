import 'package:flutter/material.dart';

/// Desktop Navigation Menu
class DesktopNavigation extends StatelessWidget {
  const DesktopNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildNavItem(
          context,
          icon: Icons.home,
          label: 'Home',
          route: '/',
          color: const Color(0xFF3B82F6),
        ),
        _buildNavItem(
          context,
          icon: Icons.public,
          label: 'Business Network',
          route: '/business-network',
          color: const Color(0xFF10B981),
        ),
        _buildNavItem(
          context,
          icon: Icons.newspaper,
          label: 'News',
          route: '/adsy-news',
          color: const Color(0xFFF59E0B),
        ),
        _buildNavItem(
          context,
          icon: Icons.school,
          label: 'E-Learning',
          route: '/courses',
          color: const Color(0xFF8B5CF6),
        ),
        _buildNavItem(
          context,
          icon: Icons.attach_money,
          label: 'Earn Money',
          route: '/#micro-gigs',
          color: const Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required Color color,
  }) {
    final isActive = ModalRoute.of(context)?.settings.name == route;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? color : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
