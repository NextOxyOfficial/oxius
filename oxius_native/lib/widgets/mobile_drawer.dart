import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:oxius_native/utils/app_fonts.dart';
import '../services/translation_service.dart';
import '../screens/settings_screen.dart';
import 'ios_web_redirect_screen.dart';
import 'ads/advertise_button.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

class MobileDrawer extends StatefulWidget {
  const MobileDrawer({super.key});

  @override
  State<MobileDrawer> createState() => _MobileDrawerState();
}

class _MobileDrawerState extends State<MobileDrawer> {
  final TranslationService _translationService = TranslationService();
  bool _isInitialized = false;

  // Official social link — update here if the page handle changes.
  static const String _facebookUrl = 'https://www.facebook.com/adsyclub';

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
      AdsyToast.success(context,
          'Language changed to ${languageInfo?['native_name'] ?? languageCode}');
    } else if (mounted) {
      AdsyToast.error(context, 'Failed to change language');
    }
  }

  Future<void> _openFacebook() async {
    final uri = Uri.parse(_facebookUrl);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        AdsyToast.error(context, 'Facebook পেজ খোলা যায়নি');
      }
    } catch (_) {
      if (mounted) {
        AdsyToast.error(context, 'Facebook পেজ খোলা যায়নি');
      }
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
                      style: AppFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              ..._translationService.availableLanguages
                  .map((language) => ListTile(
                        leading: Text(
                          language['flag'] ?? '🌐',
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          language['native_name'] ??
                              language['name'] ??
                              language['code'],
                          style: AppFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _translationService.currentLanguage ==
                                    language['code']
                                ? const Color(0xFF10B981)
                                : Colors.grey.shade700,
                          ),
                        ),
                        trailing: _translationService.currentLanguage ==
                                language['code']
                            ? const Icon(Icons.check, color: Color(0xFF10B981))
                            : null,
                        onTap: () {
                          _changeLanguage(language['code']);
                          Navigator.pop(context);
                        },
                      )),
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
          child: AdsyLoadingIndicator(
            color: Color(0xFF10B981),
          ),
        ),
      );
    }
    return Drawer(
      width: 288,
      backgroundColor: const Color(0xFFFAFAFA),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand header — official AdsyClub logo
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 38,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Text(
                      'AdsyClub',
                      style: AppFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded,
                        color: Colors.grey.shade500, size: 22),
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Language switcher
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GestureDetector(
                onTap: () => _showLanguageSelector(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFECECEC)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.language,
                          color: Colors.grey.shade600, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _translationService.t('language', fallback: 'Language'),
                        style: AppFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      Builder(
                        builder: (context) {
                          final currentLang =
                              _translationService.getLanguageInfo(
                                  _translationService.currentLanguage);
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currentLang?['flag'] ?? '🌐',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _translationService.currentLanguage
                                    .toUpperCase(),
                                style: AppFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down,
                                  color: Color(0xFF059669), size: 16),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Advertise on AdsyClub — borderless, soft-tinted button. Opens the
            // web ads panel in an in-app browser tab.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AdvertiseButton(
                label: _translationService.t(
                    'advertise_on_adsyclub', fallback: 'AdsyClub-এ বিজ্ঞাপন দিন'),
              ),
            ),

            const SizedBox(height: 8),

            // Grouped menu
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                children: [
                  _sectionLabel(
                      _translationService.t('menu', fallback: 'মূল মেনু')),
                  _buildDrawerItem(
                    context: context,
                    title: _translationService.t('home', fallback: 'হোম'),
                    icon: Icons.home_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/');
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    title: _translationService.t('classified_service',
                        fallback: 'আমার সেবা'),
                    icon: Icons.design_services_rounded,
                    iconColor: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(
                        context,
                        '/',
                        arguments: const {'scrollTo': 'classified'},
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    title: _translationService.t('eshop', fallback: 'ই-শপ'),
                    icon: Icons.storefront_rounded,
                    iconColor: const Color(0xFF6366F1),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/eshop');
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    title: _translationService.t('food_zone',
                        fallback: 'ফুড জোন'),
                    icon: Icons.restaurant_rounded,
                    iconColor: const Color(0xFFEC4899),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/food-zone');
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    title: _translationService.t('classified',
                        fallback: 'কেনাবেচা'),
                    icon: Icons.sell_rounded,
                    iconColor: const Color(0xFF0EA5E9),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/classified');
                    },
                  ),

                  _sectionLabel(_translationService.t('drawer_earn_learn',
                      fallback: 'আয় ও শেখা')),
                  _buildDrawerItem(
                    context: context,
                    title: _translationService.t('earn_money',
                        fallback: 'টাকা উপার্জন'),
                    icon: Icons.payments_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/micro-gigs');
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    title: _translationService.t('elearning',
                        fallback: 'ই-লার্নিং'),
                    icon: Icons.school_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/courses');
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    title: _translationService.t('mobile_recharge',
                        fallback: 'মোবাইল রিচার্জ'),
                    icon: Icons.smartphone_rounded,
                    iconColor: const Color(0xFF14B8A6),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/mobile-recharge');
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    title: _translationService.t('rideshare',
                        fallback: 'রাইড শেয়ার'),
                    icon: Icons.directions_car_rounded,
                    iconColor: const Color(0xFF0891B2),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/rideshare');
                    },
                  ),

                  _sectionLabel(_translationService.t('drawer_community',
                      fallback: 'কমিউনিটি')),
                  _buildDrawerItem(
                    context: context,
                    title: _translationService.t('business_network',
                        fallback: 'বিজনেস নেটওয়ার্ক'),
                    icon: Icons.hub_rounded,
                    iconColor: const Color(0xFF06B6D4),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/business-network');
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    title: _translationService.t('adsy_news', fallback: 'নিউজ'),
                    icon: Icons.newspaper_rounded,
                    iconColor: const Color(0xFFF97316),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/adsy-news');
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    title: _translationService.t('refer_program',
                        fallback: 'রেফারেল প্রোগ্রাম'),
                    icon: Icons.card_giftcard_rounded,
                    iconColor: const Color(0xFFD946EF),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/refer-a-friend');
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    title: _translationService.t('faq', fallback: 'প্রশ্নোত্তর'),
                    icon: Icons.help_outline_rounded,
                    iconColor: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/faq');
                    },
                  ),

                  _sectionLabel(_translationService.t('drawer_account',
                      fallback: 'অ্যাকাউন্ট')),
                  if (!isIOSPlatform)
                    _buildDrawerItem(
                      context: context,
                      title: _translationService.t('upgrade_pro',
                          fallback: 'প্রো প্যাকেজ নিই'),
                      icon: Icons.workspace_premium_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      badge: 'PRO',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/upgrade-to-pro');
                      },
                    ),
                  _buildDrawerItem(
                    context: context,
                    title:
                        _translationService.t('settings', fallback: 'সেটিংস'),
                    icon: Icons.settings_rounded,
                    iconColor: const Color(0xFF64748B),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    title: _translationService.t('support',
                        fallback: 'সাপোর্ট'),
                    icon: Icons.support_agent_rounded,
                    iconColor: const Color(0xFF64748B),
                    onTap: () {
                      Navigator.pop(context);
                      // Help center (FAQ), not the AdsyConnect support tab.
                      Navigator.pushNamed(context, '/faq');
                    },
                  ),
                ],
              ),
            ),

            // Footer — follow us
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: const BoxDecoration(
                border:
                    Border(top: BorderSide(color: Color(0xFFECECEC), width: 1)),
              ),
              child: Row(
                children: [
                  Text(
                    _translationService.t('follow_us', fallback: 'ফলো করুন'),
                    style: AppFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _openFacebook,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1877F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.facebook,
                          color: Colors.white, size: 17),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'v1.0',
                    style: AppFonts.roboto(
                      fontSize: 11,
                      color: Colors.grey.shade400,
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

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
      child: Text(
        text.toUpperCase(),
        style: AppFonts.roboto(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade400,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  // Drawer item — neutral dark title with a tinted icon chip.
  Widget _buildDrawerItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppFonts.roboto(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: AppFonts.roboto(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFB45309),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey.shade300, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
