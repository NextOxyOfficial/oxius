import 'package:flutter/material.dart';
import '../login_prompt_dialog.dart';

/// Business network bottom navigation — standard social-app anatomy:
/// solid white bar with a hairline top border, ONE accent color (active
/// items), outlined→filled icon pairs, and a solid center create button.
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

  static const Color _accent = Color(0xFF2563EB);
  static const Color _inactive = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: isLoggedIn
                ? _buildLoggedInNav(context)
                : _buildLoggedOutNav(context),
          ),
        ),
      ),
    );
  }

  // Logged IN users: Recent | Notifications | Create Post | Profile | AdsyClub
  List<Widget> _buildLoggedInNav(BuildContext context) {
    return [
      _buildNavItem(
        context,
        index: 0,
        icon: Icons.schedule_outlined,
        activeIcon: Icons.schedule_rounded,
        label: 'Recent',
        isActive: currentIndex == 0,
      ),
      _buildNavItem(
        context,
        index: 1,
        icon: Icons.notifications_none_rounded,
        activeIcon: Icons.notifications_rounded,
        label: 'Notifications',
        isActive: currentIndex == 1,
        badge: unreadCount > 0 ? unreadCount : null,
      ),
      _buildCreateButton(context, enabled: true),
      _buildNavItem(
        context,
        index: 3,
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
        isActive: currentIndex == 3,
      ),
      _buildNavItem(
        context,
        index: 4,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'AdsyClub',
        isActive: currentIndex == 4,
        useFavicon: true,
      ),
    ];
  }

  // Logged OUT users: Recent | Login | Create Post (disabled) | Earn | AdsyClub
  List<Widget> _buildLoggedOutNav(BuildContext context) {
    return [
      _buildNavItem(
        context,
        index: 0,
        icon: Icons.schedule_outlined,
        activeIcon: Icons.schedule_rounded,
        label: 'Recent',
        isActive: currentIndex == 0,
      ),
      _buildNavItem(
        context,
        index: 1,
        icon: Icons.login_rounded,
        activeIcon: Icons.login_rounded,
        label: 'Login',
        isActive: currentIndex == 1,
      ),
      _buildCreateButton(context, enabled: false),
      _buildNavItem(
        context,
        index: 3,
        icon: Icons.attach_money_rounded,
        activeIcon: Icons.attach_money_rounded,
        label: 'Earn',
        isActive: currentIndex == 3,
      ),
      _buildNavItem(
        context,
        index: 4,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'AdsyClub',
        isActive: currentIndex == 4,
        useFavicon: true,
      ),
    ];
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    int? badge,
    bool useFavicon = false,
  }) {
    final color = isActive ? _accent : _inactive;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                useFavicon
                    ? Image.asset(
                        'assets/images/favicon.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(isActive ? activeIcon : icon,
                              size: 24, color: color);
                        },
                      )
                    : Icon(isActive ? activeIcon : icon,
                        size: 24, color: color),
                if (badge != null && badge > 0)
                  Positioned(
                    top: -4,
                    right: -7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(
                        badge > 99 ? '99+' : badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context, {required bool enabled}) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled
            ? () => onTap(2)
            : () => LoginPromptDialog.show(
                  context,
                  action: 'create posts',
                  icon: Icons.edit_note_rounded,
                ),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: enabled ? _accent : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.add_rounded,
              color: enabled ? Colors.white : const Color(0xFF94A3B8),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
