import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/rideshare_models.dart';
import '../../services/auth_service.dart';
import '../../services/rideshare_service.dart';
import '../../widgets/common/adsy_loading.dart';
import '../../widgets/common/adsy_toast.dart';
import '../settings_screen.dart';
import 'rideshare_driver_apply_sheet.dart';
import 'rideshare_history_screen.dart';
import 'rideshare_mode.dart';
import 'rideshare_page_header.dart';
import 'rideshare_vehicles_screen.dart';
import '../../widgets/app_network_image.dart';
import '../../utils/app_fonts.dart';

/// The rideshare account page — and, since the sidebar drawer is gone, the
/// single place every rideshare destination now lives.
///
/// It has two faces. A rider sees their own details, their trips and the way
/// in to becoming a driver. An approved driver can flip a switch at the top
/// and see the driving side instead: vehicles, earnings, driver trips. The
/// switch is not decoration — it drives the map behind this page too, so
/// coming back lands on the right panel.
class RideshareAccountScreen extends StatefulWidget {
  /// Saved Places lives inside the passenger panel's sheet, so the shell
  /// hands us the opener rather than us reaching across screens.
  final VoidCallback? onOpenSavedPlaces;

  /// Which face to open on, and how to tell the shell it changed.
  final String initialMode;
  final ValueChanged<String>? onModeChanged;

  const RideshareAccountScreen({
    super.key,
    this.onOpenSavedPlaces,
    this.initialMode = 'passenger',
    this.onModeChanged,
  });

  @override
  State<RideshareAccountScreen> createState() => _RideshareAccountScreenState();
}

