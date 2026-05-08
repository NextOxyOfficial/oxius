import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum RideshareTab { passenger, driver, vehicles, history }

class RideshareBottomNav extends StatelessWidget {
  final RideshareTab activeTab;
  final String mode; // 'passenger' or 'driver' — used for history route
  final ValueChanged<RideshareTab>? onTabChange;

  const RideshareBottomNav({
    super.key,
    required this.activeTab,
    this.mode = 'passenger',
    this.onTabChange,
  });

  static const Color _purple = Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _TabData(
        tab: RideshareTab.passenger,
        icon: Icons.person_rounded,
        label: 'Passenger',
      ),
      _TabData(
        tab: RideshareTab.driver,
        icon: Icons.badge_rounded,
        label: 'Driver',
      ),
      _TabData(
        tab: RideshareTab.vehicles,
        icon: Icons.two_wheeler_rounded,
        label: 'Vehicles',
      ),
      _TabData(
        tab: RideshareTab.history,
        icon: Icons.history_rounded,
        label: 'History',
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: _purple.withValues(alpha: 0.14),
              blurRadius: 28,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: tabs.map((t) => Expanded(
              child: _buildTab(context, t),
            )).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, _TabData data) {
    final isActive = activeTab == data.tab;
    return GestureDetector(
      onTap: () => _handleTap(context, data.tab),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            data.icon,
            size: 22,
            color: isActive ? _purple : const Color(0xFFB0B8CC),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              color: isActive ? _purple : const Color(0xFFB0B8CC),
            ),
            child: Text(data.label),
          ),
          const SizedBox(height: 2),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: isActive ? 18 : 0,
            decoration: BoxDecoration(
              color: _purple,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, RideshareTab tab) {
    if (tab == activeTab) return;

    // If a custom handler is provided (used in RideshareScreen), call it
    if (onTabChange != null) {
      onTabChange!(tab);
      return;
    }

    // Default navigation from sub-screens (Vehicles / History)
    switch (tab) {
      case RideshareTab.passenger:
        Navigator.pop(context);
        break;
      case RideshareTab.driver:
        Navigator.pop(context);
        break;
      case RideshareTab.vehicles:
        Navigator.pushReplacementNamed(context, '/rideshare/vehicles');
        break;
      case RideshareTab.history:
        Navigator.pushReplacementNamed(
          context,
          mode == 'driver' ? '/rideshare/driver-history' : '/rideshare/history',
        );
        break;
    }
  }
}

class _TabData {
  final RideshareTab tab;
  final IconData icon;
  final String label;
  const _TabData({required this.tab, required this.icon, required this.label});
}
