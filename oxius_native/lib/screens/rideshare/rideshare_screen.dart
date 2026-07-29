import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../services/fcm_service.dart';
import '../../services/translation_service.dart';
import '../../widgets/rideshare_drawer.dart';
import 'rideshare_account_screen.dart';
import 'rideshare_passenger_panel.dart';
import 'rideshare_driver_panel.dart';

/// The rideshare shell: a full-bleed map with the controls floating on top.
///
/// There is deliberately no AppBar. A ride-hailing screen is a map you act
/// on, and a solid header steals the top eighth of it while telling the rider
/// something they already know. What used to live in that bar now floats over
/// the map exactly where the design puts it: the drawer button top-left, the
/// rider's own avatar top-right, and nothing else competing with the sheet
/// that rises from the bottom.
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _passengerPanelKey = const RidesharePassengerPanelKey();

  String t(String key, {required String fallback}) =>
      _ts.t(key, fallback: fallback);

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

    _passengerPanel ??= RidesharePassengerPanel(key: _passengerPanelKey);
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
    if (!mounted ||
        (requestedMode != 'driver' && requestedMode != 'passenger')) {
      return;
    }

    // Only ensure the target panel is instantiated so it can process the
    // event internally.  Do NOT auto-switch the active tab — that yanks the
    // user away from whatever they are doing (e.g. driver completing a ride
    // would jump to the passenger tab because the notification resolves as
    // mode=passenger).
    _ensureModePanel(requestedMode!);
  }

  void _openAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RideshareAccountScreen(
          onOpenSavedPlaces: () =>
              _passengerPanelKey.openCustomLocationSheet(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF1F3F6),
      // No AppBar: the map runs edge to edge behind the status bar and the
      // controls float over it.
      drawer: RideshareDrawer(
        activeTab: _mode,
        onModeSelected: (m) => _setMode(m),
        onOpenCustomLocation: () =>
            _passengerPanelKey.openCustomLocationSheet(),
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: _mode == 'passenger' ? 0 : 1,
                children: [
                  _passengerPanel ?? const SizedBox.shrink(),
                  _driverPanel ?? const SizedBox.shrink(),
                ],
              ),
            ),
            _buildFloatingControls(),
          ],
        ),
      ),
    );
  }

  /// The two circular controls over the map: menu on the left, the rider's
  /// own face on the right.
  Widget _buildFloatingControls() {
    final user = AuthService.currentUser;
    final avatar = user?.profilePicture ?? '';

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _FloatingCircle(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: const Icon(Icons.menu_rounded,
                size: 20, color: Color(0xFF0F172A)),
          ),
          _FloatingCircle(
            onTap: _openAccount,
            padding: EdgeInsets.zero,
            child: ClipOval(
              child: avatar.isNotEmpty
                  ? Image.network(
                      avatar,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _AvatarFallback(),
                    )
                  : const _AvatarFallback(),
            ),
          ),
        ],
      ),
    );
  }
}

/// White circle with the soft lift the design gives its map controls.
class _FloatingCircle extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsets padding;

  const _FloatingCircle({
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        color: const Color(0xFFF1F5F9),
        child: const Icon(Icons.person_rounded,
            size: 22, color: Color(0xFF64748B)),
      );
}