class _RideshareAccountScreenState extends State<RideshareAccountScreen> {
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF94A3B8);

  late String _mode = widget.initialMode;

  DriverProfile? _driver;
  DriverEarningsSummary? _earnings;
  double _riderRating = 0;
  int _riderRatingCount = 0;
  int _riderTrips = 0;
  bool _loading = true;
  bool _applying = false;

  bool get _isApprovedDriver => _driver?.isApproved == true;
  bool get _showingDriver => _mode == 'driver' && _isApprovedDriver;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Every number on this page is real. A hardcoded 4.82 would look like the
  /// design and tell the rider nothing.
  Future<void> _load() async {
    final rides = await RideshareService.listRides(pageSize: 50);
    final profile = await RideshareService.getDriverProfile();

    DriverEarningsSummary? earnings;
    if (profile.success && profile.data?.isApproved == true) {
      final result = await RideshareService.getDriverEarningsSummary();
      earnings = result.data;
    }

    if (!mounted) return;
    setState(() {
      _riderTrips = (rides.data ?? const <Ride>[])
          .where((r) => r.status == 'completed')
          .length;
      // A 404 here just means "not a driver yet", which is the normal case.
      _driver = profile.success ? profile.data : null;
      _riderRating = _driver?.ratingAverage ?? 0;
      _riderRatingCount = _driver?.ratingCount ?? 0;
      _earnings = earnings;
      _loading = false;
    });

    // Demote ONLY on a definitive server answer. getDriverProfile() also
    // returns success=false for timeouts and dead networks — flipping an
    // approved driver to passenger (and wiping their sticky choice) because
    // the connection blinked would strand them until a successful reload.
    if (profile.success &&
        profile.data?.isApproved != true &&
        _mode != RideshareMode.passenger) {
      setState(() => _mode = RideshareMode.passenger);
      await RideshareMode.clear();
      widget.onModeChanged?.call(RideshareMode.passenger);
    }
  }

  void _setMode(String mode) {
    if (_mode == mode) return;
    if (mode == RideshareMode.driver && !_isApprovedDriver) return;
    setState(() => _mode = mode);
    widget.onModeChanged?.call(mode);
    RideshareMode.save(mode);
    // The dashboard behind this page just changed, and it will stay changed
    // next time they open rideshare — that is worth saying out loud.
    AdsyToast.success(context, RideshareMode.switchMessage(mode));
  }

  Future<void> _openApplySheet() async {
    final applied = await RideshareDriverApplySheet.show(context);
    if (applied == null || !mounted) return;

    setState(() => _applying = true);
    final result = await RideshareService.applyAsDriver(
      licenseNumber: applied.licenseNumber,
      nationalIdNumber: applied.nationalIdNumber,
      driverDetails: applied.details,
    );
    if (!mounted) return;
    setState(() {
      _applying = false;
      if (result.success) _driver = result.data;
    });

    if (result.success) {
      AdsyToast.success(
          context, 'আবেদন জমা হয়েছে। এপ্রুভের জন্য অপেক্ষা করুন।');
    } else {
      AdsyToast.error(context,
          result.message.isNotEmpty ? result.message : 'আবেদন পাঠানো যায়নি');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const RidesharePageHeader(title: 'অ্যাকাউন্ট'),
            Expanded(
              child: _loading
                  ? const Center(child: AdsyLoadingIndicator())
                  : AdsyRefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                        children: _showingDriver
                            ? _buildDriverBody()
                            : _buildPassengerBody(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Passenger face ────────────────────────────────────────────────────────

  List<Widget> _buildPassengerBody() {
    final user = AuthService.currentUser;
    return [
      const SizedBox(height: 4),
      _buildIdentity(
        avatar: user?.profilePicture ?? '',
        name: _displayName(),
        phone: user?.phone ?? '',
        badge: _buildRoleBadge(),
      ),
      if (_isApprovedDriver) ...[
        const SizedBox(height: 16),
        _buildModeSwitch(),
      ],
      const SizedBox(height: 14),
      _buildStatStrip([
        _statItem(
          const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF59E0B)),
          _riderRatingCount > 0 ? _riderRating.toStringAsFixed(2) : 'নতুন',
          'রেটিং',
        ),
        _statItem(
          const Icon(Icons.route_rounded, size: 15, color: Color(0xFF6366F1)),
          '$_riderTrips',
          'ট্রিপ',
        ),
      ]),
      const SizedBox(height: 18),
      _SectionLabel('রাইড'),
      _MenuRow(
        icon: Icons.directions_car_rounded,
        label: 'আমার ট্রিপ',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RideshareHistoryScreen()),
        ),
      ),
      _MenuRow(
        icon: Icons.star_rounded,
        label: 'সেভ করা জায়গা',
        onTap: () {
          Navigator.of(context).maybePop();
          widget.onOpenSavedPlaces?.call();
        },
      ),
      _MenuRow(
        icon: Icons.account_balance_wallet_rounded,
        label: 'পেমেন্ট মেথড',
        // Rides are paid from the AdsyPay wallet, so that is what "payment
        // method" means here.
        onTap: () => Navigator.pushNamed(context, '/deposit-withdraw'),
      ),
      const SizedBox(height: 14),
      _SectionLabel('অ্যাকাউন্ট'),
      _MenuRow(
        icon: Icons.notifications_rounded,
        label: 'নোটিফিকেশন',
        onTap: () => Navigator.pushNamed(context, '/inbox'),
      ),
      _MenuRow(
        icon: Icons.settings_rounded,
        label: 'সেটিংস',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        ),
      ),
      _MenuRow(
        icon: Icons.card_giftcard_rounded,
        label: 'রেফার করে ডিসকাউন্ট নিন',
        onTap: () => Navigator.pushNamed(context, '/refer-a-friend'),
      ),
      const SizedBox(height: 14),
      ..._buildSupportSection(),
      const SizedBox(height: 18),
      _buildDriverCallToAction(),
      const SizedBox(height: 18),
      _MenuRow(
        icon: Icons.logout_rounded,
        label: 'লগ আউট',
        danger: true,
        onTap: _confirmLogout,
      ),
    ];
  }

  // ── Driver face ───────────────────────────────────────────────────────────

  List<Widget> _buildDriverBody() {
    final driver = _driver!;
    return [
      const SizedBox(height: 4),
      _buildIdentity(
        avatar:
            driver.userAvatar ?? AuthService.currentUser?.profilePicture ?? '',
        name: driver.userName.isNotEmpty ? driver.userName : _displayName(),
        phone: driver.userPhone,
        badge: _buildRoleBadge(),
      ),
      const SizedBox(height: 16),
      _buildModeSwitch(),
      const SizedBox(height: 14),
      _buildStatStrip([
        _statItem(
          const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF59E0B)),
          driver.ratingCount > 0
              ? driver.ratingAverage.toStringAsFixed(2)
              : 'নতুন',
          'রেটিং',
        ),
        _statItem(
          const Icon(Icons.route_rounded, size: 15, color: Color(0xFF6366F1)),
          '${_earnings?.totalTrips ?? driver.totalTrips}',
          'ট্রিপ',
        ),
        _statItem(
          const Icon(Icons.payments_rounded,
              size: 15, color: Color(0xFF059669)),
          '৳${(_earnings?.totalEarnings ?? driver.totalEarnings).toStringAsFixed(0)}',
          'আয়',
        ),
      ]),
      const SizedBox(height: 18),
      _SectionLabel('ড্রাইভিং'),
      _MenuRow(
        icon: Icons.two_wheeler_rounded,
        label: 'আমার গাড়ি',
        trailingText: driver.vehicles.isEmpty
            ? 'যোগ করুন'
            : '${driver.vehicles.length}টি',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RideshareVehiclesScreen()),
        ),
      ),
      _MenuRow(
        icon: Icons.history_rounded,
        label: 'ড্রাইভার ট্রিপ',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const RideshareHistoryScreen(asDriver: true)),
        ),
      ),
      _MenuRow(
        icon: Icons.account_balance_wallet_rounded,
        label: 'আয় ও পেমেন্ট',
        onTap: () => Navigator.pushNamed(context, '/deposit-withdraw'),
      ),
      if (driver.outstandingCashDueCount > 0) _buildCashDueNotice(driver),
      const SizedBox(height: 14),
      _SectionLabel('অ্যাকাউন্ট'),
      _MenuRow(
        icon: Icons.notifications_rounded,
        label: 'নোটিফিকেশন',
        onTap: () => Navigator.pushNamed(context, '/inbox'),
      ),
      _MenuRow(
        icon: Icons.settings_rounded,
        label: 'সেটিংস',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        ),
      ),
      const SizedBox(height: 14),
      ..._buildSupportSection(),
      const SizedBox(height: 18),
      _MenuRow(
        icon: Icons.logout_rounded,
        label: 'লগ আউট',
        danger: true,
        onTap: _confirmLogout,
      ),
    ];
  }

  // ── Shared pieces ─────────────────────────────────────────────────────────

  /// One slim line for the numbers — the bordered stat cards spent two text
  /// rows plus padding on what a phrase can say.
  Widget _buildStatStrip(List<Widget> items) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(Container(
          width: 3,
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFCBD5E1),
            shape: BoxShape.circle,
          ),
        ));
      }
      children.add(items[i]);
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: children);
  }

  Widget _statItem(Widget icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 4),
        Text(
          value,
          style: AppFonts.roboto(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppFonts.roboto(fontSize: 12, color: _muted),
        ),
      ],
    );
  }

  String _displayName() {
    final user = AuthService.currentUser;
    final name = [user?.firstName, user?.lastName]
        .where((p) => p != null && p.trim().isNotEmpty)
        .join(' ')
        .trim();
    return name.isNotEmpty ? name : (user?.username ?? 'ব্যবহারকারী');
  }

  /// The dashboard switch.
  ///
  /// This was a two-tab segmented control, which reads as "filter this page".
  /// It does something far bigger: it changes which dashboard the app opens
  /// on, permanently, until flipped back. A switch says that; tabs do not.
  Widget _buildModeSwitch() {
    final isDriver = _mode == RideshareMode.driver;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDriver ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDriver ? Icons.drive_eta_rounded : Icons.person_rounded,
            size: 17,
            color: isDriver ? const Color(0xFF059669) : _muted,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The row names the mode you are IN, not the one the switch
              // would take you to — the badge above and this line must agree.
              Text(
                isDriver ? 'ড্রাইভার মোড' : 'প্যাসেঞ্জার মোড',
                style: AppFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              Text(
                isDriver
                    ? 'সুইচ বন্ধ করলে প্যাসেঞ্জার মোডে ফিরবেন'
                    : 'সুইচ চালু করলে ড্রাইভার মোডে যাবেন',
                style: AppFonts.roboto(fontSize: 11, color: _muted),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: isDriver,
          activeTrackColor: const Color(0xFF059669),
          // Kills the 48px material tap-target box that made this row tall.
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: (on) =>
              _setMode(on ? RideshareMode.driver : RideshareMode.passenger),
        ),
      ],
    );
  }

  /// What this account is right now, shown with the name.
  ///
  /// For a driver it also carries the approval state, because "Driver" and
  /// "Driver, still waiting on approval" are very different things to be.
  Widget _buildRoleBadge() {
    if (_driver == null) {
      return _badge(
        icon: Icons.person_rounded,
        label: 'প্যাসেঞ্জার',
        bg: const Color(0xFFF1F5F9),
        fg: const Color(0xFF475569),
      );
    }
    if (!_isApprovedDriver) {
      return _buildApprovalBadge(_driver!.approvalStatus);
    }
    return _showingDriver
        ? _badge(
            icon: Icons.verified_rounded,
            label: 'ড্রাইভার',
            bg: const Color(0xFFECFDF5),
            fg: const Color(0xFF059669),
          )
        : _badge(
            icon: Icons.person_rounded,
            label: 'প্যাসেঞ্জার',
            bg: const Color(0xFFF1F5F9),
            fg: const Color(0xFF475569),
          );
  }

  Widget _badge({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentity({
    required String avatar,
    required String name,
    required String phone,
    Widget? badge,
  }) {
    return Column(
      children: [
        _buildAvatar(avatar),
        const SizedBox(height: 10),
        Text(
          name,
          textAlign: TextAlign.center,
          style: AppFonts.roboto(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          phone,
          textAlign: TextAlign.center,
          style: AppFonts.roboto(fontSize: 13, color: _muted),
        ),
        if (badge != null) ...[
          const SizedBox(height: 6),
          badge,
        ],
      ],
    );
  }

  Widget _buildAvatar(String url) {
    const size = 76.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFF1F5F9), width: 3),
      ),
      child: ClipOval(
        child: url.isNotEmpty
            ? AppNetworkImage(
                url,
                errorWidget: const _AvatarFallback(),
              )
            : const _AvatarFallback(),
      ),
    );
  }

  Widget _buildApprovalBadge(String status) {
    late final Color bg, fg;
    late final IconData icon;
    late final String label;
    switch (status) {
      case 'approved':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        icon = Icons.verified_rounded;
        label = 'এপ্রুভড ড্রাইভার';
        break;
      case 'suspended':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        icon = Icons.block_rounded;
        label = 'সাসপেন্ডেড';
        break;
      default:
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFD97706);
        icon = Icons.hourglass_top_rounded;
        label = 'এপ্রুভের অপেক্ষায়';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  /// The one control that turns a rider into a driver, in whichever of its
  /// four states applies. An approved driver never sees it — they get the
  /// switch at the top of the page instead.
  Widget _buildDriverCallToAction() {
    if (_isApprovedDriver) return const SizedBox.shrink();

    final status = _driver?.approvalStatus;

    if (status == 'pending') {
      return _StatusButton(
        icon: Icons.hourglass_top_rounded,
        title: 'ড্রাইভার আবেদন জমা আছে',
        subtitle: 'এপ্রুভ হলে এখানেই ড্রাইভার মোড চালু হবে',
        tint: const Color(0xFFD97706),
        background: const Color(0xFFFFFBEB),
        border: const Color(0xFFFDE68A),
      );
    }

    if (status == 'suspended') {
      return _StatusButton(
        icon: Icons.block_rounded,
        title: 'ড্রাইভার অ্যাকাউন্ট সাসপেন্ড',
        subtitle: 'সহায়তার জন্য সাপোর্টে যোগাযোগ করুন',
        tint: const Color(0xFFDC2626),
        background: const Color(0xFFFEF2F2),
        border: const Color(0xFFFECACA),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _applying ? null : _openApplySheet,
        style: ElevatedButton.styleFrom(
          backgroundColor: _ink,
          disabledBackgroundColor: const Color(0xFF64748B),
          padding: const EdgeInsets.symmetric(vertical: 15),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _applying
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.drive_eta_rounded,
                      size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'ড্রাইভার হতে আবেদন করুন',
                    style: AppFonts.roboto(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCashDueNotice(DriverProfile driver) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, size: 18, color: Color(0xFFD97706)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${driver.outstandingCashDueCount}টি রাইডে '
              '৳${driver.outstandingCashDueAmount.toStringAsFixed(0)} ক্যাশ বকেয়া',
              style: AppFonts.roboto(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSupportSection() {
    return [
      _SectionLabel('সাপোর্ট'),
      _MenuRow(
        icon: Icons.phone_rounded,
        label: '+8801896144066',
        sublabel: 'সাপোর্ট হেল্পলাইন',
        iconBg: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF16A34A),
        onTap: () => launchUrl(Uri.parse('tel:+8801896144066')),
      ),
      _MenuRow(
        icon: Icons.email_rounded,
        label: 'support@adsyclub.com',
        sublabel: 'ইমেইল সাপোর্ট',
        iconBg: const Color(0xFFEDE9FE),
        iconColor: const Color(0xFF7C3AED),
        onTap: () => launchUrl(Uri.parse('mailto:support@adsyclub.com')),
      ),
      _MenuRow(
        icon: Icons.flag_rounded,
        label: 'সমস্যা জানান',
        sublabel: 'সাপোর্ট টিকিট খুলুন',
        iconBg: const Color(0xFFFEF3C7),
        iconColor: const Color(0xFFD97706),
        // The drawer used to pop a text box that showed a success toast and
        // threw the text away. Send it to the ticket system that actually
        // reaches support.
        onTap: () => Navigator.pushNamed(context, '/support'),
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: () => launchUrl(Uri.parse('tel:999')),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emergency_rounded,
                    size: 18, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('কল ৯৯৯',
                        style: AppFonts.roboto(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFDC2626))),
                    Text('জরুরি সেবা',
                        style: AppFonts.roboto(
                            fontSize: 11.5, color: const Color(0xFFEF4444))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFEF4444), size: 20),
            ],
          ),
        ),
      ),
    ];
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('লগ আউট করবেন?',
            style: AppFonts.roboto(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('আবার ব্যবহার করতে লগ ইন করতে হবে।',
            style: AppFonts.roboto(fontSize: 13.5)),
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4, top: 2),
        child: Text(
          text.toUpperCase(),
          style: AppFonts.roboto(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: const Color(0xFF94A3B8),
          ),
        ),
      );
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final String? trailingText;
  final VoidCallback onTap;
  final bool danger;
  final Color? iconBg;
  final Color? iconColor;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.sublabel,
    this.trailingText,
    this.danger = false,
    this.iconBg,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFEF4444) : const Color(0xFF0F172A);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg ??
                    (danger
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFF1F5F9)),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor ?? color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.roboto(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  if (sublabel != null)
                    Text(
                      sublabel!,
                      style: AppFonts.roboto(
                        fontSize: 11.5,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                ],
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: AppFonts.roboto(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (!danger)
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}

/// A non-tappable button-shaped status — what "Apply for a Driver" turns into
/// once there is an application to wait on.
class _StatusButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final Color background;
  final Color border;

  const _StatusButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.background,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: tint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppFonts.roboto(
                    fontSize: 11.5,
                    color: tint.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
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
