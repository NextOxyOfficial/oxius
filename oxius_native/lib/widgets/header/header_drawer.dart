import 'package:flutter/material.dart';

/// Mobile Drawer Menu
class HeaderDrawer extends StatelessWidget {
  const HeaderDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 300,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade50,
              Colors.grey.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Close Button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: const EdgeInsets.all(16),
                ),
              ),
              
              // Menu Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Menu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Navigation Items
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
                        context,
                        icon: Icons.home,
                        label: 'Home',
                        route: '/',
                        color: const Color(0xFF3B82F6),
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.list_alt,
                        label: 'Classified Service',
                        route: '/#classified-services',
                        color: const Color(0xFF10B981),
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.school,
                        label: 'E-Learning',
                        route: '/courses',
                        color: const Color(0xFF8B5CF6),
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.attach_money,
                        label: 'Earn Money',
                        route: '/#micro-gigs',
                        color: const Color(0xFFF59E0B),
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.help_outline,
                        label: 'FAQ',
                        route: '/faq',
                        color: const Color(0xFFEF4444),
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.public,
                        label: 'Business Network',
                        route: '/business-network',
                        color: const Color(0xFF14B8A6),
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.newspaper,
                        label: 'News',
                        route: '/adsy-news',
                        color: const Color(0xFFF97316),
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.person_add,
                        label: 'Refer a Friend',
                        route: '/refer-a-friend',
                        color: const Color(0xFFEC4899),
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.phone_android,
                        label: 'Mobile Recharge',
                        route: '/mobile-recharge',
                        color: const Color(0xFF6366F1),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Download App Section
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Download Our App',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'Google Play',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Coming Soon',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: color.withOpacity(0.5),
      ),
      onTap: () {
        Navigator.pop(context);
        if (route == '/#classified-services') {
          Navigator.pushReplacementNamed(
            context,
            '/',
            arguments: const {'scrollTo': 'classified'},
          );
          return;
        }
        if (route == '/#micro-gigs') {
          Navigator.pushNamed(context, '/micro-gigs');
          return;
        }
        Navigator.pushNamed(context, route);
      },
    );
  }
}
