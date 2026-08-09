import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../services/fcm_service.dart';
import '../../services/translation_service.dart';
import 'rideshare_account_screen.dart';
import 'rideshare_mode.dart';
import 'rideshare_passenger_panel.dart';
import 'rideshare_driver_panel.dart';
import '../../widgets/app_network_image.dart';

/// The rideshare shell: a full-bleed map with one control floating on top.
///
/// There is deliberately no AppBar and no sidebar. A ride-hailing screen is a
/// map you act on; a solid header steals the top eighth of it and a drawer is
/// a second place for the same links to rot in. Everything the drawer held —
/// modes, vehicles, history, support, emergency — now lives in the account
/// page behind the one control that remains: the rider's own face, top-right.
class RideshareScreen extends StatefulWidget {
  const RideshareScreen({super.key});

  @override
  State<RideshareScreen> createState() => _RideshareScreenState();
}

class _RideshareScreenState extends State<RideshareScreen> {
  String _mode = 'passenger'; // 'passenger' or 'driver'
  final TranslationService _ts = TranslationService();
  bool _didApplyRouteArgs = false;
  bool _modeCameFromRoute = false;
  StreamSubscription<Map<String, dynamic>>? _rideshareNotificationSubscription;
  Widget? _passengerPanel;
  Widget? _driverPanel;
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
      _modeCameFromRoute = true;
      _ensureModePanel(_mode);
    }

    _didApplyRouteArgs = true;
    if (!_modeCameFromRoute) {
      _restoreSavedMode();
    }
  }

  /// Restores the sticky choice. Route arguments outrank it — a push that
  /// says mode=driver means the caller knows something we do not, e.g. a ride
  /// request notification.
  Future<void> _restoreSavedMode() async {
    final saved = await RideshareMode.load();
    if (!mounted || _didApplyRouteArgs && _modeCameFromRoute) return;
    if (saved == _mode) return;
    _ensureModePanel(saved);
    setState(() => _mode = saved);
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
    RideshareMode.save(mode);
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

    // Mount the target panel so it can process the event internally — inside
    // setState, because a panel assigned without a rebuild never enters the
    // tree, its initState never runs, and the event lands on nothing. Do NOT
    // auto-switch the active tab — that yanks the user away from whatever
    // they are doing (e.g. driver completing a ride would jump to the
    // passenger tab because the notification resolves as mode=passenger).
    setState(() => _ensureModePanel(requestedMode!));
  }

  void _openAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RideshareAccountScreen(
          initialMode: _mode,
          // Flipping the switch in there swaps the panel behind here, so
          // popping back lands on the side the rider just chose.
          onModeChanged: _setMode,
          onOpenSavedPlaces: () => _passengerPanelKey.openCustomLocationSheet(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      // No AppBar and no drawer: the map runs edge to edge behind the status
      // bar and the only control floats over it.
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

  /// The two controls over the map: back out of rideshare on the left, and
  /// the rider's own face on the right — the way into everything else.
  ///
  /// A driver gets a small badge on the avatar so they can tell at a glance
  /// which side of the app the map below belongs to.
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
          // Losing the AppBar also lost the only way back out of rideshare.
          // Nothing replaced it, so the rider was stranded on the map.
          if (Navigator.of(context).canPop())
            _FloatingCircle(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 20, color: Color(0xFF0F172A)),
            )
          else
            const SizedBox(width: 44),
          _FloatingCircle(
            onTap: _openAccount,
            padding: EdgeInsets.zero,
            badge: _mode == 'driver'
                ? const Icon(Icons.drive_eta_rounded,
                    size: 10, color: Colors.white)
                : null,
            child: ClipOval(
              child: avatar.isNotEmpty
                  ? AppNetworkImage(
                      avatar,
                      width: 44,
                      height: 44,
                      errorWidget: const _AvatarFallback(),
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
  final Widget? badge;

  const _FloatingCircle({
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(12),
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
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
          if (badge != null)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: badge,
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
        width: 44,
        height: 44,
        color: const Color(0xFFF1F5F9),
        child: const Icon(Icons.person_rounded,
            size: 22, color: Color(0xFF64748B)),
      );
}
