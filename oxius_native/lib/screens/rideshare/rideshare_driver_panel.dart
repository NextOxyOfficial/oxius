import 'dart:async';
import '../../widgets/location_disclosure_dialog.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import '../../models/rideshare_models.dart';
import '../../services/adsyconnect_service.dart';
import '../../services/rideshare_driver_presence_service.dart';
import '../../services/fcm_service.dart';
import '../../services/rideshare_service.dart';
import '../../services/rideshare_realtime_service.dart';
import '../../services/auth_service.dart';
import '../../services/translation_service.dart';
import '../../utils/image_compressor.dart';
import '../../utils/network_error_handler.dart';
import '../adsy_connect_chat_interface.dart';
import '../business_network/profile_screen.dart';
import 'rideshare_map_widget.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';
import 'package:oxius_native/widgets/common/adsy_pro_badge.dart';

part 'rideshare_driver_panel_profile.dart';
part 'rideshare_driver_panel_requests.dart';
part 'rideshare_driver_panel_active_ride.dart';

// Design tokens
const _indigo = Color(0xFF6366F1);
const _emerald = Color(0xFF10B981);
const _emeraldDark = Color(0xFF059669);
const _slate50 = Color(0xFFF8FAFC);
const _slate100 = Color(0xFFF1F5F9);
const _slate200 = Color(0xFFE2E8F0);
const _slate300 = Color(0xFFCBD5E1);
const _slate400 = Color(0xFF94A3B8);
const _slate500 = Color(0xFF64748B);
const _slate600 = Color(0xFF475569);
const _slate800 = Color(0xFF1E293B);

class RideshareDriverPanel extends StatefulWidget {
  const RideshareDriverPanel({super.key});

  @override
  State<RideshareDriverPanel> createState() => _RideshareDriverPanelState();
}

