import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/translation_service.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

/// Shared sidebar drawer for all Rideshare screens.
///
/// [activeTab] — one of: 'passenger', 'driver', 'vehicles', 'history'
/// [onModeSelected] — called when Passenger / Driver tile tapped (main screen only)
/// [onOpenCustomLocation] — called when Custom Location tapped (main screen only)
class RideshareDrawer extends StatelessWidget {
  final String activeTab;
  final void Function(String mode)? onModeSelected;
  final VoidCallback? onOpenCustomLocation;

  const RideshareDrawer({
    super.key,
    required this.activeTab,
    this.onModeSelected,
    this.onOpenCustomLocation,
  });

  String _t(String key, {required String fallback}) =>
      TranslationService().t(key, fallback: fallback);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_car_filled_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('rideshare_title', fallback: 'Ride Share'),
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                      Text(
                        _t('rideshare_subtitle', fallback: 'Book a ride or drive'),
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Nav items ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tile(
                      context,
                      icon: Icons.person_rounded,
                      label: _t('rideshare_tab_passenger', fallback: 'Passenger'),
                      isActive: activeTab == 'passenger',
                      onTap: () {
                        Navigator.pop(context);
                        if (onModeSelected != null) {
                          onModeSelected!('passenger');
                        } else {
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/rideshare', (r) => r.isFirst);
                        }
                      },
                    ),
                    _tile(
                      context,
                      icon: Icons.badge_rounded,
                      label: _t('rideshare_tab_driver', fallback: 'Driver'),
                      isActive: activeTab == 'driver',
                      onTap: () {
                        Navigator.pop(context);
                        if (onModeSelected != null) {
                          onModeSelected!('driver');
                        } else {
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/rideshare', (r) => r.isFirst,
                              arguments: {'mode': 'driver'});
                        }
                      },
                    ),
                    _tile(
                      context,
                      icon: Icons.two_wheeler_rounded,
                      label: _t('rideshare_tab_vehicles', fallback: 'My Vehicles'),
                      isActive: activeTab == 'vehicles',
                      onTap: () {
                        Navigator.pop(context);
                        if (activeTab != 'vehicles') {
                          Navigator.pushNamed(context, '/rideshare/vehicles');
                        }
                      },
                    ),
                    _tile(
                      context,
                      icon: Icons.history_rounded,
                      label: _t('rideshare_tab_history', fallback: 'Ride History'),
                      isActive: activeTab == 'history',
                      onTap: () {
                        Navigator.pop(context);
                        if (activeTab != 'history') {
                          Navigator.pushNamed(context, '/rideshare/history');
                        }
                      },
                    ),
                    if (onOpenCustomLocation != null)
                      _tile(
                        context,
                        icon: Icons.bookmark_add_rounded,
                        label: 'Custom Location',
                        onTap: () {
                          Navigator.pop(context);
                          Future.delayed(const Duration(milliseconds: 250), () {
                            onOpenCustomLocation!();
                          });
                        },
                      ),

                    const SizedBox(height: 8),
                    Divider(color: const Color(0xFFE2E8F0), height: 1),
                    const SizedBox(height: 8),

                    // ── Support section ───────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        'সাপোর্ট',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 0.6),
                      ),
                    ),
                    _tile(
                      context,
                      icon: Icons.phone_rounded,
                      label: '+8801896144066',
                      sublabel: 'Support Helpline',
                      iconBg: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF16A34A),
                      onTap: () => launchUrl(Uri.parse('tel:+8801896144066')),
                    ),
                    _tile(
                      context,
                      icon: Icons.email_rounded,
                      label: 'support@adsyclub.com',
                      sublabel: 'Email Support',
                      iconBg: const Color(0xFFEDE9FE),
                      iconColor: const Color(0xFF7C3AED),
                      onTap: () =>
                          launchUrl(Uri.parse('mailto:support@adsyclub.com')),
                    ),
                    _tile(
                      context,
                      icon: Icons.flag_rounded,
                      label: 'Report an Issue',
                      sublabel: 'Submit a problem',
                      iconBg: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFD97706),
                      onTap: () {
                        Navigator.pop(context);
                        _showReportIssueSheet(context);
                      },
                    ),

                    const SizedBox(height: 8),
                    Divider(color: const Color(0xFFE2E8F0), height: 1),
                    const SizedBox(height: 8),

                    // ── Emergency ─────────────────────────────────────
                    GestureDetector(
                      onTap: () => launchUrl(Uri.parse('tel:999')),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.emergency_rounded,
                                  size: 18, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('কল ৯৯৯',
                                    style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFDC2626))),
                                Text('জরুরি সেবা',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFFEF4444))),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right_rounded,
                                color: Color(0xFFEF4444), size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? sublabel,
    bool isActive = false,
    Color? iconBg,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    final bg = iconBg ??
        (isActive ? const Color(0xFF6366F1) : const Color(0xFFF1F5F9));
    final ic =
        iconColor ?? (isActive ? Colors.white : const Color(0xFF64748B));
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF6366F1).withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
              color: isActive
                  ? const Color(0xFF6366F1).withValues(alpha: 0.25)
                  : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration:
                  BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 17, color: ic),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  if (sublabel != null)
                    Text(sublabel,
                        style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: const Color(0xFF94A3B8))),
                ],
              ),
            ),
            if (isActive)
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }

  static void _showReportIssueSheet(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.flag_rounded,
                        size: 18, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Report an Issue',
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B))),
                      Text('আপনার সমস্যা বর্ণনা করুন',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 5,
                autofocus: true,
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: 'সমস্যার বিবরণ লিখুন...',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFFB0B8CC)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF6366F1), width: 1.5)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    AdsyToast.success(context, 'আপনার রিপোর্ট পাঠানো হয়েছে।');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('সাবমিট করুন',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
