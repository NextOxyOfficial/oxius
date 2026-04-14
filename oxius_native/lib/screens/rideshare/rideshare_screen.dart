import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/fcm_service.dart';
import '../../services/translation_service.dart';
import 'rideshare_passenger_panel.dart';
import 'rideshare_driver_panel.dart';

class RideshareScreen extends StatefulWidget {
  const RideshareScreen({super.key});

  @override
  State<RideshareScreen> createState() => _RideshareScreenState();
}

class _RideshareScreenState extends State<RideshareScreen> {
  String _mode = 'passenger'; // 'passenger' or 'driver'
  final TranslationService _ts = TranslationService();
  bool _didApplyRouteArgs = false;
  StreamSubscription<Map<String, dynamic>>? _rideshareNotificationSubscription;
  Widget? _passengerPanel;
  Widget? _driverPanel;

  String t(String key, {required String fallback}) => _ts.t(key, fallback: fallback);

  @override
  void initState() {
    super.initState();
    _ensureModePanel('passenger');
    _ts.addListener(_onTranslationsChanged);
    _rideshareNotificationSubscription =
        FCMService.rideshareNotificationEvents.listen(_handleRideshareEvent);
  }

  @override
  void dispose() {
    _rideshareNotificationSubscription?.cancel();
    _ts.removeListener(_onTranslationsChanged);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didApplyRouteArgs) {
      return;
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    String? requestedMode;

    if (args is Map) {
      requestedMode = args['mode']?.toString();
    } else if (args is String) {
      requestedMode = args;
    }

    if (requestedMode == 'driver' || requestedMode == 'passenger') {
      _mode = requestedMode!;
      _ensureModePanel(_mode);
    }

    _didApplyRouteArgs = true;
  }

  void _ensureModePanel(String mode) {
    if (mode == 'driver') {
      _driverPanel ??= const RideshareDriverPanel();
      return;
    }

    _passengerPanel ??= const RidesharePassengerPanel();
  }

  void _setMode(String mode) {
    if (_mode == mode) {
      return;
    }

    _ensureModePanel(mode);
    setState(() => _mode = mode);
  }

  void _onTranslationsChanged() {
    if (mounted) setState(() {});
  }

  void _handleRideshareEvent(Map<String, dynamic> payload) {
    final requestedMode = payload['mode']?.toString();
    if (!mounted || (requestedMode != 'driver' && requestedMode != 'passenger')) {
      return;
    }

    // Only ensure the target panel is instantiated so it can process the
    // event internally.  Do NOT auto-switch the active tab — that yanks the
    // user away from whatever they are doing (e.g. driver completing a ride
    // would jump to the passenger tab because the notification resolves as
    // mode=passenger).
    _ensureModePanel(requestedMode!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const SizedBox(height: 4),
          _buildModeSwitch(),
          const SizedBox(height: 4),
          Expanded(
            child: IndexedStack(
              index: _mode == 'passenger' ? 0 : 1,
              children: [
                _passengerPanel ?? const SizedBox.shrink(),
                _driverPanel ?? const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            size: 20,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('rideshare_title', fallback: 'Ride Share'),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                t('rideshare_subtitle', fallback: 'Book a ride or drive'),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(
            context,
            _mode == 'driver'
                ? '/rideshare/driver-history'
                : '/rideshare/history',
          ),
          tooltip: t('rideshare_history', fallback: 'History'),
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 20,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        if (_mode == 'driver')
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/rideshare/vehicles'),
            tooltip: t('rideshare_vehicles_btn', fallback: 'Vehicles'),
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.two_wheeler_rounded,
                size: 20,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: const Color(0xFFE2E8F0),
        ),
      ),
    );
  }

  Widget _buildModeSwitch() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              label: t('rideshare_passenger_mode', fallback: 'Passenger'),
              icon: Icons.person_rounded,
              isActive: _mode == 'passenger',
              onTap: () => _setMode('passenger'),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildModeButton(
              label: t('rideshare_driver_mode', fallback: 'Driver'),
              icon: Icons.badge_rounded,
              isActive: _mode == 'driver',
              onTap: () => _setMode('driver'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

