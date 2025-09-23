import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MobileDrawer extends StatefulWidget {
  const MobileDrawer({super.key});

  @override
  State<MobileDrawer> createState() => _MobileDrawerState();
}

class _MobileDrawerState extends State<MobileDrawer> {
  String _currentLanguage = 'en';

  // Language options with flags and native names (matching Vue.js structure)
  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'bn', 'name': 'বাংলা', 'flag': '🇧🇩'},
  ];

  // Translation function that dynamically pulls from i18n structure
  String t(String key) {
    final translations = {
      'en': {
        'welcome': 'Welcome to',
        'adsy_club': 'AdsyClub',
        'language': 'Language',
        'menu': 'Menu',
        'home': 'Home',
        'classified_service': 'My Services',
        'elearning': 'eLearning',
        'earn_money': 'Earn Money',
        'faq': 'FAQ',
        'business_network': 'Business Network',
        'adsy_news': 'Adsy News',
        'refer_program': 'Referral Program',
        'settings': 'Settings',
        'support': 'Help & Support',
        'download_app': 'Get Our Mobile App!',
        'app_experience': 'Experience AdsyClub on the go',
        'google_play': 'Google Play',
        'coming_soon': 'Coming Soon',
        'follow_us': 'Follow Us',
        'nav_to_home': 'Navigate to Home',
        'coming_soon_msg': 'coming soon!',
      },
      'bn': {
        'welcome': 'স্বাগতম',
        'adsy_club': 'অ্যাডজি ক্লাব',
        'language': 'ভাষা',
        'menu': 'মেনু',
        'home': 'হোম',
        'classified_service': 'আমার সেবা',
        'elearning': 'ই-লার্নিং',
        'earn_money': 'টাকা উপার্জন',
        'faq': 'প্রশ্নোত্তর',
        'business_network': 'বিজনেস নেটওয়ার্ক',
        'adsy_news': 'নিউজ',
        'refer_program': 'রেফারেল প্রোগ্রাম',
        'settings': 'সেটিংস্‌',
        'support': 'সাপোর্ট',
        'download_app': 'আমাদের মোবাইল অ্যাপ নিন!',
        'app_experience': 'যেকোনো জায়গায় AdsyClub ব্যবহার করুন',
        'google_play': 'গুগল প্লে',
        'coming_soon': 'আসছে শীঘ্রই',
        'follow_us': 'ফলো করুন',
        'nav_to_home': 'হোমে যান',
        'coming_soon_msg': 'আসছে শীঘ্রই!',
      }
    };

    return translations[_currentLanguage]?[key] ?? key;
  }

  void _changeLanguage(String languageCode) {
    setState(() {
      _currentLanguage = languageCode;
    });
    
    // Show feedback to user
    final languageName = _languages.firstWhere((lang) => lang['code'] == languageCode)['name'];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Language changed to $languageName'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Color(0xFF10B981)),
                    const SizedBox(width: 12),
                    Text(
                      t('language'),
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              ..._languages.map((language) => ListTile(
                leading: Text(
                  language['flag']!,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  language['name']!,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _currentLanguage == language['code'] 
                        ? const Color(0xFF10B981) 
                        : Colors.grey.shade700,
                  ),
                ),
                trailing: _currentLanguage == language['code']
                    ? const Icon(Icons.check, color: Color(0xFF10B981))
                    : null,
                onTap: () {
                  _changeLanguage(language['code']!);
                  Navigator.pop(context);
                },
              )).toList(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

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
                          t('welcome'),
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          t('adsy_club'),
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

            // Language Switcher Section (Interactive)
            GestureDetector(
              onTap: () => _showLanguageSelector(context),
              child: Container(
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
                      t('language'),
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _languages.firstWhere((lang) => lang['code'] == _currentLanguage)['flag']!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentLanguage.toUpperCase(),
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: const Color(0xFF10B981),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                t('menu'),
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
                      title: t('home'),
                      icon: Icons.home,
                      iconColor: const Color(0xFF3B82F6),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(t('nav_to_home')),
                            backgroundColor: const Color(0xFF3B82F6),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: t('classified_service'),
                      icon: Icons.list_alt,
                      iconColor: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${t('classified_service')} ${t('coming_soon_msg')}'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: t('elearning'),
                      icon: Icons.school,
                      iconColor: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${t('elearning')} ${t('coming_soon_msg')}'),
                            backgroundColor: const Color(0xFF8B5CF6),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: t('earn_money'),
                      icon: Icons.monetization_on,
                      iconColor: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${t('earn_money')} ${t('coming_soon_msg')}'),
                            backgroundColor: const Color(0xFFF59E0B),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: t('faq'),
                      icon: Icons.help_outline,
                      iconColor: const Color(0xFFEF4444),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${t('faq')} ${t('coming_soon_msg')}'),
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: t('business_network'),
                      icon: Icons.network_check,
                      iconColor: const Color(0xFF06B6D4),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${t('business_network')} ${t('coming_soon_msg')}'),
                            backgroundColor: const Color(0xFF06B6D4),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: t('adsy_news'),
                      icon: Icons.newspaper,
                      iconColor: const Color(0xFFF97316),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${t('adsy_news')} ${t('coming_soon_msg')}'),
                            backgroundColor: const Color(0xFFF97316),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: t('refer_program'),
                      icon: Icons.share,
                      iconColor: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${t('refer_program')} ${t('coming_soon_msg')}'),
                            backgroundColor: const Color(0xFF8B5CF6),
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
                      title: t('settings'),
                      icon: Icons.settings,
                      iconColor: Colors.grey.shade600,
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${t('settings')} ${t('coming_soon_msg')}'),
                            backgroundColor: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: t('support'),
                      icon: Icons.support_agent,
                      iconColor: Colors.grey.shade600,
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${t('support')} ${t('coming_soon_msg')}'),
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