class _RideshareDriverPanelState extends State<RideshareDriverPanel>
    with WidgetsBindingObserver {
  final TranslationService _ts = TranslationService();
  /// setState relay for the part-file extensions — calling the protected
  /// setState directly from an extension violates @protected even inside the
  /// same library.
  void _rebuild(VoidCallback fn) => setState(fn);

  String t(String key, {required String fallback}) =>
      _ts.t(key, fallback: fallback);

  DriverProfile? _driverProfile;
  Ride? _activeRide;
  List<Ride> _availableRequests = [];
  DriverEarningsSummary? _earnings;

  bool _isLoading = true;
  bool _isTogglingOnline = false;
  bool _isAcceptingRide = false;
  final Set<String> _skippingRideIds = <String>{};
  bool _isUpdatingStatus = false;
  bool _isPayingCashDues = false;
  bool _isAuthError = false;
  bool _isSavingProfile = false;
  bool _locationGranted = false;
  bool _hasForegroundLocationPermission = false;
  bool _needsBackgroundLocationUpgrade = false;
  bool _isCheckingLocationPermission = true;
  bool _isRequestingLocationPermission = false;
  bool _pendingOnlineAfterPermission = false;
  bool _isProfileExpanded = true;
  bool _profileExpansionInitialized = false;
  bool _alertReadinessChecked = false;

  final _licenseController = TextEditingController();
  final _nidController = TextEditingController();
  final _driverDetailsController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  List<String> _additionalDocuments = [];
  List<String> _additionalDocumentLabels = [];
  double _serviceRadius = 8.0;
  double _maxRideDistance = 0.0;

  Timer? _refreshTimer;
  Timer? _activeRideRefreshTimer;
  Timer? _countdownTimer;
  Timer? _incomingRideAlertTimer;
  Timer? _incomingRideAlertStopTimer;
  final RideshareRealtimeService _realtimeService = RideshareRealtimeService();
  StreamSubscription<Map<String, dynamic>>? _dispatchEventSubscription;
  StreamSubscription<Map<String, dynamic>>? _rideEventSubscription;
  StreamSubscription<Map<String, dynamic>>? _rideshareNotificationSubscription;
  StreamSubscription<String>? _authFailureSubscription;
  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();
  bool _isRefreshingActiveRide = false;
  bool _incomingRideAlertActive = false;
  String? _incomingRideAlertRideId;

  // Live passenger location received via WebSocket
  RidePoint? _passengerLocation;
  // Throttle live passenger location updates: WebSocket can ping multiple
  // times per second, but the map only needs ~3 updates/sec to feel smooth.
  // Without throttling, every ping triggers a full Stack/Map rebuild.
  int _lastPassengerLocationSetStateAt = 0;
  Timer? _pendingPassengerLocationTimer;
  double? _latestPassengerLat;
  double? _latestPassengerLng;
  static const int _passengerLocationMinIntervalMs = 300;
  static const double _passengerLocationMinMoveMeters = 5.0;
  RidePoint? _driverCurrentPoint;
  RoutePreview? _smartRoutePreview;
  String _smartRouteSignature = '';
  bool _isLoadingSmartRoute = false;

  Ride? _resolveDriverActiveRide(DriverProfile? profile, Ride? ride) {
    if (profile == null || ride == null) return null;
    final assignedDriverId = ride.assignedDriver?.userId ?? '';
    if (assignedDriverId.isEmpty) return null;
    return assignedDriverId == profile.userId ? ride : null;
  }

  RidePoint? _driverPointFromProfile(DriverProfile? profile) {
    final latitude = profile?.currentLatitude;
    final longitude = profile?.currentLongitude;
    if (latitude == null || longitude == null) {
      return null;
    }

    return RidePoint(
      name: t('rideshare_you', fallback: 'আপনি'),
      latitude: latitude,
      longitude: longitude,
    );
  }

  bool _canChatWithPassenger(Ride ride) {
    return ride.riderId.isNotEmpty &&
        (ride.isAccepted || ride.isDriverArriving || ride.isInProgress);
  }

  bool _hasSubmittedIdentity(DriverProfile? profile) {
    if (profile == null) return false;
    return profile.licenseNumber.trim().isNotEmpty ||
        profile.nationalIdNumber.trim().isNotEmpty;
  }

  bool get _licenseLocked =>
      (_driverProfile?.licenseNumber.trim().isNotEmpty ?? false);

  bool get _nidLocked =>
      (_driverProfile?.nationalIdNumber.trim().isNotEmpty ?? false);

  double _mapViewportHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeHeight = screenHeight - MediaQuery.of(context).padding.vertical;
    final preferredHeight = safeHeight * 0.78;
    return preferredHeight < 420 ? 420 : preferredHeight;
  }

  Widget _buildMapSectionFrame({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required Widget child,
    Color accentColor = _indigo,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EDF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.74)],
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
                    color: _slate800,
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
                  color: Colors.white.withValues(alpha: 0.76), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: _slate800.withValues(alpha: 0.08),
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

  void _initializeProfileExpansion(DriverProfile? profile) {
    if (_profileExpansionInitialized) return;
    _isProfileExpanded = !_hasSubmittedIdentity(profile);
    _profileExpansionInitialized = true;
  }

  Future<void> _openVehicles() async {
    await Navigator.pushNamed(context, '/rideshare/vehicles');
    if (mounted) {
      _loadDriverData();
    }
  }

  bool _hasEligibleVehicle(DriverProfile? profile) {
    if (profile == null) return false;
    return profile.defaultVehicle != null ||
        profile.vehicles.any((vehicle) => vehicle.isActive);
  }

  Future<void> _showMissingVehicleInstruction() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('rideshare_add_vehicle_first', fallback: 'আগে একটি গাড়ি যোগ করুন'),
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Text(
          t('rideshare_need_vehicle_msg',
              fallback:
                  'You need an active vehicle. Add a Bike, Car or Auto from the Vehicles section.'),
          style:
              GoogleFonts.inter(fontSize: 13, color: _slate500, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              t('rideshare_close', fallback: 'বন্ধ করুন'),
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _openVehicles();
            },
            icon: const Icon(Icons.two_wheeler_rounded, size: 16),
            label: Text(
              t('rideshare_open_vehicles', fallback: 'গাড়ি পেজ খুলুন'),
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _ts.addListener(_onTranslationsChanged);
    WidgetsBinding.instance.addObserver(this);
    RideshareDriverPresenceService.positionNotifier.addListener(
      _handlePresencePositionChanged,
    );
    _rideshareNotificationSubscription =
        FCMService.rideshareNotificationEvents.listen(
      _handleRideshareNotificationEvent,
    );
    _authFailureSubscription = _realtimeService.authFailure.listen((reason) {
      if (!mounted) return;
      // Probe auth via HTTP — if the user is still authenticated this will
      // refresh the active ride and we can safely retry the socket.
      unawaited(_realtimeService.retryAfterAuthFailure());
    });
    _refreshLocationPermissionStatus();
    _handlePresencePositionChanged();
    _loadDriverData();
    _startRefreshTimer();
    _startActiveRideRefreshTimer();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _ts.removeListener(_onTranslationsChanged);
    WidgetsBinding.instance.removeObserver(this);
    RideshareDriverPresenceService.positionNotifier.removeListener(
      _handlePresencePositionChanged,
    );
    _refreshTimer?.cancel();
    _activeRideRefreshTimer?.cancel();
    _countdownTimer?.cancel();
    _pendingPassengerLocationTimer?.cancel();
    _cancelIncomingRideAlertLocally();
    _ringtonePlayer.stop();
    Vibration.cancel();
    _dispatchEventSubscription?.cancel();
    _rideEventSubscription?.cancel();
    _rideshareNotificationSubscription?.cancel();
    _authFailureSubscription?.cancel();
    _realtimeService.dispose();
    _licenseController.dispose();
    _nidController.dispose();
    _driverDetailsController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground — refresh location permission,
      // reconnect WebSocket, and reload pending ride requests so the
      // driver sees requests that arrived while the app was backgrounded.
      _refreshLocationPermissionStatus().then((_) {
        if (mounted) {
          unawaited(_resumePendingOnlineIfReady());
        }
      });
      if (_driverProfile?.isOnline == true) {
        _syncRealtimeConnections();
        _loadAvailableRequests();
        if (_activeRide != null) {
          // Lightweight active-ride refresh without a full profile reload
          RideshareService.getActiveRide().then((result) {
            if (!mounted) {
              return;
            }
            setState(() {
              _activeRide =
                  _resolveDriverActiveRide(_driverProfile, result.data);
              if (_activeRide == null) {
                _passengerLocation = null;
              }
            });
            _syncRealtimeConnections();
            if (_activeRide == null) {
              _loadAvailableRequests();
            }
          });
        }
      }
    }
  }

  void _handlePresencePositionChanged() {
    final position = RideshareDriverPresenceService.positionNotifier.value;
    if (!mounted || position == null) {
      return;
    }

    setState(() {
      _driverCurrentPoint = RidePoint(
        name: t('rideshare_you', fallback: 'আপনি'),
        latitude: position.latitude,
        longitude: position.longitude,
      );
    });
    _refreshSmartRoutePreview();
  }

  Future<bool> _refreshLocationPermissionStatus(
      {bool syncTracking = true}) async {
    if (mounted) {
      setState(() => _isCheckingLocationPermission = true);
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission =
          await RideshareDriverPresenceService.getLocationPermission();
      final hasForegroundPermission = serviceEnabled &&
          RideshareDriverPresenceService.isForegroundPermissionGranted(
              permission);
      final granted = serviceEnabled &&
          RideshareDriverPresenceService.isBackgroundPermissionGranted(
              permission);

      if (mounted) {
        setState(() {
          _hasForegroundLocationPermission = hasForegroundPermission;
          _needsBackgroundLocationUpgrade = hasForegroundPermission && !granted;
          _locationGranted = granted;
          _isCheckingLocationPermission = false;
        });
      }

      if (!granted) {
        _stopLocationTracking();
      } else if (syncTracking && _driverProfile?.isOnline == true) {
        await _startLocationTracking();
      }

      return granted;
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasForegroundLocationPermission = false;
          _needsBackgroundLocationUpgrade = false;
          _locationGranted = false;
          _isCheckingLocationPermission = false;
        });
      }
      _stopLocationTracking();
      return false;
    }
  }

  Future<bool> _showDriverLocationGuide(
      {required bool goOnlineAfterSetup}) async {
    if (!mounted) {
      return false;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'লোকেশন সেটআপ কমপ্লিট করুন',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _slate800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'অ্যাপ ব্যাকগ্রাউন্ডে থাকলেও অনলাইনে থাকতে এবং রাইড রিকোয়েস্ট পেতে অ্যাপ সেটিংস থেকে সবসময় লোকেশন অনুমতি দিন।',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _slate500,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _slate50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _slate200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'দ্রুত ধাপ',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _slate800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '১. অ্যাপ সেটিংস খুলুন\n২. Permissions> Location এ চাপুন\n৩. Allow All the Time নির্বাচন করুন\n৪. আবার এখানে ফিরে আসুন',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _slate600,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: _slate200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'এখন নয়',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: _slate600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: _indigo,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        goOnlineAfterSetup
                            ? 'সেটিংস খুলুন'
                            : 'সেটআপ কমপ্লিট করুন',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return result ?? false;
  }

  Future<void> _openDriverLocationSettingsGuide({
    bool goOnlineAfterSetup = false,
  }) async {
    final shouldOpenSettings = await _showDriverLocationGuide(
      goOnlineAfterSetup: goOnlineAfterSetup,
    );
    if (!shouldOpenSettings) {
      return;
    }

    _pendingOnlineAfterPermission = goOnlineAfterSetup;
    await Geolocator.openAppSettings();
  }

  Future<void> _resumePendingOnlineIfReady() async {
    if (!_pendingOnlineAfterPermission ||
        _isTogglingOnline ||
        _driverProfile == null ||
        _driverProfile!.isOnline ||
        !_locationGranted) {
      return;
    }

    _pendingOnlineAfterPermission = false;
    await _toggleOnline(skipPermissionCheck: true);
  }

  Future<bool> _requestLocationPermission() async {
    if (_isRequestingLocationPermission) return false;

    setState(() => _isRequestingLocationPermission = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError(
            'Location service is off. Please enable GPS before going online.');
        await Geolocator.openLocationSettings();
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Play Policy: show prominent disclosure (background use) BEFORE the
        // OS prompt. Driver mode streams live location, incl. in background.
        if (!mounted) return false;
        final consented =
            await LocationDisclosure.ensure(context, background: true);
        if (!consented) {
          _showError('ড্রাইভার মোড ব্যবহার করতে লোকেশন অনুমতি প্রয়োজন।');
          return false;
        }
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showError('Location permission is required to use driver mode.');
        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        _showError(
            'Location permission permanently denied. Please enable it in app settings.');
        await Geolocator.openAppSettings();
        return false;
      }

      if (!RideshareDriverPresenceService.isBackgroundPermissionGranted(
          permission)) {
        setState(() {
          _hasForegroundLocationPermission = true;
          _needsBackgroundLocationUpgrade = true;
          _locationGranted = false;
        });
        await _openDriverLocationSettingsGuide(goOnlineAfterSetup: true);
        return false;
      }

      if (mounted) {
        setState(() {
          _hasForegroundLocationPermission = true;
          _needsBackgroundLocationUpgrade = false;
          _locationGranted = true;
        });
      }
      return true;
    } catch (e) {
      _showError('Failed to enable location: $e');
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingLocationPermission = false;
          _isCheckingLocationPermission = false;
        });
      }
    }
  }

  void _onTranslationsChanged() {
    if (mounted) setState(() {});
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted && _driverProfile?.isOnline == true && _activeRide == null) {
        _loadAvailableRequests();
      }
      // Keep last_seen_at fresh on the server so the staleness task does not
      // auto-offline a driver who is online but temporarily stationary.
      if (mounted && _driverProfile?.isOnline == true) {
        RideshareService.sendDriverHeartbeat();
      }
    });
  }

  void _startActiveRideRefreshTimer() {
    _activeRideRefreshTimer?.cancel();
    _activeRideRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted ||
          _activeRide == null ||
          _isUpdatingStatus ||
          _isAcceptingRide) {
        return;
      }
      _refreshActiveRideSilently();
    });
  }

  Future<void> _refreshActiveRideSilently() async {
    final rideId = _activeRide?.id;
    if (_isRefreshingActiveRide || rideId == null || rideId.isEmpty) {
      return;
    }

    _isRefreshingActiveRide = true;
    try {
      final result = await RideshareService.getRide(rideId);
      if (!mounted) {
        return;
      }

      final refreshedRide = result.data;
      if (!result.success || refreshedRide == null) {
        return;
      }

      if (refreshedRide.isCompleted || refreshedRide.isCancelled) {
        setState(() {
          _activeRide = null;
          _passengerLocation = null;
          _smartRoutePreview = null;
          _smartRouteSignature = '';
        });
        _syncRealtimeConnections();
        _loadAvailableRequests();
        _loadDriverData();
        _showSuccess(
          refreshedRide.isCompleted
              ? t('rideshare_ride_completed', fallback: 'রাইড সম্পন্ন!')
              : t('rideshare_ride_cancelled', fallback: 'রাইড বাতিল হয়েছে'),
        );
        return;
      }

      if (_activeRide?.updatedAt == refreshedRide.updatedAt) {
        return;
      }

      setState(() => _activeRide = refreshedRide);
      _refreshSmartRoutePreview();
    } finally {
      _isRefreshingActiveRide = false;
    }
  }

  Future<void> _handleRideshareNotificationEvent(
    Map<String, dynamic> payload,
  ) async {
    if (!mounted) {
      return;
    }

    final mode = payload['mode']?.toString();
    if (mode != 'driver') {
      return;
    }

    final rawType = payload['type']?.toString() ?? '';
    final notificationType = payload['notification_type']?.toString() ?? '';
    final source = payload['source']?.toString();
    final isRideRequestNotification =
        notificationType == 'targeted_ride_request' ||
            notificationType == 'new_ride_request';
    final effectiveType = isRideRequestNotification
        ? notificationType
        : (rawType.isNotEmpty ? rawType : notificationType);
    final rideId = payload['ride_id']?.toString() ?? '';
    // Always play the in-app ringtone for incoming ride requests while the
    // driver panel is mounted — regardless of whether the event arrived via
    // the realtime socket or FCM. Previously we skipped FCM-sourced events
    // assuming the OS notification would ring, but FCM only plays a short
    // default notification tone, not a continuous ringtone. The in-app
    // ringtone (flutter_ringtone_player, asAlarm: true, looping) is the only
    // reliable audible alert when the driver is on the rideshare screen.
    if (_activeRide == null &&
        (effectiveType == 'targeted_ride_request' ||
            effectiveType == 'new_ride_request')) {
      unawaited(_playIncomingRideAlert(rideId: rideId));
    }
    // Source is retained for future routing decisions.
    if (source == 'fcm') {
      // no-op — kept for readability / future branching.
    }

    if (rideId.isNotEmpty) {
      final result = await RideshareService.getRide(rideId);
      if (!mounted || !result.success || result.data == null) {
        return;
      }

      final resolvedRide =
          _resolveDriverActiveRide(_driverProfile, result.data);
      if (resolvedRide != null) {
        await _stopIncomingRideAlert();
        setState(() {
          _activeRide = resolvedRide;
          _availableRequests = [];
        });
        _syncRealtimeConnections();
        _refreshSmartRoutePreview(force: true);
        return;
      }
    }

    if (_activeRide != null) {
      await _refreshActiveRideSilently();
      return;
    }

    if (_driverProfile?.isOnline == true) {
      await _loadAvailableRequests();
    }
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || (_availableRequests.isEmpty && _activeRide == null)) {
        return;
      }

      final hadExpiredRequests = _removeExpiredTargetedRequests();
      if (!hadExpiredRequests && mounted) {
        setState(() {});
      }
    });
  }

  bool _isRequestExpired(Ride ride) {
    return ride.targetedDriver != null && ride.targetedCountdownSeconds() <= 0;
  }

  bool _removeExpiredTargetedRequests() {
    final before = _availableRequests.length;
    final filtered =
        _availableRequests.where((ride) => !_isRequestExpired(ride)).toList();

    if (filtered.length == before) {
      return false;
    }

    if (filtered.isEmpty) {
      unawaited(_stopIncomingRideAlert());
    }

    setState(() {
      _availableRequests = filtered;
      _skippingRideIds.removeWhere(
        (rideId) => !_availableRequests.any((ride) => ride.id == rideId),
      );
    });
    return true;
  }

  Future<void> _loadDriverData() async {
    setState(() {
      _isLoading = true;
      _isAuthError = false;
    });
    if (!AuthService.isAuthenticated) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isAuthError = true;
          _driverProfile = null;
        });
      }
      return;
    }
    final results = await Future.wait([
      RideshareService.getDriverProfile(),
      RideshareService.getActiveRide(),
      RideshareService.getDriverEarningsSummary(),
    ]);
    final profileResult = results[0] as RideshareApiResult<DriverProfile>;
    final activeRideResult = results[1] as RideshareApiResult<Ride?>;
    final earningsResult =
        results[2] as RideshareApiResult<DriverEarningsSummary>;
    final resolvedActiveRide = _resolveDriverActiveRide(
      profileResult.data,
      activeRideResult.data,
    );
    final msg = profileResult.message.toLowerCase();
    final authFailed = !profileResult.success &&
        (msg.contains('unauthorized') ||
            msg.contains('credentials') ||
            msg.contains('authentication') ||
            msg.contains('not provided'));
    if (mounted) {
      setState(() {
        _isAuthError = authFailed;
        _driverProfile = profileResult.data;
        _activeRide = resolvedActiveRide;
        _earnings = earningsResult.data;
        _driverCurrentPoint =
            RideshareDriverPresenceService.positionNotifier.value != null
                ? RidePoint(
                    name: t('rideshare_you', fallback: 'আপনি'),
                    latitude: RideshareDriverPresenceService
                        .positionNotifier.value!.latitude,
                    longitude: RideshareDriverPresenceService
                        .positionNotifier.value!.longitude,
                  )
                : _driverPointFromProfile(profileResult.data);
        _isLoading = false;
      });
      if (profileResult.data != null) {
        _licenseController.text = profileResult.data!.licenseNumber;
        _nidController.text = profileResult.data!.nationalIdNumber;
        _driverDetailsController.text = profileResult.data!.driverDetails;
        _additionalDocuments =
            List<String>.from(profileResult.data!.additionalDocuments);
        _additionalDocumentLabels = List<String>.generate(
          _additionalDocuments.length,
          (i) => 'Document ${i + 1}',
        );
        _serviceRadius = profileResult.data!.serviceRadiusKm;
        _maxRideDistance = profileResult.data!.maxRideDistanceKm;
        _initializeProfileExpansion(profileResult.data);
      } else {
        _licenseController.clear();
        _nidController.clear();
        _driverDetailsController.clear();
        _additionalDocuments = [];
        _additionalDocumentLabels = [];
      }
      if (_driverProfile?.isOnline == true) {
        await _startLocationTracking();
        if (_activeRide == null) _loadAvailableRequests();
      }
      _syncRealtimeConnections();
      _refreshSmartRoutePreview(force: true);
    }
  }

  void _syncRealtimeConnections() {
    RideshareDriverPresenceService.setActiveRideId(_activeRide?.id);

    final canReceiveDispatch =
        _driverProfile?.isOnline == true && _activeRide == null;
    if (canReceiveDispatch) {
      _dispatchEventSubscription ??=
          _realtimeService.dispatchEvents.listen(_handleDispatchEvent);
      _realtimeService.connectDriverDispatch();
    } else {
      _dispatchEventSubscription?.cancel();
      _dispatchEventSubscription = null;
      _realtimeService.disconnectDriverDispatch();
    }

    if (_activeRide != null) {
      _rideEventSubscription ??=
          _realtimeService.rideEvents.listen(_handleActiveRideEvent);
      _realtimeService.connectRide(_activeRide!.id);
    } else {
      _rideEventSubscription?.cancel();
      _rideEventSubscription = null;
      _realtimeService.disconnectRide();
    }
  }

  Future<void> _handleDispatchEvent(Map<String, dynamic> event) async {
    if (!mounted) return;

    final type = event['type']?.toString() ?? '';

    // Reconnect recovery: reload available requests so any ride that was
    // dispatched while the dispatch socket was reconnecting is not lost.
    if (type == 'connection.established') {
      if (_driverProfile?.isOnline == true && _activeRide == null) {
        await _loadAvailableRequests();
      }
      return;
    }

    if (type == 'ride.targeted') {
      // The fetch is what puts the request on screen — it must not sit in
      // line behind the ringtone player spinning up. Run both at once.
      final loading = _loadAvailableRequests();
      unawaited(_playIncomingRideAlert(rideId: event['ride_id']?.toString()));
      await loading;
      _showSuccess('নতুন রাইড রিকোয়েস্ট এসেছে!');
      return;
    }

    if (type == 'ride.event') {
      await _loadAvailableRequests();
    }
  }

  /// Throttle live passenger.location updates from the ride socket.
  /// Multiple pings per second otherwise trigger a full rebuild + smart
  /// route recompute for every event. We coalesce them into one update
  /// every [_passengerLocationMinIntervalMs] ms, AND skip updates where
  /// the passenger has moved less than [_passengerLocationMinMoveMeters].
  void _scheduleThrottledPassengerLocationUpdate(double lat, double lng) {
    _latestPassengerLat = lat;
    _latestPassengerLng = lng;

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - _lastPassengerLocationSetStateAt;

    void applyUpdate() {
      if (!mounted) return;
      final newLat = _latestPassengerLat;
      final newLng = _latestPassengerLng;
      if (newLat == null || newLng == null) return;

      final existing = _passengerLocation;
      if (existing != null) {
        // Crude great-circle distance — only needs to be accurate to ~1 m.
        const earthRadiusM = 6371000.0;
        final dLat = (newLat - existing.latitude) * 3.141592653589793 / 180;
        final dLng = (newLng - existing.longitude) * 3.141592653589793 / 180;
        final approxMeters =
            earthRadiusM * (dLat.abs() + dLng.abs() * 0.8); // good enough
        if (approxMeters < _passengerLocationMinMoveMeters) {
          return; // No meaningful movement — skip rebuild entirely.
        }
      }

      _lastPassengerLocationSetStateAt = DateTime.now().millisecondsSinceEpoch;
      setState(() {
        _passengerLocation = RidePoint(
          name: t('rideshare_passenger', fallback: 'যাত্রী'),
          latitude: newLat,
          longitude: newLng,
        );
      });
      _refreshSmartRoutePreview();
    }

    if (elapsed >= _passengerLocationMinIntervalMs) {
      _pendingPassengerLocationTimer?.cancel();
      _pendingPassengerLocationTimer = null;
      applyUpdate();
    } else {
      _pendingPassengerLocationTimer?.cancel();
      _pendingPassengerLocationTimer = Timer(
        Duration(milliseconds: _passengerLocationMinIntervalMs - elapsed),
        applyUpdate,
      );
    }
  }

  Future<void> _handleActiveRideEvent(Map<String, dynamic> event) async {
    if (!mounted || _activeRide == null) return;

    final type = event['type']?.toString() ?? '';

    // Reconnect recovery: when the ride socket re-establishes, immediately
    // fetch the current ride state to catch any transitions that arrived
    // while the socket was reconnecting (3-second gap).
    if (type == 'connection.established') {
      await _refreshActiveRideSilently();
      return;
    }

    // Handle live passenger location updates
    if (type == 'passenger.location') {
      final lat = double.tryParse(event['latitude']?.toString() ?? '');
      final lng = double.tryParse(event['longitude']?.toString() ?? '');
      if (lat != null && lng != null) {
        _scheduleThrottledPassengerLocationUpdate(lat, lng);
      }
      return;
    }

    if (type != 'ride.event') {
      return;
    }

    final rideId = event['ride_id']?.toString() ?? '';
    if (rideId.isEmpty) return;

    final result = await RideshareService.getRide(rideId);
    if (!mounted) return;

    if (result.success && result.data != null) {
      setState(() => _activeRide = result.data);
      if (_activeRide?.isCompleted == true ||
          _activeRide?.isCancelled == true) {
        await _stopIncomingRideAlert();
        setState(() {
          _passengerLocation = null;
          _smartRoutePreview = null;
          _smartRouteSignature = '';
        });
        _showSuccess(_activeRide!.isCompleted
            ? t('rideshare_ride_completed', fallback: 'রাইড সম্পন্ন!')
            : t('rideshare_ride_cancelled', fallback: 'রাইড বাতিল হয়েছে'));
      } else {
        _refreshSmartRoutePreview(force: true);
      }
      _syncRealtimeConnections();
    }
  }

  Future<void> _playIncomingRideAlert({String? rideId}) async {
    final normalizedRideId = rideId?.trim();
    if (_incomingRideAlertActive &&
        normalizedRideId != null &&
        normalizedRideId.isNotEmpty &&
        _incomingRideAlertRideId == normalizedRideId) {
      return;
    }

    try {
      await _stopIncomingRideAlert();
      _incomingRideAlertActive = true;
      _incomingRideAlertRideId =
          (normalizedRideId != null && normalizedRideId.isNotEmpty)
              ? normalizedRideId
              : null;

      if (await Vibration.hasVibrator()) {
        if (await Vibration.hasCustomVibrationsSupport()) {
          await Vibration.vibrate(pattern: const [0, 1200, 800], repeat: 0);
        } else {
          await Vibration.vibrate(duration: 1200);
          _incomingRideAlertTimer =
              Timer.periodic(const Duration(seconds: 2), (_) {
            Vibration.vibrate(duration: 1200);
          });
        }
      }
      _incomingRideAlertStopTimer = Timer(const Duration(minutes: 1), () {
        unawaited(_stopIncomingRideAlert());
      });
      await _ringtonePlayer.playRingtone(looping: true, asAlarm: true);
    } catch (_) {
      // Alert fallback is intentionally silent if the device blocks audio/vibration.
    }
  }

  void _cancelIncomingRideAlertLocally() {
    _incomingRideAlertTimer?.cancel();
    _incomingRideAlertTimer = null;
    _incomingRideAlertStopTimer?.cancel();
    _incomingRideAlertStopTimer = null;
    _incomingRideAlertActive = false;
    _incomingRideAlertRideId = null;
  }

  Future<void> _stopIncomingRideAlert() async {
    _cancelIncomingRideAlertLocally();

    try {
      await _ringtonePlayer.stop();
    } catch (_) {
      // Ignore ringtone stop failures.
    }

    try {
      await Vibration.cancel();
    } catch (_) {
      // Ignore vibration stop failures.
    }
  }

  Future<void> _loadAvailableRequests() async {
    final result = await RideshareService.listAvailableRideRequests();
    if (!mounted || !result.success) return;

    final requests =
        (result.data ?? []).where((ride) => !_isRequestExpired(ride)).toList();
    if (requests.isEmpty) {
      await _stopIncomingRideAlert();
    }
    setState(() => _availableRequests = requests);
  }

  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);

    final isNewApplication = _driverProfile == null;
    final RideshareApiResult<DriverProfile> result;

    if (isNewApplication) {
      result = await RideshareService.applyAsDriver(
        licenseNumber: _licenseController.text.trim(),
        nationalIdNumber: _nidController.text.trim(),
        driverDetails: _driverDetailsController.text.trim(),
        additionalDocuments: _additionalDocuments,
      );
    } else {
      result = await RideshareService.updateDriverProfile(
        licenseNumber: _licenseController.text.trim(),
        nationalIdNumber: _nidController.text.trim(),
        driverDetails: _driverDetailsController.text.trim(),
        additionalDocuments: _additionalDocuments,
        serviceRadiusKm: _serviceRadius,
        maxRideDistanceKm: _maxRideDistance,
      );
    }

    if (mounted) {
      setState(() => _isSavingProfile = false);
      if (result.success && result.data != null) {
        _licenseController.text = result.data!.licenseNumber;
        _nidController.text = result.data!.nationalIdNumber;
        _driverDetailsController.text = result.data!.driverDetails;
        setState(() {
          _driverProfile = result.data;
          _additionalDocuments =
              List<String>.from(result.data!.additionalDocuments);
          _additionalDocumentLabels = List<String>.generate(
            _additionalDocuments.length,
            (i) => 'Document ${i + 1}',
          );
          _serviceRadius = result.data!.serviceRadiusKm;
          _maxRideDistance = result.data!.maxRideDistanceKm;
          _isProfileExpanded = !_hasSubmittedIdentity(result.data);
          _profileExpansionInitialized = true;
        });
        _showSuccess(isNewApplication
            ? t('rideshare_application_submitted',
                fallback: 'আবেদন জমা হয়েছে! অ্যাডমিনের অনুমোদনের অপেক্ষা করুন।')
            : t('rideshare_profile_saved', fallback: 'প্রোফাইল সেভ হয়েছে'));
      } else {
        _showError(result.message);
      }
    }
  }

  Future<void> _pickAdditionalDocuments() async {
    final remainingSlots = 10 - _additionalDocuments.length;
    if (remainingSlots <= 0) {
      _showError(t('rideshare_doc_limit',
          fallback: 'সর্বোচ্চ ১০টি ডকুমেন্ট দেওয়া যাবে।'));
      return;
    }

    try {
      final files =
          await _imagePicker.pickMultiImage(imageQuality: 80, maxWidth: 1800);
      if (files.isEmpty || !mounted) return;

      final docs = List<String>.from(_additionalDocuments);
      final labels = List<String>.from(_additionalDocumentLabels);

      for (final file in files.take(remainingSlots)) {
        // Compress before encoding — documents use a higher 200KB target so
        // they stay readable (fallback to original bytes on failure).
        final compressed = await ImageCompressor.compressToBase64(
          file,
          targetSize: 200 * 1024,
        );
        if (compressed != null) {
          docs.add(compressed);
        } else {
          final bytes = await file.readAsBytes();
          final base64Data = base64Encode(bytes);
          final ext = file.name.toLowerCase();
          final mime = ext.endsWith('.png')
              ? 'png'
              : ext.endsWith('.webp')
                  ? 'webp'
                  : 'jpeg';
          docs.add('data:image/$mime;base64,$base64Data');
        }
        labels.add(file.name);
      }

      if (!mounted) return;
      setState(() {
        _additionalDocuments = docs;
        _additionalDocumentLabels = labels;
      });
    } catch (_) {
      _showError(t('rideshare_doc_pick_failed',
          fallback: 'এখন ডকুমেন্ট নেওয়া যাচ্ছে না।'));
    }
  }

  void _removeAdditionalDocument(int index) {
    if (index < 0 || index >= _additionalDocuments.length) return;
    setState(() {
      _additionalDocuments.removeAt(index);
      if (index < _additionalDocumentLabels.length) {
        _additionalDocumentLabels.removeAt(index);
      }
    });
  }

  Future<void> _toggleOnline({bool skipPermissionCheck = false}) async {
    if (_driverProfile == null) return;
    final newStatus = !_driverProfile!.isOnline;

    if (newStatus && !_hasEligibleVehicle(_driverProfile)) {
      await _showMissingVehicleInstruction();
      return;
    }

    if (newStatus && _driverProfile!.cashDueLimitReached) {
      _showError(
        t('rideshare_cash_due_warning_msg',
            fallback:
                'You have cash dues. Pay from Adsy Balance before going online.'),
      );
      return;
    }

    setState(() => _isTogglingOnline = true);

    if (newStatus && !skipPermissionCheck) {
      final granted = await _requestLocationPermission();
      if (!granted) {
        if (mounted) {
          setState(() => _isTogglingOnline = false);
        }
        return;
      }
    }

    final result = await RideshareService.toggleDriverOnline(newStatus);
    if (mounted) {
      setState(() => _isTogglingOnline = false);
      if (result.success && result.data != null) {
        setState(() => _driverProfile = result.data);
        if (newStatus) {
          await _startLocationTracking();
          _loadAvailableRequests();
          _syncRealtimeConnections();
          _showSuccess(
              t('rideshare_now_online', fallback: 'আপনি এখন অনলাইনে'));
          unawaited(_ensureDriverAlertReadiness());
        } else {
          _stopLocationTracking();
          setState(() => _availableRequests = []);
          _syncRealtimeConnections();
          _showSuccess(
              t('rideshare_now_offline', fallback: 'আপনি এখন অফলাইনে'));
        }
      } else {
        if (newStatus && result.message.toLowerCase().contains('vehicle')) {
          await _showMissingVehicleInstruction();
          return;
        }
        _showError(result.message);
      }
    }
  }

  /// One-time-per-session check that the OS will actually let ride-request
  /// alerts ring when the phone is locked / in a pocket. Best-effort: it never
  /// blocks going online, it just nudges the driver to fix whatever the OS is
  /// still gating (battery optimization is the common culprit on BD OEMs).
  Future<void> _ensureDriverAlertReadiness() async {
    if (_alertReadinessChecked) return;
    _alertReadinessChecked = true;

    final readiness = await FCMService.ensureDriverAlertPermissions();
    if (!mounted || readiness.isFullyReady) return;

    final issues = <String>[
      if (!readiness.notificationsGranted)
        'নোটিফিকেশন অনুমতি — রাইড রিকোয়েস্ট দেখানোর জন্য আবশ্যক।',
      if (!readiness.batteryOptimizationIgnored)
        'ব্যাটারি অপটিমাইজেশন বন্ধ — ফোন লক থাকলেও রিকোয়েস্ট পেতে দরকার।',
      if (!readiness.fullScreenIntentGranted)
        'ফুল-স্ক্রিন অ্যালার্ট — কল-এর মতো স্ক্রিন জাগিয়ে দেখানোর জন্য।',
    ];
    if (issues.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'রাইড অ্যালার্ট সেটআপ কমপ্লিট করুন',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _slate800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ফোন লক বা পকেটে থাকা অবস্থায় রাইড রিকোয়েস্ট মিস না করতে নিচের অনুমতিগুলো চালু রাখুন:',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _slate500,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              for (final issue in issues)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.error_outline_rounded,
                            size: 16, color: Color(0xFFF59E0B)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          issue,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: _slate600,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: _slate200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'পরে',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: _slate600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        // Re-run the permission requests; allow the prompt to
                        // surface again next time if the driver dismisses it.
                        _alertReadinessChecked = false;
                        unawaited(FCMService.ensureDriverAlertPermissions());
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _indigo,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'অনুমতি দিন',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _payOutstandingCashDues(
      {bool goOnlineAfterPayment = false}) async {
    if (_driverProfile == null || _isPayingCashDues) return;

    setState(() => _isPayingCashDues = true);
    final result = await RideshareService.settleDriverCashDues(
      goOnlineAfterPayment: goOnlineAfterPayment,
    );

    if (!mounted) return;

    setState(() => _isPayingCashDues = false);
    if (result.success && result.data != null) {
      setState(() => _driverProfile = result.data);
      _showSuccess(result.message.isNotEmpty
          ? result.message
          : t('rideshare_ride_completed_msg', fallback: 'হয়ে গেছে!'));
      // Refresh wallet balance so home/wallet screens show updated amount
      unawaited(AuthService.refreshUserData());
      await _loadDriverData();
      if (goOnlineAfterPayment && _driverProfile?.isOnline != true) {
        await _toggleOnline();
      }
      return;
    }

    _showError(result.message);
  }

  Future<void> _startLocationTracking() async {
    await RideshareDriverPresenceService.syncWithDriverProfile(
      _driverProfile,
      promptForPermissions: false,
    );
    _handlePresencePositionChanged();
  }

  void _stopLocationTracking() {
    unawaited(RideshareDriverPresenceService.stop());
    if (mounted) {
      setState(() => _driverCurrentPoint = null);
    }
  }

  Future<void> _acceptRide(Ride ride) async {
    if (_isRequestExpired(ride)) {
      setState(() {
        _availableRequests.removeWhere((request) => request.id == ride.id);
      });
      _showError(t('rideshare_request_expired_msg',
          fallback: 'রিকোয়েস্টটির মেয়াদ শেষ।'));
      return;
    }

    setState(() {
      _isAcceptingRide = true;
      _activeRide = ride.copyWith(
        status: 'accepted',
        assignedDriver: _driverProfile,
        targetedDriver: _driverProfile,
        vehicle: _driverProfile?.defaultVehicle,
        acceptedAt: DateTime.now(),
      );
      _availableRequests = [];
      _passengerLocation = null;
    });
    unawaited(_stopIncomingRideAlert());
    _syncRealtimeConnections();

    final result = await RideshareService.acceptRide(ride.id);
    if (mounted) {
      setState(() => _isAcceptingRide = false);
      if (result.success && result.data != null) {
        setState(() {
          _activeRide = result.data;
          _availableRequests = [];
        });
        _syncRealtimeConnections();
        _refreshSmartRoutePreview(force: true);
        _showSuccess(t('rideshare_ride_accepted', fallback: 'রাইড নেওয়া হয়েছে!'));
      } else {
        setState(() {
          _activeRide = null;
          _smartRoutePreview = null;
          _smartRouteSignature = '';
        });
        _showError(result.message);
        _loadAvailableRequests();
      }
    }
  }

  Future<void> _skipRide(Ride ride) async {
    if (_skippingRideIds.contains(ride.id)) return;

    setState(() {
      _skippingRideIds.add(ride.id);
      _availableRequests.removeWhere((request) => request.id == ride.id);
    });

    if (ride.targetedDriver == null) {
      if (!mounted) return;
      setState(() => _skippingRideIds.remove(ride.id));
      _showSuccess(t('rideshare_ride_skipped', fallback: 'রাইডটি স্কিপ হয়েছে।'));
      return;
    }

    final result = await RideshareService.skipRideRequest(ride.id);
    if (!mounted) return;

    await _stopIncomingRideAlert();
    setState(() => _skippingRideIds.remove(ride.id));

    if (result.success) {
      _showSuccess(t('rideshare_ride_skipped', fallback: 'রাইডটি স্কিপ হয়েছে।'));
    } else {
      _showError(result.message);
    }

    _loadAvailableRequests();
  }

  Future<void> _updateRideStatus(
    String status, {
    double? finalFare,
    String paymentMethod = 'wallet',
  }) async {
    if (_activeRide == null) return;
    final previousRide = _activeRide;

    if (status == 'driver_arriving' || status == 'in_progress') {
      setState(() {
        _activeRide = _activeRide?.copyWith(
          status: status,
          acceptedAt: _activeRide?.acceptedAt ?? DateTime.now(),
          startedAt:
              status == 'in_progress' ? DateTime.now() : _activeRide?.startedAt,
          passengerCanCancel:
              status == 'in_progress' ? false : _activeRide?.passengerCanCancel,
        );
      });
      _syncRealtimeConnections();
      _refreshSmartRoutePreview(force: true);
    }

    setState(() => _isUpdatingStatus = true);
    final RideshareApiResult<Ride> result;
    if (status == 'cancelled') {
      result = await RideshareService.cancelRide(_activeRide!.id);
    } else {
      result = await RideshareService.updateRideStatus(
        _activeRide!.id,
        status,
        finalFare: finalFare,
        paymentMethod: paymentMethod,
      );
    }
    if (mounted) {
      setState(() => _isUpdatingStatus = false);
      if (result.success && result.data != null) {
        if (status == 'completed' || status == 'cancelled') {
          setState(() {
            _activeRide = null;
            _passengerLocation = null;
            _smartRoutePreview = null;
            _smartRouteSignature = '';
          });
          _loadAvailableRequests();
          _loadDriverData();
          // Refresh wallet balance after ride completion
          unawaited(AuthService.refreshUserData());
          _syncRealtimeConnections();
          _showSuccess(
            status == 'completed'
                ? (paymentMethod == 'cash'
                    ? t('rideshare_cash_ride_completed',
                        fallback:
                            'Ride completed. Cash payment marked and due added.')
                    : t('rideshare_ride_completed',
                        fallback: 'রাইড সম্পন্ন!'))
                : t('rideshare_ride_cancelled', fallback: 'রাইড বাতিল হয়েছে'),
          );
        } else {
          setState(() => _activeRide = result.data);
          _syncRealtimeConnections();
          _refreshSmartRoutePreview(force: true);
        }
      } else {
        if (previousRide != null &&
            (status == 'driver_arriving' || status == 'in_progress')) {
          setState(() => _activeRide = previousRide);
          _syncRealtimeConnections();
          _refreshSmartRoutePreview(force: true);
        }
        _showError(result.message);
      }
    }
  }

  RidePoint? _effectiveDriverCurrentPoint() {
    if (_driverCurrentPoint != null) {
      return _driverCurrentPoint;
    }

    final rideLocation = _activeRide?.latestDriverLocation;
    if (rideLocation != null) {
      return RidePoint(
        name: t('rideshare_you', fallback: 'আপনি'),
        latitude: rideLocation.latitude,
        longitude: rideLocation.longitude,
      );
    }

    final profile = _driverProfile;
    if (profile?.currentLatitude != null && profile?.currentLongitude != null) {
      return RidePoint(
        name: t('rideshare_you', fallback: 'আপনি'),
        latitude: profile!.currentLatitude!,
        longitude: profile.currentLongitude!,
      );
    }

    return null;
  }

  bool _supportsSmartRoute(Ride ride) {
    return ride.isAccepted ||
        ride.isDriverArriving ||
        ride.isInProgress ||
        ride.isAwaitingPassengerConfirmation;
  }

  RidePoint? _resolveDriverNavigationDestination(Ride ride) {
    if (ride.isAccepted || ride.isDriverArriving) {
      return ride.pickupPoint;
    }
    if (ride.isInProgress || ride.isAwaitingPassengerConfirmation) {
      return ride.dropPoint;
    }
    return null;
  }

  String _driverRoutePointSignature(RidePoint? point) {
    if (point == null) return 'none';
    return '${point.latitude.toStringAsFixed(3)},${point.longitude.toStringAsFixed(3)}';
  }

  Future<void> _refreshSmartRoutePreview({bool force = false}) async {
    final ride = _activeRide;
    if (ride == null || !_supportsSmartRoute(ride)) {
      if (!mounted) return;
      if (_smartRoutePreview != null ||
          _smartRouteSignature.isNotEmpty ||
          _isLoadingSmartRoute) {
        setState(() {
          _smartRoutePreview = null;
          _smartRouteSignature = '';
          _isLoadingSmartRoute = false;
        });
      }
      return;
    }

    final origin = _effectiveDriverCurrentPoint();
    final destination = _resolveDriverNavigationDestination(ride);
    if (origin == null || destination == null) {
      return;
    }

    final signature =
        '${ride.id}|${ride.status}|${_driverRoutePointSignature(origin)}|${_driverRoutePointSignature(destination)}';
    if (!force && (_isLoadingSmartRoute || signature == _smartRouteSignature)) {
      return;
    }

    if (mounted) {
      setState(() => _isLoadingSmartRoute = true);
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
      setState(() => _isLoadingSmartRoute = false);
      return;
    }

    setState(() {
      _isLoadingSmartRoute = false;
      if (result.success && result.data != null) {
        _smartRoutePreview = result.data;
        _smartRouteSignature = signature;
      }
    });
  }

  double _currentDisplayedDistanceKm(Ride ride) {
    return _smartRoutePreview?.distanceKm ?? ride.distanceKm;
  }

  String _currentDisplayedEta(Ride ride) {
    return _smartRoutePreview?.etaDisplay ?? ride.etaDisplay;
  }

  Map<String, dynamic>? _currentDisplayedRouteGeometry(Ride ride) {
    return _smartRoutePreview?.routeGeometry ?? ride.routeGeometry;
  }

  Future<void> _advanceRideWithNavigation(String status) async {
    await _updateRideStatus(status);
    final ride = _activeRide;
    if (ride == null) {
      return;
    }
    await _refreshSmartRoutePreview(force: true);
  }

  void _openBusinessProfile(String userId) {
    if (userId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)),
    );
  }

  Widget _buildVerifiedBadge() {
    return const Icon(
      Icons.verified,
      size: 14,
      color: Color(0xFF3B82F6),
    );
  }

  Widget _buildProBadge() {
    return const AdsyProBadge();
  }

  Widget _buildTripsBadge(int completedTrips) {
    final label = completedTrips == 1 ? '1 trip' : '$completedTrips trips';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _slate100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _slate200),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _slate500,
        ),
      ),
    );
  }

  Widget _buildIdentityRow({
    required String name,
    required bool isVerified,
    required bool isPro,
    required int completedTrips,
    required TextStyle textStyle,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(name, style: textStyle),
        if (isVerified) _buildVerifiedBadge(),
        if (isPro) _buildProBadge(),
        _buildTripsBadge(completedTrips),
      ],
    );
  }

  Widget _buildPaymentBadge(String? paymentMethod) {
    final isCash = paymentMethod == 'cash';
    final color = isCash ? const Color(0xFFD97706) : const Color(0xFF6366F1);
    final bg = isCash ? const Color(0xFFFFFBEB) : const Color(0xFFEEF2FF);
    final border = isCash ? const Color(0xFFFDE68A) : const Color(0xFFC7D2FE);
    final icon =
        isCash ? Icons.payments_rounded : Icons.account_balance_wallet_rounded;
    final label = isCash
        ? t('rideshare_cash', fallback: 'ক্যাশ')
        : t('rideshare_wallet', fallback: 'ওয়ালেট');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    AdsyToast.error(
        context, _localizeDriverMessage(_resolveDriverErrorMessage(msg)));
  }

  String _resolveDriverErrorMessage(String message) {
    final raw = message.trim();
    if (raw.isEmpty) {
      return 'কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।';
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

  void _showSuccess(String msg) {
    if (!mounted) return;
    AdsyToast.success(context, _localizeDriverMessage(msg));
  }

  String _localizeDriverMessage(String message) {
    final raw = message.trim();
    if (raw.isEmpty) {
      return 'কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।';
    }

    final lower = raw.toLowerCase();

    const exactMessages = {
      'connection error. please check your internet connection.':
          'ইন্টারনেট সংযোগে সমস্যা হয়েছে। আপনার সংযোগ পরীক্ষা করুন।',
      'unable to process response. please try again.':
          'রেসপন্স প্রক্রিয়া করা যায়নি। আবার চেষ্টা করুন।',
      'connection timeout. please try again.':
          'সংযোগের সময় শেষ হয়েছে। আবার চেষ্টা করুন।',
      'network connection issue. please check your internet.':
          'নেটওয়ার্কে সমস্যা হয়েছে। ইন্টারনেট সংযোগ পরীক্ষা করুন।',
      'request timed out. please try again.':
          'রিকোয়েস্টের সময় শেষ হয়েছে। আবার চেষ্টা করুন।',
      'session expired. please log in again.':
          'সেশন শেষ হয়েছে। আবার লগইন করুন।',
      "you don't have permission to perform this action.":
          'এই কাজটি করার অনুমতি আপনার নেই।',
      'requested resource not found.': 'চাওয়া তথ্য পাওয়া যায়নি।',
      'server error. please try again later.':
          'সার্ভারে সমস্যা হয়েছে। একটু পরে আবার চেষ্টা করুন।',
      'service temporarily unavailable. please try again later.':
          'সার্ভিস সাময়িকভাবে বন্ধ আছে। একটু পরে আবার চেষ্টা করুন।',
      'something went wrong. please try again.':
          'কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।',
      'location service is off. please enable gps before going online.':
          'অনলাইনে যেতে আগে জিপিএস চালু করুন।',
      'location permission is required to use driver mode.':
          'ড্রাইভার মোড ব্যবহার করতে লোকেশন অনুমতি প্রয়োজন।',
      'location permission permanently denied. please enable it in app settings.':
          'লোকেশন অনুমতি স্থায়ীভাবে বন্ধ আছে। অ্যাপ সেটিংস থেকে চালু করুন।',
      'new ride request received.': 'নতুন রাইড রিকোয়েস্ট এসেছে।',
      'unable to open chat': 'চ্যাট খোলা যাচ্ছে না।',
      'passenger chat is unavailable':
          'যাত্রীর সাথে চ্যাট এখন পাওয়া যাচ্ছে না।',
      'ride completed!': 'রাইড কমপ্লিট হয়েছে!',
      'ride cancelled': 'রাইড বাতিল হয়েছে।',
      'application submitted! wait for admin approval.':
          'আবেদন জমা হয়েছে। এখন অ্যাডমিন অনুমোদনের জন্য অপেক্ষা করুন।',
      'profile saved': 'প্রোফাইল সেভ করা হয়েছে।',
      'you are now online': 'আপনি এখন অনলাইনে আছেন।',
      'you are now offline': 'আপনি এখন অফলাইনে আছেন।',
      'done!': 'কমপ্লিট হয়েছে!',
      'this ride request has expired.': 'এই রাইড রিকোয়েস্টের সময় শেষ হয়েছে।',
      'ride accepted!': 'রাইড গ্রহণ করা হয়েছে!',
      'ride skipped.': 'রাইডটি স্কিপ করা হয়েছে।',
      'passenger confirmation requested for early completion.':
          'আগাম কমপ্লিটের জন্য যাত্রীর অনুমোদন চাওয়া হয়েছে।',
      'could not pick documents right now.':
          'এই মুহূর্তে ডকুমেন্ট নেওয়া যাচ্ছে না।',
      'you can upload up to 10 additional documents.':
          'সর্বোচ্চ ১০টি অতিরিক্ত ডকুমেন্ট আপলোড করা যাবে।',
      'ride is no longer available.': 'রাইডটি আর উপলভ্য নেই।',
      'this ride is currently assigned to another driver.':
          'এই রাইডটি বর্তমানে অন্য একজন ড্রাইভারের জন্য নির্ধারিত।',
      'you already have an active ride. complete it before accepting a new one.':
          'আপনার ইতোমধ্যে একটি একটিভ রাইড আছে। নতুনটি নেওয়ার আগে সেটি শেষ করুন।',
      'ride accepted successfully.': 'রাইড সফলভাবে গ্রহণ করা হয়েছে।',
    };

    final exact = exactMessages[lower];
    if (exact != null) {
      return exact;
    }

    if (lower.startsWith('failed to enable location')) {
      return 'লোকেশন চালু করতে সমস্যা হয়েছে। আবার চেষ্টা করুন।';
    }

    return raw;
  }

  Future<void> _openPassengerChat(Ride ride) async {
    if (ride.riderId.isEmpty) {
      _showError(t('rideshare_passenger_chat_unavailable',
          fallback: 'যাত্রীর চ্যাট এখন সম্ভব নয়'));
      return;
    }

    var loadingDialogShown = false;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const Center(
          child: AdsyLoadingIndicator(),
        ),
      );
      loadingDialogShown = true;

      final chatroom =
          await AdsyConnectService.getOrCreateChatRoom(ride.riderId);
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
        userId: ride.riderId,
        userName: ride.riderName,
        userAvatar: ride.riderAvatar,
        profession: t('rideshare_passenger', fallback: 'যাত্রী'),
        isOnline: false,
      );
    } catch (error) {
      if (mounted && loadingDialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      debugPrint('Rideshare driver chat open failed: $error');
      _showError('Unable to open chat');
    }
  }

  Future<void> _callPassenger(Ride ride) async {
    final riderPhone = ride.riderPhone?.trim() ?? '';
    if (riderPhone.isEmpty) {
      _showError(t('rideshare_passenger_call_unavailable',
          fallback: 'যাত্রীকে কল এখন সম্ভব নয়'));
      return;
    }

    final uri = Uri(scheme: 'tel', path: riderPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    _showError(t('rideshare_passenger_call_unavailable',
        fallback: 'যাত্রীকে কল এখন সম্ভব নয়'));
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: AdsyLoadingIndicator(color: _indigo));
    }
    if (_isAuthError) return _buildLoginRequired();
    return AdsyRefreshIndicator(
      color: _indigo,
      onRefresh: () async {
        await _refreshLocationPermissionStatus();
        await _loadDriverData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        // The shell has no AppBar; reserve the status bar plus the floating
        // avatar so the first card is not underneath either of them.
        padding: EdgeInsets.fromLTRB(4, MediaQuery.of(context).padding.top + 62, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if ((_driverProfile?.isOnline == true) && !_locationGranted) ...[
              _buildLocationRequiredCard(),
              const SizedBox(height: 12),
            ],
            if (_activeRide != null) ...[
              _buildActiveRideCard(),
            ] else ...[
              if (_driverProfile != null) ...[
                _buildStatsRow(),
                const SizedBox(height: 12),
                _buildOnlineToggleCard(),
                const SizedBox(height: 12),
                if ((_driverProfile?.outstandingCashDueAmount ?? 0) > 0) ...[
                  _buildCashDueCard(),
                  const SizedBox(height: 12),
                ],
              ],
              if (_driverProfile?.isApproved == true) _buildRideRequestsCard(),
              if (_driverProfile?.isApproved == true)
                const SizedBox(height: 12),
              _buildProfileCard(),
              SizedBox(height: _isProfileExpanded ? 12 : 8),
            ],
          ],
        ),
      ),
    );
  }

  // ── WIDGETS ────────────────────────────────────────────────────────────────

  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7), shape: BoxShape.circle),
              child: const Icon(Icons.lock_outline_rounded,
                  size: 40, color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 16),
            Text(t('login_required', fallback: 'লগইন লাগবে'),
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _slate800)),
            const SizedBox(height: 6),
            Text(
                t('rideshare_login_required_subtitle',
                    fallback: 'ড্রাইভার ফিচার ব্যবহারে লগইন করুন।'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: _slate500)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login')
                  .then((_) => _loadDriverData()),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: Text(t('login_button', fallback: 'লগইন'),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: _indigo,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
