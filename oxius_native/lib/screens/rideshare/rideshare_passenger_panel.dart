import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/rideshare_models.dart';
import '../../services/adsyconnect_service.dart';
import '../../services/auth_service.dart';
import '../../services/fcm_service.dart';
import '../../services/rideshare_service.dart';
import '../../services/rideshare_realtime_service.dart';
import '../../services/translation_service.dart';
import '../../utils/network_error_handler.dart';
import '../adsy_connect_chat_interface.dart';
import '../business_network/profile_screen.dart';
import 'rideshare_map_widget.dart';
import 'custom_location_sheet.dart';

part 'rideshare_passenger_panel_active_ride.dart';
part 'rideshare_passenger_panel_booking.dart';

class RidesharePassengerPanel extends StatefulWidget {
  const RidesharePassengerPanel({super.key});

  @override
  State<RidesharePassengerPanel> createState() =>
      _RidesharePassengerPanelState();
}

// Public key type so callers can invoke openCustomLocationSheet()
class RidesharePassengerPanelKey
    extends GlobalKey<_RidesharePassengerPanelState> {
  const RidesharePassengerPanelKey() : super.constructor();
  void openCustomLocationSheet() => currentState?._showCustomLocationSheet();
}

class _RidesharePassengerPanelState extends State<RidesharePassengerPanel>
    with WidgetsBindingObserver {
  static const String _recentPlacesKey = 'rideshare_recent_places_v2';

  final TranslationService _ts = TranslationService();
  String t(String key, {required String fallback}) =>
      _ts.t(key, fallback: fallback);

  // Controllers
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();

  // State
  RidePoint? _pickupPoint;
  RidePoint? _dropPoint;
  String _selectedVehicleType = 'bike';
  String _selectedPaymentMethod = 'wallet';
  RideEstimate? _estimate;
  Ride? _activeRide;
  List<RidePoint> _pickupSuggestions = [];
  List<RidePoint> _dropSuggestions = [];
  List<RidePoint> _recentPlaces = [];
  List<NearbyDriver> _nearbyDrivers = [];

  // Loading states
  bool _isLoadingLocation = false;
  bool _isSearchingPickup = false;
  bool _isSearchingDrop = false;
  bool _isEstimating = false;
  bool _isCreatingRide = false;
  bool _isCancellingRide = false;
  bool _isLoadingActiveRide = true;
  bool _locationGranted = false;
  bool _isCheckingLocationPermission = true;
  bool _didAutoFillCurrentLocation = false;

  // Focus
  String _activeInput = 'pickup'; // 'pickup' or 'drop'
  Timer? _searchDebounce;
  final RideshareRealtimeService _realtimeService = RideshareRealtimeService();
  StreamSubscription<Map<String, dynamic>>? _rideEventSubscription;
  StreamSubscription<Map<String, dynamic>>? _rideshareNotificationSubscription;
  Timer? _statusRefreshTimer;
  String _searchStatusMessage = 'Looking for nearby drivers...';
  int _driverResponseTimeoutSeconds = 60;
  int _dispatchAttempt = 0;
  DateTime? _targetedAtFromEvent;
  String? _targetedDriverNameFromEvent;
  bool _noDriversInRange = false;
  bool _isReportingCancellation = false;
  StreamSubscription<Position>? _passengerLocationSubscription;
  bool _isRefreshingActiveRide = false;
  int _statusRefreshTick = 0;
  String? _lastExpiredTargetRefreshKey;
  // Server timestamp of the most recent ride event we applied. Used to drop
  // out-of-order events that arrive on the socket after a newer one has
  // already mutated UI state — e.g. a stale "driver_assigned" trailing a
  // "ride_completed".
  DateTime? _lastAppliedRideEventAt;
  StreamSubscription<String>? _authFailureSubscription;
  RoutePreview? _activeRoutePreview;
  String _activeRouteSignature = '';
  bool _isLoadingActiveRoute = false;
  double? _mapSearchLatitude;
  double? _mapSearchLongitude;
  bool _hideDropSuggestionsUntilEdit = false;

  // Booking step: 0=drop input, 1=pickup input, 2=vehicle+payment+confirm
  int _bookingStep = 0;

  @override
  void initState() {
    super.initState();
    _ts.addListener(_onTranslationsChanged);
    WidgetsBinding.instance.addObserver(this);
    _startStatusRefreshTimer();
    _loadRecentPlaces();
    _rideshareNotificationSubscription =
        FCMService.rideshareNotificationEvents.listen(
      _handleRideshareNotificationEvent,
    );
    _authFailureSubscription = _realtimeService.authFailure.listen((reason) {
      // Repeated immediate WS failures — most commonly an expired token. Fall
      // back to an HTTP refresh of the active ride; if the user is still
      // authenticated this also gives the service a chance to retry the
      // socket cleanly.
      if (!mounted) return;
      unawaited(_refreshActiveRideSilently(forceApply: true));
      unawaited(_realtimeService.retryAfterAuthFailure());
    });
    _refreshLocationPermissionStatus(autoFillCurrentLocation: true);
    _loadActiveRide();
  }

  @override
  void dispose() {
    _ts.removeListener(_onTranslationsChanged);
    WidgetsBinding.instance.removeObserver(this);
    _pickupController.dispose();
    _dropController.dispose();
    _searchDebounce?.cancel();
    _statusRefreshTimer?.cancel();
    _rideEventSubscription?.cancel();
    _rideshareNotificationSubscription?.cancel();
    _passengerLocationSubscription?.cancel();
    _authFailureSubscription?.cancel();
    _realtimeService.dispose();
    super.dispose();
  }

  void _onTranslationsChanged() {
    if (mounted) setState(() {});
  }

  void _startStatusRefreshTimer() {
    _statusRefreshTimer?.cancel();
    // The 1s timer exists primarily to drive the targeted-driver countdown UI
    // while we are actively searching. Once a driver is assigned we no longer
    // need per-second ticks — socket events drive the state. We still keep a
    // low-frequency polling fallback (every 15s) to recover from a missed
    // socket event without hammering the server.
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _activeRide == null) return;
      final ride = _activeRide!;
      final isSearching = ride.isSearching;

      if (isSearching) {
        final targetedDriverName = _currentTargetedDriverName(ride);
        final secondsRemaining = _targetedRemainingSeconds(ride);

        if (targetedDriverName.isNotEmpty && secondsRemaining > 0) {
          _lastExpiredTargetRefreshKey = null;
        }

        if (targetedDriverName.isNotEmpty && secondsRemaining == 0) {
          final targetedAt = _targetedAtFromEvent ?? ride.targetedAt;
          final expiryKey = [
            ride.id,
            ride.dispatchAttempt,
            targetedDriverName,
            targetedAt?.toIso8601String() ?? '',
          ].join('|');

          if (_lastExpiredTargetRefreshKey != expiryKey) {
            _lastExpiredTargetRefreshKey = expiryKey;
            unawaited(_refreshActiveRideSilently(forceApply: true));
          }
        }

        setState(() {}); // tick countdown
      }

      _statusRefreshTick += 1;
      // Trust the WebSocket. Poll infrequently as a safety net only.
      //   searching + targeted driver visible → 8s (countdown is local)
      //   searching (no target yet)          → 6s
      //   any other state                    → 20s
      final int refreshIntervalSeconds;
      if (isSearching) {
        refreshIntervalSeconds =
            _currentTargetedDriverName(ride).isNotEmpty ? 8 : 6;
      } else {
        refreshIntervalSeconds = 20;
      }
      if (_statusRefreshTick % refreshIntervalSeconds == 0) {
        unawaited(_refreshActiveRideSilently());
      }
    });
  }

  int _parseInt(dynamic value, int fallback) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _formatDuration(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  int _targetedRemainingSeconds(Ride ride, {DateTime? now}) {
    if (_currentTargetedDriverName(ride).isEmpty) return 0;

    final targetedAt = _targetedAtFromEvent ?? ride.targetedAt;
    if (targetedAt == null) return _driverResponseTimeoutSeconds;

    final currentTime = now ?? DateTime.now();
    final elapsed = currentTime.difference(targetedAt).inSeconds;
    final remaining = _driverResponseTimeoutSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  double _mapViewportHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeHeight = screenHeight - MediaQuery.of(context).padding.vertical;
    final preferredHeight = safeHeight * 0.62;
    return preferredHeight < 320 ? 320 : preferredHeight;
  }

  Widget _buildMapSectionFrame({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required Widget child,
    Color accentColor = const Color(0xFF6366F1),
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact header: icon + title + badge in a single tight row
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.72)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: accentColor.withValues(alpha: 0.14)),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: _mapViewportHeight(context),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.72), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ],
      ),
    );
  }

  String _currentTargetedDriverName(Ride ride) {
    final eventName = (_targetedDriverNameFromEvent ?? '').trim();
    if (eventName.isNotEmpty) {
      return eventName;
    }
    return ride.targetedDriver?.userName.trim() ?? '';
  }

  Ride? _resolvePassengerActiveRide(Ride? ride) {
    final currentUserId = AuthService.currentUser?.id ?? '';
    if (ride == null || currentUserId.isEmpty) {
      return ride;
    }
    return ride.riderId == currentUserId ? ride : null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshLocationPermissionStatus(
        autoFillCurrentLocation: _pickupPoint == null && _activeRide == null,
      );
      if (_activeRide == null) {
        _loadActiveRide();
      } else {
        unawaited(_refreshActiveRideSilently(forceApply: true));
      }
    }
  }

  Future<bool> _refreshLocationPermissionStatus({
    bool autoFillCurrentLocation = false,
  }) async {
    if (mounted) {
      setState(() => _isCheckingLocationPermission = true);
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();
      final granted = serviceEnabled &&
          permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever;

      if (mounted) {
        setState(() {
          _locationGranted = granted;
          _isCheckingLocationPermission = false;
        });
      }

      if (granted &&
          autoFillCurrentLocation &&
          !_didAutoFillCurrentLocation &&
          _pickupPoint == null &&
          _activeRide == null) {
        _didAutoFillCurrentLocation = true;
        await _useCurrentLocation(showSuccessMessage: false);
      }

      return granted;
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationGranted = false;
          _isCheckingLocationPermission = false;
        });
      }
      return false;
    }
  }

  Future<void> _requestLocationPermission() async {
    if (_isLoadingLocation) return;

    setState(() => _isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError(
            'Location service is off. Please enable GPS to use rideshare.');
        await Geolocator.openLocationSettings();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showError('Location permission is required for rideshare.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showError(
            'Location permission permanently denied. Please enable it in app settings.');
        await Geolocator.openAppSettings();
        return;
      }

      if (mounted) {
        setState(() => _locationGranted = true);
      }

      if (_pickupPoint == null) {
        _didAutoFillCurrentLocation = true;
        await _useCurrentLocation(showSuccessMessage: false);
        _showSuccess(
            'Location enabled. Pickup set from your current location.');
      }
    } catch (e) {
      _showError('Failed to enable location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _isCheckingLocationPermission = false;
        });
      }
    }
  }

  Future<void> _loadActiveRide() async {
    setState(() => _isLoadingActiveRide = true);
    final result = await RideshareService.getActiveRide();
    if (mounted) {
      _applyRideState(_resolvePassengerActiveRide(result.data),
          isLoading: false);
    }
  }

  Future<void> _loadActiveRideById(String rideId) async {
    setState(() => _isLoadingActiveRide = true);
    final result = await RideshareService.getRide(rideId);
    if (mounted) {
      _applyRideState(_resolvePassengerActiveRide(result.data),
          isLoading: false);
    }
  }

  Future<void> _refreshRideSnapshot({String? rideId}) async {
    final result = rideId != null && rideId.isNotEmpty
        ? await RideshareService.getRide(rideId)
        : await RideshareService.getActiveRide();
    if (!mounted || !result.success) {
      return;
    }

    _applyRideState(_resolvePassengerActiveRide(result.data), isLoading: false);
  }

  void _syncSearchDispatchState(Ride? ride) {
    if (ride == null || !ride.isSearching) {
      _targetedAtFromEvent = null;
      _targetedDriverNameFromEvent = null;
      _noDriversInRange = false;
      _lastExpiredTargetRefreshKey = null;
      return;
    }

    _targetedAtFromEvent = ride.targetedAt;
    final targetedDriverName = ride.targetedDriver?.userName.trim() ?? '';
    _targetedDriverNameFromEvent =
        targetedDriverName.isEmpty ? null : targetedDriverName;
    if (targetedDriverName.isNotEmpty) {
      _noDriversInRange = false;
      if (_targetedRemainingSeconds(ride) > 0) {
        _lastExpiredTargetRefreshKey = null;
      }
    }
  }

  void _applyRideState(Ride? ride, {required bool isLoading}) {
    setState(() {
      _activeRide = ride;
      _searchStatusMessage = _deriveSearchStatusMessage(ride);
      _dispatchAttempt = ride?.dispatchAttempt ?? 0;
      _syncSearchDispatchState(ride);
      _isLoadingActiveRide = isLoading;
      _statusRefreshTick = 0;
    });
    _syncRideRealtimeConnection();
    _refreshPassengerRoutePreview(force: true);
  }

  Future<void> _handleRideshareNotificationEvent(
    Map<String, dynamic> payload,
  ) async {
    if (!mounted) {
      return;
    }

    final mode = payload['mode']?.toString();
    if (mode != 'passenger') {
      return;
    }

    final rideId = payload['ride_id']?.toString();
    if (rideId != null && rideId.isNotEmpty) {
      await _refreshRideSnapshot(rideId: rideId);
      return;
    }

    await _refreshRideSnapshot();
  }

  Future<void> _refreshActiveRideSilently({bool forceApply = false}) async {
    final rideId = _activeRide?.id;
    if (_isRefreshingActiveRide ||
        rideId == null ||
        rideId.isEmpty ||
        _isCancellingRide) {
      return;
    }

    _isRefreshingActiveRide = true;
    try {
      final result = await RideshareService.getRide(rideId);
      if (!mounted || !result.success) {
        return;
      }

      final refreshedRide = result.data;
      if (refreshedRide == null) {
        _applyRideState(null, isLoading: false);
        return;
      }

      final resolvedRide = _resolvePassengerActiveRide(refreshedRide);
      if (resolvedRide == null) {
        _applyRideState(null, isLoading: false);
        return;
      }

      if (!forceApply && _activeRide?.updatedAt == resolvedRide.updatedAt) {
        _syncPassengerLocationTracking();
        return;
      }

      setState(() {
        _activeRide = resolvedRide;
        _searchStatusMessage = _deriveSearchStatusMessage(resolvedRide);
        _dispatchAttempt = resolvedRide.dispatchAttempt;
        _syncSearchDispatchState(resolvedRide);
        _statusRefreshTick = 0;
      });
      _syncRideRealtimeConnection(); // Re-validate socket after state change
      _syncPassengerLocationTracking();
      _refreshPassengerRoutePreview();
    } finally {
      _isRefreshingActiveRide = false;
    }
  }

  String _deriveSearchStatusMessage(Ride? ride) {
    if (ride == null) {
      return _localizeDisplayMessage(
        t('rideshare_finding_driver_status',
            fallback: 'Looking for nearby drivers...'),
      );
    }

    for (final entry in ride.statusHistory.reversed) {
      final event = entry.metadata['event'];
      if (event == 'driver_skipped') {
        continue;
      }
      final message =
          entry.metadata['status_text'] ?? entry.metadata['message'];
      if (message is String && message.trim().isNotEmpty) {
        return _localizeDisplayMessage(message.trim());
      }
    }

    final targetedDriverName = _currentTargetedDriverName(ride);
    if (ride.isSearching && targetedDriverName.isNotEmpty) {
      return 'à¦°à¦¿à¦•à§‹à§Ÿà§‡à¦¸à§à¦Ÿ à¦ªà¦¾à¦ à¦¾à¦¨à§‹ à¦¹à§Ÿà§‡à¦›à§‡: $targetedDriverName';
    }
    if (ride.isSearching) {
      return _localizeDisplayMessage(
        t('rideshare_finding_driver_status',
            fallback: 'Looking for nearby drivers...'),
      );
    }
    if (ride.isCancelled && (ride.cancellationReason?.isNotEmpty ?? false)) {
      return _localizeDisplayMessage(ride.cancellationReason!);
    }
    return _localizeDisplayMessage(ride.statusDisplay);
  }

  void _syncRideRealtimeConnection() {
    final ride = _activeRide;
    if (ride == null) {
      _rideEventSubscription?.cancel();
      _rideEventSubscription = null;
      _realtimeService.disconnectRide();
      return;
    }

    _rideEventSubscription ??=
        _realtimeService.rideEvents.listen(_handleRideRealtimeEvent);
    _realtimeService.connectRide(ride.id);
    _syncPassengerLocationTracking();
  }

  /// Start or stop live passenger GPS tracking based on active ride state.
  void _syncPassengerLocationTracking() {
    final ride = _activeRide;
    final shouldTrack = ride != null &&
        (ride.isDriverArriving || ride.isInProgress) &&
        _locationGranted;

    if (shouldTrack && _passengerLocationSubscription == null) {
      _passengerLocationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        ),
      ).listen(_sendPassengerLocation);
    } else if (!shouldTrack && _passengerLocationSubscription != null) {
      _passengerLocationSubscription?.cancel();
      _passengerLocationSubscription = null;
    }
  }

  void _sendPassengerLocation(Position position) {
    _realtimeService.sendToRide({
      'event': 'passenger.location',
      'latitude': position.latitude,
      'longitude': position.longitude,
      'heading': position.heading,
      'accuracy_meters': position.accuracy,
    });
  }

  Future<void> _handleRideRealtimeEvent(Map<String, dynamic> event) async {
    if (!mounted || _isCancellingRide) {
      return;
    }

    final type = event['type']?.toString() ?? '';
    final eventName = event['event']?.toString() ?? '';

    // When the socket connects (or reconnects after a gap), refresh state
    // immediately to recover any events that were emitted during the gap.
    // Django Channels does not buffer missed WebSocket frames, so a reconnect
    // without an immediate snapshot fetch leaves the UI stale.
    if (type == 'connection.established') {
      _lastAppliedRideEventAt = null; // resync from server snapshot
      unawaited(_refreshActiveRideSilently(forceApply: true));
      return;
    }

    // Out-of-order protection for state-changing ride events. Live driver
    // location pings and search-status updates intentionally bypass this
    // gate so we don't stall the pulsing UI on jittery networks.
    final isStateMutating =
        type == 'ride.event' || eventName == 'ride_status_changed';
    if (isStateMutating) {
      final eventTs = DateTime.tryParse(
        (event['timestamp'] ?? event['updated_at'] ?? '').toString(),
      );
      if (eventTs != null &&
          _lastAppliedRideEventAt != null &&
          eventTs.isBefore(_lastAppliedRideEventAt!)) {
        // Stale event — a newer one has already been applied. Drop it.
        return;
      }
      if (eventTs != null) {
        _lastAppliedRideEventAt = eventTs;
      }
    }

    if (_activeRide == null) return;

    if (type == 'driver.location') {
      final location = RideDriverLocation.fromJson(event);
      if (!mounted) return;
      setState(() {
        _activeRide = _activeRide?.copyWith(latestDriverLocation: location);
      });
      _refreshPassengerRoutePreview();
      return;
    }

    if (eventName == 'search_status_updated') {
      final message = event['message']?.toString();
      final timeoutSeconds = _parseInt(
        event['driver_response_timeout_seconds'],
        _driverResponseTimeoutSeconds,
      );
      final dispatchAttempt =
          _parseInt(event['dispatch_attempt'], _dispatchAttempt);
      final targetedAt =
          DateTime.tryParse(event['targeted_at']?.toString() ?? '');
      final targetedDriverId = event['targeted_driver_id']?.toString();
      final targetedDriverName = event['targeted_driver_name']?.toString();
      final noDrivers = event['no_drivers_in_range'] == true;

      setState(() {
        if (message != null && message.isNotEmpty) {
          _searchStatusMessage = _localizeDisplayMessage(message);
        }
        _noDriversInRange = noDrivers;
        _driverResponseTimeoutSeconds = timeoutSeconds;
        _dispatchAttempt = dispatchAttempt;
        _targetedDriverNameFromEvent =
            (targetedDriverName == null || targetedDriverName.trim().isEmpty)
                ? null
                : targetedDriverName.trim();
        _targetedAtFromEvent =
            (targetedDriverId == null || targetedDriverId.isEmpty)
                ? null
                : targetedAt;
      });
      return;
    }

    if (type == 'ride.event') {
      final rideId = event['ride_id']?.toString() ?? '';
      if (rideId.isEmpty) {
        return;
      }
      // Use silent refresh (no full-screen spinner) for socket-triggered updates.
      // _loadActiveRideById sets _isLoadingActiveRide=true which replaces the
      // entire UI with a spinner for 200-500ms on every state transition —
      // that causes the jarring "flash" between states. _refreshActiveRideSilently
      // updates the ride model in-place without any loading indicator.
      await _refreshActiveRideSilently(forceApply: true);
      if (eventName == 'ride_auto_cancelled') {
        _showError(event['message']?.toString() ??
            'No drivers available, please try again.');
      }
    }
  }

  Future<void> _useCurrentLocation({bool showSuccessMessage = true}) async {
    setState(() => _isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _locationGranted = false);
        }
        _showError('Location service is off. Please enable GPS to continue.');
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() => _locationGranted = false);
          }
          _showError('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _locationGranted = false);
        }
        _showError(
            'Location permission permanently denied. Please enable in settings.');
        await Geolocator.openAppSettings();
        return;
      }

      if (mounted) {
        setState(() => _locationGranted = true);
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // Reverse geocode
      final result = await RideshareService.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (mounted && result.success && result.data != null) {
        await _rememberRecentPlace(result.data!);
        setState(() {
          _pickupPoint = result.data;
          _pickupController.text = result.data!.name;
          _pickupSuggestions = [];
          _activeInput = 'drop';
        });
        _loadNearbyDrivers();
        _requestEstimate();
        if (showSuccessMessage) {
          _showSuccess('Location found');
        }
      } else {
        _showError('Could not resolve location');
      }
    } catch (e) {
      _showError('Failed to get location: $e');
    }

    if (mounted) {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _onPickupSearch(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _pickupSuggestions = [];
        _isSearchingPickup = false;
      });
      return;
    }
    setState(() => _isSearchingPickup = true);
    _searchDebounce = Timer(const Duration(milliseconds: 250), () async {
      final result = await RideshareService.searchLocations(
        query,
        limit: 7,
        latitude: _mapSearchLatitude ?? _pickupPoint?.latitude,
        longitude: _mapSearchLongitude ?? _pickupPoint?.longitude,
      );
      if (mounted) {
        setState(() {
          _isSearchingPickup = false;
          if (result.success) _pickupSuggestions = result.data ?? [];
        });
      }
    });
  }

  void _onDropSearch(String query) {
    _searchDebounce?.cancel();
    _hideDropSuggestionsUntilEdit = false;
    if (query.trim().length < 2) {
      setState(() {
        _dropSuggestions = [];
        _isSearchingDrop = false;
      });
      return;
    }
    setState(() => _isSearchingDrop = true);
    _searchDebounce = Timer(const Duration(milliseconds: 250), () async {
      final result = await RideshareService.searchLocations(
        query,
        limit: 7,
        latitude: _mapSearchLatitude ??
            _pickupPoint?.latitude ??
            _dropPoint?.latitude,
        longitude: _mapSearchLongitude ??
            _pickupPoint?.longitude ??
            _dropPoint?.longitude,
      );
      if (mounted) {
        setState(() {
          _isSearchingDrop = false;
          if (result.success) _dropSuggestions = result.data ?? [];
        });
      }
    });
  }

  void _onPlannerMapCenterChanged(double latitude, double longitude) {
    _mapSearchLatitude = latitude;
    _mapSearchLongitude = longitude;
  }

  Future<void> _selectPickupSuggestion(RidePoint point) async {
    await _rememberRecentPlace(point);
    setState(() {
      _pickupPoint = point;
      _pickupController.text = point.name;
      _pickupSuggestions = [];
      _activeInput = '';
      _bookingStep = 2; // advance to vehicle + payment
    });
    _loadNearbyDrivers();
    _requestEstimate();
  }

  Future<void> _selectDropSuggestion(RidePoint point) async {
    await _rememberRecentPlace(point);
    setState(() {
      _dropPoint = point;
      _dropController.text = point.name;
      _dropSuggestions = [];
      _hideDropSuggestionsUntilEdit = true;
      _activeInput = 'pickup';
      _bookingStep = 1; // advance to pickup
    });
    _requestEstimate();
  }

  void _dismissDropSuggestions() {
    if (!mounted) {
      return;
    }

    setState(() {
      _dropSuggestions = [];
      _hideDropSuggestionsUntilEdit = true;
      if (_activeInput == 'drop') {
        _activeInput = '';
      }
    });
  }

  Future<void> _loadRecentPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_recentPlacesKey) ?? <String>[];
    final loadedPlaces = <RidePoint>[];

    for (final rawItem in rawItems) {
      try {
        final decoded = jsonDecode(rawItem);
        if (decoded is Map<String, dynamic>) {
          loadedPlaces.add(RidePoint.fromJson(decoded));
        }
      } catch (_) {
        // Ignore malformed cached entries.
      }
    }

    if (!mounted) {
      return;
    }

    setState(() => _recentPlaces = loadedPlaces);
  }

  Future<void> _rememberRecentPlace(RidePoint point) async {
    final updatedPlaces = <RidePoint>[
      point,
      ..._recentPlaces.where(
        (existingPoint) =>
            existingPoint.latitude != point.latitude ||
            existingPoint.longitude != point.longitude ||
            existingPoint.name != point.name,
      ),
    ].take(8).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _recentPlacesKey,
      updatedPlaces.map((place) => jsonEncode(place.toJson())).toList(),
    );

    if (!mounted) {
      return;
    }

    setState(() => _recentPlaces = updatedPlaces);
  }

  Future<void> _showCustomLocationSheet() async {
    final result = await showCustomLocationSheet(context);
    if (result == null || !mounted) return;
    final point = result.point;
    if (_activeInput == 'drop' ||
        (_pickupPoint != null && _dropPoint == null)) {
      await _selectDropSuggestion(point);
    } else {
      await _selectPickupSuggestion(point);
    }
    if (!mounted) return;
    setState(() {});
    if (result.successMessage != null) {
      _showSuccess(result.successMessage!);
    }
  }

  List<RidePoint> _visibleSuggestionsForField(
    TextEditingController controller,
    List<RidePoint> suggestions,
    bool isActive,
  ) {
    if (!isActive) {
      return const <RidePoint>[];
    }
    if (controller.text.trim().isEmpty) {
      return const <RidePoint>[];
    }
    return suggestions;
  }

  Future<void> _loadNearbyDrivers() async {
    if (_pickupPoint == null) return;
    final result = await RideshareService.getNearbyDrivers(
      _pickupPoint!.latitude,
      _pickupPoint!.longitude,
      vehicleType: _selectedVehicleType,
    );
    if (mounted && result.success) {
      final nearbyDrivers = (result.data ?? const <NearbyDriver>[])
          .where((driver) => driver.isOnline)
          .toList(growable: false);
      setState(() => _nearbyDrivers = nearbyDrivers);
    }
  }

  Future<void> _requestEstimate() async {
    if (_pickupPoint == null || _dropPoint == null) return;

    setState(() => _isEstimating = true);

    final result = await RideshareService.estimateRide(
      pickupLatitude: _pickupPoint!.latitude,
      pickupLongitude: _pickupPoint!.longitude,
      dropLatitude: _dropPoint!.latitude,
      dropLongitude: _dropPoint!.longitude,
      vehicleType: _selectedVehicleType,
      pickupAddress: _pickupPoint!.name,
      dropAddress: _dropPoint!.name,
    );

    if (mounted) {
      setState(() {
        _estimate = result.data;
        _isEstimating = false;
      });
    }
  }

  Future<void> _createRide() async {
    if (!_locationGranted) {
      _showError(t('rideshare_location_required',
          fallback: 'Location access required before booking a ride.'));
      return;
    }
    if (_pickupPoint == null || _dropPoint == null) return;

    setState(() => _isCreatingRide = true);

    final result = await RideshareService.createRide(
      pickupLatitude: _pickupPoint!.latitude,
      pickupLongitude: _pickupPoint!.longitude,
      dropLatitude: _dropPoint!.latitude,
      dropLongitude: _dropPoint!.longitude,
      vehicleType: _selectedVehicleType,
      pickupAddress: _pickupPoint!.name,
      dropAddress: _dropPoint!.name,
      paymentMethod: _selectedPaymentMethod,
    );

    if (mounted) {
      setState(() => _isCreatingRide = false);

      if (result.success && result.data != null) {
        _applyRideState(result.data, isLoading: false);
        _showSuccess(t('rideshare_ride_requested',
            fallback: 'Ride requested! Looking for a driver...'));
      } else {
        final msg = result.message.toLowerCase();
        if (msg.contains('active ride') || msg.contains('already have')) {
          // Hide booking form with spinner. Use the ride_id from the error
          // response to fetch the specific ride directly Ã¢â‚¬â€ more reliable than
          // calling getActiveRide which can sometimes return null.
          setState(() => _isLoadingActiveRide = true);
          final rideId = result.errors is Map
              ? result.errors['ride_id']?.toString()
              : null;
          if (rideId != null && rideId.isNotEmpty) {
            _loadActiveRideById(rideId);
          } else {
            _loadActiveRide();
          }
        } else {
          _showError(result.message);
        }
      }
    }
  }

  Future<void> _confirmCancelRide() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(t('rideshare_cancel_ride_title', fallback: 'Cancel Ride?'),
            style:
                GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          t('rideshare_cancel_ride_confirm',
              fallback:
                  'Are you sure you want to cancel? You can book a new ride after cancellation.'),
          style:
              GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('rideshare_keep_ride', fallback: 'Keep Ride'),
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6366F1))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(t('rideshare_yes_cancel', fallback: 'Yes, Cancel'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) _cancelRide();
  }

  Future<void> _cancelRide() async {
    if (_activeRide == null) return;

    // Snapshot the id so a socket race that mutates _activeRide mid-cancel
    // cannot redirect the cancel call to a different ride.
    final rideIdToCancel = _activeRide!.id;

    // Disconnect realtime immediately to prevent incoming events from
    // overwriting state while the cancel API call is in flight.
    _rideEventSubscription?.cancel();
    _rideEventSubscription = null;
    _realtimeService.disconnectRide();

    setState(() => _isCancellingRide = true);

    final result = await RideshareService.cancelRide(
      rideIdToCancel,
      reason: 'Cancelled by passenger',
    );

    if (mounted) {
      setState(() => _isCancellingRide = false);

      if (result.success) {
        // Clear active ride AND reset the booking form so user starts fresh
        setState(() {
          _activeRide = null;
          _pickupPoint = null;
          _dropPoint = null;
          _estimate = null;
          _activeRoutePreview = null;
          _activeRouteSignature = '';
          _nearbyDrivers = [];
          _pickupSuggestions = [];
          _dropSuggestions = [];
          _activeInput = 'pickup';
          _searchStatusMessage = t('rideshare_finding_driver_status',
              fallback: 'Looking for nearby drivers...');
          _noDriversInRange = false;
          _targetedAtFromEvent = null;
          _dispatchAttempt = 0;
        });
        _pickupController.clear();
        _dropController.clear();
        _showSuccess(t('rideshare_ride_cancelled', fallback: 'Ride cancelled'));
      } else {
        // Reconnect realtime so the user can keep receiving ride updates
        _syncRideRealtimeConnection();
        _showError(result.message);
      }
    }
  }

  bool _canChatWithDriver(Ride ride) {
    return ride.assignedDriver != null &&
        (ride.isAccepted ||
            ride.isDriverArriving ||
            ride.isInProgress ||
            ride.isAwaitingPassengerConfirmation);
  }

  Future<void> _openDriverChat(Ride ride) async {
    final driver = ride.assignedDriver;
    if (driver == null || driver.userId.isEmpty) {
      _showError('Driver chat is unavailable right now.');
      return;
    }

    var loadingDialogShown = false;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      loadingDialogShown = true;

      final chatroom =
          await AdsyConnectService.getOrCreateChatRoom(driver.userId);
      final chatroomId = chatroom['id']?.toString();
      if (chatroomId == null || chatroomId.isEmpty) {
        throw Exception('Chat room unavailable');
      }

      if (mounted && loadingDialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingDialogShown = false;
      }

      if (!mounted) return;
      AdsyConnectChatInterface.open(
        context,
        chatroomId: chatroomId,
        userId: driver.userId,
        userName: driver.userName,
        userAvatar: driver.userAvatar,
        profession: 'Driver',
        isOnline: driver.isOnline,
      );
    } catch (_) {
      if (mounted && loadingDialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showError('Unable to open driver chat right now.');
    }
  }

  void _openBusinessProfile(String userId) {
    if (userId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)),
    );
  }

  Future<void> _reportDriverCancellation() async {
    final ride = _activeRide;
    if (ride == null || !ride.canReportDriver || _isReportingCancellation) {
      return;
    }

    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          t('rideshare_report_driver_cancellation',
              fallback: 'Report Driver Cancellation'),
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: t('rideshare_add_details_hint',
                fallback: 'Add details for support...'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('rideshare_close', fallback: 'Close'),
                style: GoogleFonts.inter()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('rideshare_submit', fallback: 'Submit'),
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _isReportingCancellation = true);
    final result = await RideshareService.reportDriverCancellation(
      ride.id,
      details: controller.text.trim(),
    );
    if (!mounted) return;

    setState(() => _isReportingCancellation = false);
    if (result.success) {
      setState(() {
        _activeRide = _activeRide?.copyWith(canReportDriver: false);
      });
      _showSuccess('Driver report submitted successfully.');
    } else {
      _showError(result.message);
    }
  }

  RidePoint? _currentDriverPoint(Ride ride) {
    if (ride.latestDriverLocation != null) {
      return RidePoint(
        name: 'Driver',
        latitude: ride.latestDriverLocation!.latitude,
        longitude: ride.latestDriverLocation!.longitude,
      );
    }
    if (ride.assignedDriver?.currentLatitude != null &&
        ride.assignedDriver?.currentLongitude != null) {
      return RidePoint(
        name: 'Driver',
        latitude: ride.assignedDriver!.currentLatitude!,
        longitude: ride.assignedDriver!.currentLongitude!,
      );
    }
    return null;
  }

  bool _supportsPassengerSmartRoute(Ride ride) {
    return ride.isAccepted ||
        ride.isDriverArriving ||
        ride.isInProgress ||
        ride.isAwaitingPassengerConfirmation;
  }

  RidePoint? _resolvePassengerRouteOrigin(Ride ride) {
    return _currentDriverPoint(ride);
  }

  RidePoint? _resolvePassengerRouteDestination(Ride ride) {
    if (ride.isAccepted || ride.isDriverArriving) {
      return ride.pickupPoint;
    }
    if (ride.isInProgress || ride.isAwaitingPassengerConfirmation) {
      return ride.dropPoint;
    }
    return null;
  }

  String _passengerRoutePointSignature(RidePoint? point) {
    if (point == null) return 'none';
    return '${point.latitude.toStringAsFixed(3)},${point.longitude.toStringAsFixed(3)}';
  }

  Future<void> _refreshPassengerRoutePreview({bool force = false}) async {
    final ride = _activeRide;
    if (ride == null || !_supportsPassengerSmartRoute(ride)) {
      if (!mounted) return;
      if (_activeRoutePreview != null ||
          _activeRouteSignature.isNotEmpty ||
          _isLoadingActiveRoute) {
        setState(() {
          _activeRoutePreview = null;
          _activeRouteSignature = '';
          _isLoadingActiveRoute = false;
        });
      }
      return;
    }

    final origin = _resolvePassengerRouteOrigin(ride);
    final destination = _resolvePassengerRouteDestination(ride);
    if (origin == null || destination == null) {
      return;
    }

    final signature =
        '${ride.id}|${ride.status}|${_passengerRoutePointSignature(origin)}|${_passengerRoutePointSignature(destination)}';
    if (!force &&
        (_isLoadingActiveRoute || signature == _activeRouteSignature)) {
      return;
    }

    if (mounted) {
      setState(() => _isLoadingActiveRoute = true);
    }

    final result = await RideshareService.previewRoute(
      originLatitude: origin.latitude,
      originLongitude: origin.longitude,
      destinationLatitude: destination.latitude,
      destinationLongitude: destination.longitude,
      originAddress: origin.name,
      destinationAddress: destination.name,
    );

    if (!mounted) {
      return;
    }

    if (_activeRide?.id != ride.id) {
      setState(() => _isLoadingActiveRoute = false);
      return;
    }

    setState(() {
      _isLoadingActiveRoute = false;
      if (result.success && result.data != null) {
        _activeRoutePreview = result.data;
        _activeRouteSignature = signature;
      }
    });
  }

  double _currentPassengerDistanceKm(Ride ride) {
    return _activeRoutePreview?.distanceKm ?? ride.distanceKm;
  }

  String _currentPassengerEta(Ride ride) {
    return _activeRoutePreview?.etaDisplay ?? ride.etaDisplay;
  }

  Map<String, dynamic>? _currentPassengerRouteGeometry(Ride ride) {
    return _activeRoutePreview?.routeGeometry ?? ride.routeGeometry;
  }

  Future<void> _confirmEarlyCompletion(bool confirm) async {
    final ride = _activeRide;
    if (ride == null) return;

    String paymentMethod = 'wallet';
    if (confirm) {
      final selectedMethod = await _selectPaymentMethod(ride);
      if (selectedMethod == null) {
        return;
      }
      paymentMethod = selectedMethod;
    }

    setState(() => _isLoadingActiveRide = true);
    final result = await RideshareService.confirmEarlyCompletion(
      ride.id,
      confirm: confirm,
      paymentMethod: paymentMethod,
    );
    if (!mounted) return;

    if (result.success && result.data != null) {
      _applyRideState(result.data, isLoading: false);
      _showSuccess(
        confirm
            ? (paymentMethod == 'cash'
                ? t('rideshare_cash_completion_note',
                    fallback: 'Ride complete. Please pay the driver in cash.')
                : t('rideshare_wallet_completion_note',
                    fallback: 'Ride complete and wallet payment confirmed.'))
            : 'Ride will continue until you confirm completion.',
      );
      return;
    }

    setState(() => _isLoadingActiveRide = false);
    _showError(result.message);
  }

  Future<String?> _selectPaymentMethod(Ride ride) async {
    final payableFare = ride.payableFare;
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('rideshare_choose_payment_method',
                    fallback: 'Choose Payment Method'),
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '${t('rideshare_trip_fare', fallback: 'Trip Fare')}: à§³${payableFare.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              _buildPaymentMethodTile(
                ctx,
                value: 'wallet',
                title: t('rideshare_wallet_payment_title',
                    fallback: 'Pay with Adsy Balance'),
                subtitle: t('rideshare_wallet_subtitle',
                    fallback:
                        'Fare will be deducted from your in-app balance instantly.'),
                icon: Icons.account_balance_wallet_rounded,
                accent: const Color(0xFF6366F1),
              ),
              const SizedBox(height: 10),
              _buildPaymentMethodTile(
                ctx,
                value: 'cash',
                title: t('rideshare_cash_payment_title',
                    fallback: 'Pay Driver in Cash'),
                subtitle: t('rideshare_cash_subtitle',
                    fallback:
                        'You will pay the driver directly in cash at the end of the ride.'),
                icon: Icons.payments_rounded,
                accent: const Color(0xFF10B981),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMapTap(double latitude, double longitude) async {
    final result = await RideshareService.reverseGeocode(latitude, longitude);
    if (!mounted || !result.success || result.data == null) return;

    final point = result.data!;
    await _rememberRecentPlace(point);
    setState(() {
      if (_bookingStep == 1) {
        // Map tap on pickup step
        _pickupPoint = point;
        _pickupController.text = point.name;
        _pickupSuggestions = [];
        _activeInput = '';
        _bookingStep = 2;
        _loadNearbyDrivers();
      } else {
        // Map tap on drop step
        _dropPoint = point;
        _dropController.text = point.name;
        _dropSuggestions = [];
        _hideDropSuggestionsUntilEdit = true;
        _activeInput = 'pickup';
        _bookingStep = 1;
      }
    });
    _requestEstimate();
  }

  void _showError(String message) {
    if (!mounted) return;
    final resolvedMessage =
        _localizeDisplayMessage(_resolveErrorMessage(message));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(resolvedMessage, style: GoogleFonts.inter(fontSize: 13)),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  String? _driverMapVehicleInfo(Ride ride) {
    final driver = ride.assignedDriver;
    final vehicle = ride.vehicle ?? driver?.defaultVehicle;
    if (driver == null || vehicle == null) {
      return null;
    }

    final registration = vehicle.registrationNumber.trim();
    if (registration.isEmpty) {
      return vehicle.displayName;
    }

    return '${vehicle.vehicleIcon} $registration';
  }

  String _resolveErrorMessage(String message) {
    final raw = message.trim();
    if (raw.isEmpty) {
      return 'কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।';
    }

    final lower = raw.toLowerCase();
    const technicalHints = [
      'exception',
      'clientexception',
      'formatexception',
      'socket',
      'network',
      'timeout',
      'unauthorized',
      'forbidden',
      'not found',
      'server error',
      'service unavailable',
      '401',
      '403',
      '404',
      '500',
      '503',
    ];

    if (technicalHints.any(lower.contains)) {
      return NetworkErrorHandler.getErrorMessage(raw);
    }

    return raw;
  }

  String _localizeDisplayMessage(String message) {
    final raw = message.trim();
    if (raw.isEmpty) {
      return 'কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।';
    }

    final lower = raw.toLowerCase();

    const exactMessages = {
      'connection error. please check your internet connection.':
          'ইন্টারনেট সংযোগে সমস্যা হয়েছে। আপনার সংযোগ পরীক্ষা করুন।',
      'unable to process response. please try again.':
          'রেসপন্স প্রক্রিয়া করা যায়নি। আবার চেষ্টা করুন।',
      'connection timeout. please try again.':
          'সংযোগের সময় শেষ হয়েছে। আবার চেষ্টা করুন।',
      'network connection issue. please check your internet.':
          'নেটওয়ার্কে সমস্যা হয়েছে। ইন্টারনেট সংযোগ পরীক্ষা করুন।',
      'request timed out. please try again.':
          'রিকোয়েস্টের সময় শেষ হয়েছে। আবার চেষ্টা করুন।',
      'session expired. please log in again.':
          'সেশন শেষ হয়েছে। আবার লগইন করুন।',
      "you don't have permission to perform this action.":
          'এই কাজটি করার অনুমতি আপনার নেই।',
      'requested resource not found.': 'চাওয়া তথ্য পাওয়া যায়নি।',
      'server error. please try again later.':
          'সার্ভারে সমস্যা হয়েছে। একটু পরে আবার চেষ্টা করুন।',
      'service temporarily unavailable. please try again later.':
          'সার্ভিস সাময়িকভাবে বন্ধ আছে। একটু পরে আবার চেষ্টা করুন।',
      'something went wrong. please try again.':
          'কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।',
      'location service is off. please enable gps to use rideshare.':
          'রাইডশেয়ার ব্যবহার করতে জিপিএস চালু করুন।',
      'location service is off. please enable gps to continue.':
          'চালিয়ে যেতে জিপিএস চালু করুন।',
      'location permission is required for rideshare.':
          'রাইডশেয়ার ব্যবহারের জন্য লোকেশন অনুমতি প্রয়োজন।',
      'location permission denied': 'লোকেশন অনুমতি দেওয়া হয়নি।',
      'location permission permanently denied. please enable it in app settings.':
          'লোকেশন অনুমতি স্থায়ীভাবে বন্ধ আছে। অ্যাপ সেটিংস থেকে চালু করুন।',
      'location permission permanently denied. please enable in settings.':
          'লোকেশন অনুমতি স্থায়ীভাবে বন্ধ আছে। সেটিংস থেকে চালু করুন।',
      'location enabled. pickup set from your current location.':
          'লোকেশন চালু হয়েছে। আপনার বর্তমান অবস্থান থেকে পিকআপ সেট করা হয়েছে।',
      'location found': 'লোকেশন পাওয়া গেছে।',
      'could not resolve location': 'লোকেশনের ঠিকানা বের করা যায়নি।',
      'no drivers available, please try again.':
          'কাছাকাছি কোনো ড্রাইভার পাওয়া যায়নি। আবার চেষ্টা করুন।',
      'driver chat is unavailable right now.':
          'ড্রাইভারের সাথে চ্যাট এখন পাওয়া যাচ্ছে না।',
      'unable to open driver chat right now.':
          'ড্রাইভার চ্যাট এখন খোলা যাচ্ছে না।',
      'driver report submitted successfully.':
          'ড্রাইভারের রিপোর্ট সফলভাবে পাঠানো হয়েছে।',
      'ride cancelled': 'রাইড বাতিল হয়েছে।',
      'looking for nearby drivers...': 'কাছাকাছি ড্রাইভার খোঁজা হচ্ছে...',
      'looking for a driver': 'ড্রাইভার খোঁজা হচ্ছে।',
      'driver confirmed': 'ড্রাইভার নিশ্চিত হয়েছে।',
      'ride requested! looking for a driver...':
          'রাইড রিকোয়েস্ট করা হয়েছে। ড্রাইভার খোঁজা হচ্ছে...',
      'ride complete. please pay the driver in cash.':
          'রাইড সম্পন্ন। ড্রাইভারকে নগদ পরিশোধ করুন।',
      'ride complete and wallet payment confirmed.':
          'রাইড সম্পন্ন এবং ওয়ালেট পেমেন্ট নিশ্চিত হয়েছে।',
      'you already have an active ride.':
          'আপনার ইতোমধ্যে একটি সক্রিয় রাইড আছে।',
      'ride requested successfully.': 'রাইড রিকোয়েস্ট সফলভাবে করা হয়েছে।',
      'no drivers available. ride cancelled automatically.':
          'কোনো ড্রাইভার পাওয়া যায়নি। রাইড স্বয়ংক্রিয়ভাবে বাতিল হয়েছে।',
    };

    final exact = exactMessages[lower];
    if (exact != null) {
      return exact;
    }

    if (lower.startsWith('failed to enable location')) {
      return 'লোকেশন চালু করতে সমস্যা হয়েছে। আবার চেষ্টা করুন।';
    }
    if (lower.startsWith('failed to get location')) {
      return 'লোকেশন নিতে সমস্যা হয়েছে। আবার চেষ্টা করুন।';
    }
    if (lower.startsWith('request sent to ')) {
      return 'রিকোয়েস্ট পাঠানো হয়েছে: ${raw.substring('Request sent to '.length)}';
    }

    return raw;
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_localizeDisplayMessage(message),
          style: GoogleFonts.inter(fontSize: 13)),
      backgroundColor: const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingActiveRide) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6366F1),
        ),
      );
    }

    // Active ride takes full priority Ã¢â‚¬â€ booking form is completely hidden
    if (_activeRide != null) {
      return RefreshIndicator(
        color: const Color(0xFF6366F1),
        onRefresh: _loadActiveRide,
        child: _buildActiveRideView(),
      );
    }

    // No active ride Ã¢â‚¬â€ show booking form
    return _buildBookingView();
  }
}
