import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MobileDrawer extends StatelessWidget {
  const MobileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer Header (matching Vue.js mobile drawer header)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF10B981),
                    Color(0xFF059669),
                  ],
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          'AdsyClub',
                          style: GoogleFonts.roboto(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Language Switcher Section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.language,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Language',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'EN',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: Colors.grey.shade200, height: 1),
            ),

            const SizedBox(height: 8),

            // Menu Items Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                'Menu',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),

            // Menu Items (matching Vue.js mobile navigation)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildDrawerItem(
                      context: context,
                      title: 'Home',
                      icon: Icons.home,
                      iconColor: const Color(0xFF3B82F6),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Navigate to Home'),
                            backgroundColor: Color(0xFF3B82F6),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: 'Classified Service',
                      icon: Icons.list_alt,
                      iconColor: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Classified Service coming soon!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: 'E-Learning',
                      icon: Icons.school,
                      iconColor: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('E-Learning coming soon!'),
                            backgroundColor: Color(0xFF8B5CF6),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: 'Earn Money',
                      icon: Icons.monetization_on,
                      iconColor: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Earn Money coming soon!'),
                            backgroundColor: Color(0xFFF59E0B),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: 'FAQ',
                      icon: Icons.help_outline,
                      iconColor: const Color(0xFFEF4444),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('FAQ coming soon!'),
                            backgroundColor: Color(0xFFEF4444),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: 'Business Network',
                      icon: Icons.network_check,
                      iconColor: const Color(0xFF06B6D4),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Business Network coming soon!'),
                            backgroundColor: Color(0xFF06B6D4),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: 'News',
                      icon: Icons.newspaper,
                      iconColor: const Color(0xFFF97316),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('News coming soon!'),
                            backgroundColor: Color(0xFFF97316),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: 'Referral Program',
                      icon: Icons.share,
                      iconColor: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Referral Program coming soon!'),
                            backgroundColor: Color(0xFF8B5CF6),
                          ),
                        );
                      },
                    ),

                    // Divider
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Divider(height: 1),
                    ),

                    _buildDrawerItem(
                      context: context,
                      title: 'Settings',
                      icon: Icons.settings,
                      iconColor: Colors.grey.shade600,
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Settings coming soon!'),
                            backgroundColor: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: 'Help & Support',
                      icon: Icons.support_agent,
                      iconColor: Colors.grey.shade600,
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Help & Support coming soon!'),
                            backgroundColor: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Download App Section (matching Vue.js mobile popup)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF10B981),
                    Color(0xFF3B82F6),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_android,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Get Our Mobile App!',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Experience AdsyClub on the go',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              'Google Play',
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              'Coming Soon',
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Social Media Section (matching Vue.js)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Text(
                    'Follow Us',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opening Facebook page...'),
                          backgroundColor: Color(0xFF1877F2),
                        ),
                      );
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1877F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.facebook,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build drawer items (matching Vue.js design)
  Widget _buildDrawerItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: iconColor,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: iconColor.withOpacity(0.5),
            size: 18,
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          minLeadingWidth: 40,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}