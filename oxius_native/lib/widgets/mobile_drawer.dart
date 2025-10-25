import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/translation_service.dart';
import '../screens/settings_screen.dart';

class MobileDrawer extends StatefulWidget {
  const MobileDrawer({super.key});

  @override
  State<MobileDrawer> createState() => _MobileDrawerState();
}

class _MobileDrawerState extends State<MobileDrawer> {
  final TranslationService _translationService = TranslationService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeTranslations();
  }

  Future<void> _initializeTranslations() async {
    await _translationService.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    final success = await _translationService.changeLanguage(languageCode);
    
    if (success && mounted) {
      setState(() {});
      
      final languageInfo = _translationService.getLanguageInfo(languageCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language changed to ${languageInfo?['native_name'] ?? languageCode}'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to change language'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                      _translationService.t('language', fallback: 'Language'),
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              ..._translationService.availableLanguages.map((language) => ListTile(
                leading: Text(
                  language['flag'] ?? '🌐',
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  language['native_name'] ?? language['name'] ?? language['code'],
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _translationService.currentLanguage == language['code'] 
                        ? const Color(0xFF10B981) 
                        : Colors.grey.shade700,
                  ),
                ),
                trailing: _translationService.currentLanguage == language['code']
                    ? const Icon(Icons.check, color: Color(0xFF10B981))
                    : null,
                onTap: () {
                  _changeLanguage(language['code']);
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
    if (!_isInitialized) {
      return const Drawer(
        backgroundColor: Colors.white,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF10B981),
          ),
        ),
      );
    }
    return Drawer(
      width: 280,
      backgroundColor: const Color(0xFFFAFAFA),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Interactive Language Switcher Section
            GestureDetector(
              onTap: () => _showLanguageSelector(context),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.language,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _translationService.t('language', fallback: 'Language'),
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    // Show current language flag and code
                    Builder(
                      builder: (context) {
                        final currentLang = _translationService.getLanguageInfo(_translationService.currentLanguage);
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentLang?['flag'] ?? '🌐',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _translationService.currentLanguage.toUpperCase(),
                                    style: GoogleFonts.roboto(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Color(0xFF10B981),
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.grey.shade300, height: 1),
            ),

            const SizedBox(height: 4),

            // Menu Items Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                _translationService.t('menu', fallback: 'Menu'),
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ),

            // Menu Items (matching Vue.js mobile navigation with dynamic translations)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    _buildDrawerItem(
                      context: context,
                      title: _translationService.t('home', fallback: 'Home'),
                      icon: Icons.home,
                      iconColor: const Color(0xFF3B82F6),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/');
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: _translationService.t('classified_service', fallback: 'Classified Service'),
                      icon: Icons.list_alt,
                      iconColor: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/');
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: _translationService.t('elearning', fallback: 'E-Learning'),
                      icon: Icons.school,
                      iconColor: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/courses');
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: _translationService.t('earn_money', fallback: 'Earn Money'),
                      icon: Icons.monetization_on,
                      iconColor: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/');
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: _translationService.t('faq', fallback: 'FAQ'),
                      icon: Icons.help_outline,
                      iconColor: const Color(0xFFEF4444),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/faq');
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: _translationService.t('business_network', fallback: 'Business Network'),
                      icon: Icons.network_check,
                      iconColor: const Color(0xFF06B6D4),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/business-network');
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: _translationService.t('adsy_news', fallback: 'News'),
                      icon: Icons.newspaper,
                      iconColor: const Color(0xFFF97316),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/adsy-news');
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: _translationService.t('refer_program', fallback: 'Referral Program'),
                      icon: Icons.share,
                      iconColor: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/refer-a-friend');
                      },
                    ),

                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      child: Divider(height: 1, color: Colors.grey.shade300),
                    ),

                    _buildDrawerItem(
                      context: context,
                      title: _translationService.t('upgrade_to_pro', fallback: 'Upgrade to Pro'),
                      icon: Icons.star,
                      iconColor: const Color(0xFFFBBF24),
                      badge: 'PRO',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/upgrade-to-pro');
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: _translationService.t('settings', fallback: 'Settings'),
                      icon: Icons.settings,
                      iconColor: Colors.grey.shade600,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context: context,
                      title: _translationService.t('support', fallback: 'Help & Support'),
                      icon: Icons.support_agent,
                      iconColor: Colors.grey.shade600,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/support');
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Social Media Section with dynamic translations
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Text(
                    _translationService.t('follow_us', fallback: 'Follow Us'),
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1877F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.facebook,
                        color: Colors.white,
                        size: 16,
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
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: ListTile(
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 16,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: iconColor,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [iconColor, iconColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.roboto(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: iconColor.withOpacity(0.5),
            size: 16,
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          minLeadingWidth: 32,
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}