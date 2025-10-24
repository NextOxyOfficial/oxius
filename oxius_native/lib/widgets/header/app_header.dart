import 'package:flutter/material.dart';
import 'header_logo.dart';
import 'header_actions.dart';
import 'header_drawer.dart';
import 'desktop_navigation.dart';

/// Main App Header - Mobile Responsive
/// Matches Vue.js header.vue design
class AppHeader extends StatefulWidget {
  const AppHeader({super.key});

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      decoration: BoxDecoration(
        color: isMobile 
            ? const Color(0xFFE2E8F0).withOpacity(0.7) 
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: (screenWidth * 0.015).clamp(4.0, 12.0),
            vertical: isMobile ? 4 : 10,
          ),
          child: Row(
            children: [
              // Mobile Menu Button + Logo
              Row(
                children: [
                  if (isMobile)
                    IconButton(
                      icon: const Icon(Icons.menu, size: 22),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 2),
                  const HeaderLogo(),
                ],
              ),
              
              // Desktop Navigation
              if (!isMobile) ...[
                const SizedBox(width: 16),
                const Expanded(child: DesktopNavigation()),
              ] else
                const Spacer(),
              
              // Header Actions (Inbox, QR, Profile)
              const HeaderActions(),
            ],
          ),
        ),
      ),
    );
  }
}
