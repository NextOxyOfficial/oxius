import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import '../../services/rideshare_service.dart';
import '../../widgets/common/adsy_toast.dart';
import '../settings_screen.dart';
import 'rideshare_history_screen.dart';

/// The rider's account page from the design: face, name, phone, the two
/// stat cards, then the plain menu list.
///
/// Reached from the avatar floating over the map. Every row goes somewhere
/// real — a menu that opens "coming soon" is worse than no menu, so the two
/// rows this app has no destination for (Payment Method, Refer) route to the
/// places that DO handle those things.
class RideshareAccountScreen extends StatefulWidget {
  /// Saved Places lives inside the passenger panel's sheet, so the shell
  /// hands us the opener rather than us reaching across screens.
  final VoidCallback? onOpenSavedPlaces;

  const RideshareAccountScreen({super.key, this.onOpenSavedPlaces});

  @override
  State<RideshareAccountScreen> createState() => _RideshareAccountScreenState();
}

class _RideshareAccountScreenState extends State<RideshareAccountScreen> {
  double _rating = 0;
  int _ratingCount = 0;
  int _completedTrips = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  /// The two stat cards show REAL numbers: the rider's own driver rating when
  /// they also drive, and their completed-trip count. A hardcoded 4.82 would
  /// look like the mockup and mean nothing.
  Future<void> _loadStats() async {
    final rides = await RideshareService.listRides(pageSize: 50);
    if (!mounted) return;
    final completed = (rides.data ?? const [])
        .where((r) => r.status == 'completed')
        .length;

    double rating = 0;
    int count = 0;
    final profile = await RideshareService.getDriverProfile();
    if (profile.success && profile.data != null) {
      rating = profile.data!.ratingAverage;
      count = profile.data!.ratingCount;
    }

    if (!mounted) return;
    setState(() {
      _completedTrips = completed;
      _rating = rating;
      _ratingCount = count;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final name = [user?.firstName, user?.lastName]
        .where((p) => p != null && p.trim().isNotEmpty)
        .join(' ')
        .trim();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header: back chevron + centred title, exactly the design's bar.
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: Color(0xFF0F172A)),
                  ),
                  Expanded(
                    child: Text(
                      'Account',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  const SizedBox(height: 8),
                  Center(child: _buildAvatar(user?.profilePicture ?? '')),
                  const SizedBox(height: 12),
                  Text(
                    name.isNotEmpty ? name : (user?.username ?? 'Rider'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.phone ?? '',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // The two stat cards.
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Rating',
                          value: _loading
                              ? '—'
                              : (_ratingCount > 0
                                  ? _rating.toStringAsFixed(2)
                                  : 'New'),
                          leading: const Icon(Icons.star_rounded,
                              size: 15, color: Color(0xFFF59E0B)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Trips',
                          value: _loading ? '—' : '$_completedTrips',
                          leading: const Icon(Icons.route_rounded,
                              size: 15, color: Color(0xFF6366F1)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  _MenuRow(
                    icon: Icons.notifications_rounded,
                    label: 'Notifications',
                    onTap: () => Navigator.pushNamed(context, '/inbox'),
                  ),
                  _MenuRow(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  _MenuRow(
                    icon: Icons.star_rounded,
                    label: 'Saved Places',
                    onTap: () {
                      Navigator.of(context).maybePop();
                      widget.onOpenSavedPlaces?.call();
                    },
                  ),
                  _MenuRow(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Payment Method',
                    // Rides are paid from the AdsyPay wallet, so that is what
                    // "payment method" means here.
                    onTap: () =>
                        Navigator.pushNamed(context, '/deposit-withdraw'),
                  ),
                  _MenuRow(
                    icon: Icons.directions_car_rounded,
                    label: 'My Trips',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RideshareHistoryScreen()),
                    ),
                  ),
                  _MenuRow(
                    icon: Icons.card_giftcard_rounded,
                    label: 'Refer & Get Discount',
                    onTap: () =>
                        Navigator.pushNamed(context, '/refer-a-friend'),
                  ),
                  _MenuRow(
                    icon: Icons.logout_rounded,
                    label: 'Log Out',
                    danger: true,
                    onTap: _confirmLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String url) {
    const size = 86.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFF1F5F9), width: 3),
      ),
      child: ClipOval(
        child: url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _AvatarFallback(),
              )
            : const _AvatarFallback(),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('লগ আউট করবেন?',
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('আবার ব্যবহার করতে লগ ইন করতে হবে।',
            style: GoogleFonts.inter(fontSize: 13.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('লগ আউট',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await AuthService.logout();
    if (!mounted) return;
    AdsyToast.success(context, 'লগ আউট হয়েছে');
    Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Widget leading;

  const _StatCard({
    required this.label,
    required this.value,
    required this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9EDF3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        danger ? const Color(0xFFEF4444) : const Color(0xFF0F172A);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: danger
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            if (!danger)
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFF1F5F9),
        child: const Icon(Icons.person_rounded,
            size: 40, color: Color(0xFF94A3B8)),
      );
}
