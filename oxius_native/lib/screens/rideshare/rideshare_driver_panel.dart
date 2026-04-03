import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';
import '../../models/rideshare_models.dart';
import '../../services/adsyconnect_service.dart';
import '../../services/rideshare_service.dart';
import '../../services/rideshare_realtime_service.dart';
import '../../services/auth_service.dart';
import '../../utils/network_error_handler.dart';
import '../adsy_connect_chat_interface.dart';
import '../business_network/profile_screen.dart';
import 'rideshare_map_widget.dart';

// Design tokens
const _indigo = Color(0xFF6366F1);
const _violet = Color(0xFF8B5CF6);
const _emerald = Color(0xFF10B981);
const _emeraldDark = Color(0xFF059669);
const _slate50 = Color(0xFFF8FAFC);
const _slate100 = Color(0xFFF1F5F9);
const _slate200 = Color(0xFFE2E8F0);
const _slate300 = Color(0xFFCBD5E1);
const _slate400 = Color(0xFF94A3B8);
const _slate500 = Color(0xFF64748B);
const _slate800 = Color(0xFF1E293B);

class RideshareDriverPanel extends StatefulWidget {
  const RideshareDriverPanel({super.key});

  @override
  State<RideshareDriverPanel> createState() => _RideshareDriverPanelState();
}

class _RideshareDriverPanelState extends State<RideshareDriverPanel>
  with WidgetsBindingObserver {
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
  bool _isCheckingLocationPermission = true;
  bool _isRequestingLocationPermission = false;
  bool _isProfileExpanded = true;
  bool _profileExpansionInitialized = false;

  final _licenseController = TextEditingController();
  final _nidController = TextEditingController();
  double _serviceRadius = 8.0;
  double _maxRideদূরত্ব = 0.0;

  StreamSubscription<Position>? _locationSubscription;
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  Timer? _incomingRideAlertTimer;
  Timer? _incomingRideAlertStopTimer;
  final RideshareRealtimeService _realtimeService = RideshareRealtimeService();
  StreamSubscription<Map<String, dynamic>>? _dispatchEventSubscription;
  StreamSubscription<Map<String, dynamic>>? _rideEventSubscription;
  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();

  // Live passenger location received via WebSocket
  RidePoint? _passengerLocation;

  Ride? _resolveDriverActiveRide(DriverProfile? profile, Ride? ride) {
    if (profile == null || ride == null) return null;
    final assignedDriverId = ride.assignedDriver?.userId ?? '';
    if (assignedDriverId.isEmpty) return null;
    return assignedDriverId == profile.userId ? ride : null;
  }

  bool _canChatWithযাত্রী(Ride ride) {
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
          'আগে একটি যানবাহন যোগ করুন',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'অনলাইনে যাওয়ার আগে কমপক্ষে একটি সক্রিয় যানবাহন প্রয়োজন। Vehicles সেকশন থেকে বাইক/কার/CNG যোগ করে আবার চেষ্টা করুন।',
          style: GoogleFonts.inter(fontSize: 13, color: _slate500, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'বন্ধ করুন',
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
              'যানবাহন খুলুন',
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
    WidgetsBinding.instance.addObserver(this);
    _refreshLocationPermissionStatus();
    _loadDriverData();
    _startরিফ্রেশTimer();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationSubscription?.cancel();
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    _stopIncomingRideAlert();
    _dispatchEventSubscription?.cancel();
    _rideEventSubscription?.cancel();
    _realtimeService.dispose();
    _ringtonePlayer.stop();
    _licenseController.dispose();
    _nidController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshLocationPermissionStatus();
    }
  }

  Future<bool> _refreshLocationPermissionStatus({bool syncTracking = true}) async {
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

      if (!granted) {
        _stopLocationTracking();
      } else if (syncTracking && _driverProfile?.isOnline == true) {
        await _startLocationTracking();
      }

      return granted;
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationGranted = false;
          _isCheckingLocationPermission = false;
        });
      }
      _stopLocationTracking();
      return false;
    }
  }

  Future<bool> _requestLocationPermission() async {
    if (_isRequestingLocationPermission) return false;

    setState(() => _isRequestingLocationPermission = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location service is off. Please enable GPS before going online.');
        await Geolocator.openLocationSettings();
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showError('Location permission is required to use driver mode.');
        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permission permanently denied. Please enable it in app settings.');
        await Geolocator.openAppSettings();
        return false;
      }

      if (mounted) {
        setState(() => _locationGranted = true);
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

  void _startরিফ্রেশTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && _driverProfile?.isOnline == true && _activeRide == null) {
        _loadAvailableRequests();
      }
    });
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || (_availableRequests.isEmpty && _activeRide == null)) {
        return;
      }

      final hadমেয়াদোত্তীর্ণRequests = _removeমেয়াদোত্তীর্ণTargetedRequests();
      if (!hadমেয়াদোত্তীর্ণRequests && mounted) {
        setState(() {});
      }
    });
  }

  bool _isRequestমেয়াদোত্তীর্ণ(Ride ride) {
    return ride.targetedDriver != null &&
        ride.targetedCountdownSeconds() <= 0;
  }

  bool _removeমেয়াদোত্তীর্ণTargetedRequests() {
    final before = _availableRequests.length;
    final filtered = _availableRequests
        .where((ride) => !_isRequestমেয়াদোত্তীর্ণ(ride))
        .toList();

    if (filtered.length == before) {
      return false;
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
    setState(() { _isLoading = true; _isAuthError = false; });
    if (!AuthService.isAuthenticated) {
      if (mounted) setState(() { _isLoading = false; _isAuthError = true; _driverProfile = null; });
      return;
    }
    final results = await Future.wait([
      RideshareService.getDriverProfile(),
      RideshareService.getActiveRide(),
      RideshareService.getDriverEarningsSummary(),
    ]);
    final profileResult = results[0] as RideshareApiResult<DriverProfile>;
    final activeRideResult = results[1] as RideshareApiResult<Ride?>;
    final earningsResult = results[2] as RideshareApiResult<DriverEarningsSummary>;
    final resolvedActiveRide = _resolveDriverActiveRide(
      profileResult.data,
      activeRideResult.data,
    );
    final msg = profileResult.message.toLowerCase();
    final authFailed = !profileResult.success &&
        (msg.contains('unauthorized') || msg.contains('credentials') ||
         msg.contains('authentication') || msg.contains('not provided'));
    if (mounted) {
      setState(() {
        _isAuthError = authFailed;
        _driverProfile = profileResult.data;
        _activeRide = resolvedActiveRide;
        _earnings = earningsResult.data;
        _isLoading = false;
      });
      if (profileResult.data != null) {
        _licenseController.text = profileResult.data!.licenseNumber;
        _nidController.text = profileResult.data!.nationalIdNumber;
        _serviceRadius = profileResult.data!.serviceRadiusKm;
        _maxRideদূরত্ব = profileResult.data!.maxRideদূরত্বKm;
        _initializeProfileExpansion(profileResult.data);
      }
      if (_driverProfile?.isOnline == true) {
        await _startLocationTracking();
        if (_activeRide == null) _loadAvailableRequests();
      }
      _syncRealtimeConnections();
    }
  }

  void _syncRealtimeConnections() {
    final canReceiveDispatch = _driverProfile?.isOnline == true && _activeRide == null;
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
    if (type == 'ride.targeted') {
      await _playIncomingRideAlert();
      await _loadAvailableRequests();
      _showSuccess('New ride request received.');
      return;
    }

    if (type == 'ride.event') {
      await _loadAvailableRequests();
    }
  }

  Future<void> _handleActiveRideEvent(Map<String, dynamic> event) async {
    if (!mounted || _activeRide == null) return;

    final type = event['type']?.toString() ?? '';

    // Handle live passenger location updates
    if (type == 'passenger.location') {
      final lat = double.tryParse(event['latitude']?.toString() ?? '');
      final lng = double.tryParse(event['longitude']?.toString() ?? '');
      if (lat != null && lng != null) {
        setState(() {
          _passengerLocation = RidePoint(
            name: 'যাত্রী',
            latitude: lat,
            longitude: lng,
          );
        });
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
      if (_activeRide?.isসম্পন্ন করুনd == true || _activeRide?.isবাতিলled == true) {
        _stopIncomingRideAlert();
        setState(() => _passengerLocation = null);
        _showSuccess(_activeRide!.isসম্পন্ন করুনd ? 'রাইড সম্পন্ন হয়েছে!' : 'রাইড বাতিল করা হয়েছে');
      }
      _syncRealtimeConnections();
    }
  }

  Future<void> _playIncomingRideAlert() async {
    try {
      _stopIncomingRideAlert();

      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: 1200);
        _incomingRideAlertTimer = Timer.periodic(const Duration(seconds: 2), (_) {
          Vibration.vibrate(duration: 1200);
        });
        _incomingRideAlertStopTimer = Timer(const Duration(minutes: 1), () {
          _stopIncomingRideAlert();
        });
      }
      await _ringtonePlayer.playNotification(looping: false, asAlarm: true);
    } catch (_) {
      // Alert fallback is intentionally silent if the device blocks audio/vibration.
    }
  }

  void _stopIncomingRideAlert() {
    _incomingRideAlertTimer?.cancel();
    _incomingRideAlertTimer = null;
    _incomingRideAlertStopTimer?.cancel();
    _incomingRideAlertStopTimer = null;
    Vibration.cancel();
  }

  Future<void> _loadAvailableRequests() async {
    final result = await RideshareService.listAvailableRideRequests();
    if (!mounted || !result.success) return;

    final requests = (result.data ?? [])
        .where((ride) => !_isRequestমেয়াদোত্তীর্ণ(ride))
        .toList();
    if (requests.isEmpty) {
      _stopIncomingRideAlert();
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
      );
    } else {
      result = await RideshareService.updateDriverProfile(
        licenseNumber: _licenseController.text.trim(),
        nationalIdNumber: _nidController.text.trim(),
        serviceRadiusKm: _serviceRadius,
        maxRideদূরত্বKm: _maxRideদূরত্ব,
      );
    }

    if (mounted) {
      setState(() => _isSavingProfile = false);
      if (result.success && result.data != null) {
        _licenseController.text = result.data!.licenseNumber;
        _nidController.text = result.data!.nationalIdNumber;
        setState(() {
          _driverProfile = result.data;
          _serviceRadius = result.data!.serviceRadiusKm;
          _maxRideদূরত্ব = result.data!.maxRideদূরত্বKm;
          _isProfileExpanded = !_hasSubmittedIdentity(result.data);
          _profileExpansionInitialized = true;
        });
        _showSuccess(isNewApplication
            ? 'Application submitted! Wait for admin approval.'
            : 'Profile saved');
      } else {
        _showError(result.message);
      }
    }
  }

  Future<void> _toggleOnline() async {
    if (_driverProfile == null) return;
    final newStatus = !_driverProfile!.isOnline;

    if (newStatus && !_hasEligibleVehicle(_driverProfile)) {
      await _showMissingVehicleInstruction();
      return;
    }

    if (newStatus && _driverProfile!.cashDueLimitReached) {
      _showError(
        'আপনার নগদ বকেয়া আছে। অনলাইনে যাওয়ার আগে অ্যাডসি ব্যালেন্স থেকে পরিশোধ করুন।',
      );
      return;
    }

    setState(() => _isTogglingOnline = true);

    if (newStatus) {
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
          _showSuccess('আপনি এখন অনলাইনে আছেন');
        } else {
          _stopLocationTracking();
          setState(() => _availableRequests = []);
          _syncRealtimeConnections();
          _showSuccess('আপনি এখন অফলাইনে আছেন');
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

  Future<void> _payOutstandingCashDues({bool goOnlineAfterPayment = false}) async {
    if (_driverProfile == null || _isPayingCashDues) return;

    setState(() => _isPayingCashDues = true);
    final result = await RideshareService.settleDriverনগদDues(
      goOnlineAfterPayment: goOnlineAfterPayment,
    );

    if (!mounted) return;

    setState(() => _isPayingCashDues = false);
    if (result.success && result.data != null) {
      setState(() => _driverProfile = result.data);
      _showSuccess(result.message);
      await _loadDriverData();
      if (goOnlineAfterPayment && _driverProfile?.isOnline != true) {
        await _toggleOnline();
      }
      return;
    }

    _showError(result.message);
  }

  Future<void> _startLocationTracking() async {
    _locationSubscription?.cancel();
    try {
      final granted = await _refreshLocationPermissionStatus(syncTracking: false);
      if (!granted) {
        _showError('Location permission required');
        return;
      }
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen(_updateDriverLocation);
    } catch (_) { _showError('Failed to start location tracking'); }
  }

  void _stopLocationTracking() { _locationSubscription?.cancel(); _locationSubscription = null; }

  Future<void> _updateDriverLocation(Position p) async {
    await RideshareService.updateDriverLocation(
      latitude: p.latitude, longitude: p.longitude, rideId: _activeRide?.id,
      heading: p.heading, speedKph: p.speed * 3.6, accuracyMeters: p.accuracy,
    );
  }

  Future<void> _acceptRide(Ride ride) async {
    if (_isRequestমেয়াদোত্তীর্ণ(ride)) {
      setState(() {
        _availableRequests.removeWhere((request) => request.id == ride.id);
      });
      _showError('This ride request has expired.');
      return;
    }

    setState(() => _isAcceptingRide = true);
    final result = await RideshareService.acceptRide(ride.id);
    if (mounted) {
      setState(() => _isAcceptingRide = false);
      if (result.success && result.data != null) {
        _stopIncomingRideAlert();
        setState(() { _activeRide = result.data; _availableRequests = []; });
        _ringtonePlayer.stop();
        _syncRealtimeConnections();
        _showSuccess('Ride accepted!');
      } else { _showError(result.message); _loadAvailableRequests(); }
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
      _showSuccess('Ride skipped.');
      return;
    }

    final result = await RideshareService.skipRideRequest(ride.id);
    if (!mounted) return;

    _stopIncomingRideAlert();
    setState(() => _skippingRideIds.remove(ride.id));

    if (result.success) {
      _showSuccess('Ride skipped. Looking for another request...');
    } else {
      _showError(result.message);
    }

    _loadAvailableRequests();
  }

  Future<void> _updateRideStatus(
    String status, {
    double? finalভাড়া,
    String paymentMethod = 'wallet',
  }) async {
    if (_activeRide == null) return;
    setState(() => _isUpdatingStatus = true);
    final RideshareApiResult<Ride> result;
    if (status == 'cancelled') {
      result = await RideshareService.cancelRide(_activeRide!.id);
    } else {
      result = await RideshareService.updateRideStatus(
        _activeRide!.id,
        status,
        finalভাড়া: finalভাড়া,
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
          });
          _loadAvailableRequests();
          _loadDriverData();
          _syncRealtimeConnections();
          _showSuccess(
            status == 'completed'
                ? (paymentMethod == 'cash'
                    ? 'Ride completed. নগদ payment marked and due added.'
                    : 'রাইড সম্পন্ন হয়েছে!')
                : 'রাইড বাতিল করা হয়েছে',
          );
        } else {
          setState(() => _activeRide = result.data);
          _syncRealtimeConnections();
        }
      } else { _showError(result.message); }
    }
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _indigo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Pro',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
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
    final icon = isCash ? Icons.payments_rounded : Icons.account_balance_wallet_rounded;
    final label = isCash ? 'নগদ' : 'ওয়ালেট';
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
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(NetworkErrorHandler.getErrorMessage(msg), style: GoogleFonts.inter(fontSize: 13)),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
      backgroundColor: _emerald,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  Future<void> _openযাত্রীChat(Ride ride) async {
    if (ride.riderId.isEmpty) {
      _showError('যাত্রী chat is unavailable');
      return;
    }

    var loadingDialogShown = false;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      loadingDialogShown = true;

      final chatroom = await AdsyConnectService.getOrCreateChatRoom(ride.riderId);
      final chatroomId = chatroom['id']?.toString();
      if (chatroomId == null || chatroomId.isEmpty) {
        throw Exception('Chat room unavailable');
      }

      if (mounted && loadingDialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingDialogShown = false;
      }
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: AdsyConnectChatInterface(
              chatroomId: chatroomId,
              userId: ride.riderId,
              userName: ride.riderName,
              userAvatar: ride.riderAvatar,
              profession: 'যাত্রী',
              isOnline: false,
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted && loadingDialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      debugPrint('Rideshare driver chat open failed: $error');
      _showError('Unable to open chat');
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: _indigo));
    if (_isAuthError) return _buildLoginRequired();
    return রিফ্রেশIndicator(
      color: _indigo,
      onরিফ্রেশ: () async {
        await _refreshLocationPermissionStatus();
        await _loadDriverData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_locationGranted) ...[
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
                if ((_driverProfile?.outstandingনগদDueAmount ?? 0) > 0) ...[
                  _buildনগদDueCard(),
                  const SizedBox(height: 12),
                ],
              ],
              _buildProfileCard(),
              SizedBox(height: _isProfileExpanded ? 12 : 8),
              if (_driverProfile?.isApproved == true) _buildRideRequestsCard(),
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
              decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
              child: const Icon(Icons.lock_outline_rounded, size: 40, color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 16),
            Text('Login Required',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: _slate800)),
            const SizedBox(height: 6),
            Text('Please log in to access driver features.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: _slate500)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login').then((_) => _loadDriverData()),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: Text('Log In', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: _indigo,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final approval = _driverProfile?.approvalStatus ?? 'pending';
    final isApproved = _driverProfile?.isApproved == true;
    Color approvalColor;
    if (approval == 'approved') {
      approvalColor = _emerald;
    } else if (approval == 'suspended') {
      approvalColor = Colors.red.shade500;
    } else {
      approvalColor = const Color(0xFFD97706);
    }

    return Row(children: [
      _buildStatChip('Status',
          approval[0].toUpperCase() + approval.substring(1),
          approvalColor, isApproved ? Icons.verified_rounded : Icons.hourglass_top_rounded),
      const SizedBox(width: 8),
      _buildStatChip('Trips', '${_earnings?.totalTrips ?? 0}', _indigo, Icons.directions_car_rounded),
      const SizedBox(width: 8),
      _buildStatChip('Earned', '৳${(_earnings?.totalEarnings ?? 0).toStringAsFixed(0)}',
          _emerald, Icons.account_balance_wallet_rounded),
    ]);
  }

  Widget _buildLocationRequiredCard() {
    final isBusy = _isCheckingLocationPermission || _isRequestingLocationPermission;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF2F2), Color(0xFFFFF7ED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_disabled_rounded,
              color: Color(0xFFDC2626),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location Sharing Mandatory',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enable location to go online, receive ride requests, and share live driver updates.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF7F1D1D),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: isBusy ? null : _requestLocationPermission,
            icon: isBusy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.my_location_rounded, size: 16),
            label: Text(
              isBusy ? 'Checking' : 'Enable',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _slate200),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w600, color: _slate400, letterSpacing: 0.3)),
          ]),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w700, color: _slate800)),
        ]),
      ),
    );
  }

  Widget _buildOnlineToggleCard() {
    final isOnline = _driverProfile?.isOnline == true;
    final isApproved = _driverProfile?.isApproved == true;
    final dueLimitReached = _driverProfile?.cashDueLimitReached == true;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: isOnline ? const LinearGradient(
            colors: [_emerald, _emeraldDark],
            begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        color: isOnline ? null : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isOnline ? null : Border.all(color: _slate200),
        boxShadow: [BoxShadow(
          color: isOnline ? _emerald.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
          blurRadius: 10, offset: const Offset(0, 3),
        )],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: isOnline ? Colors.white.withValues(alpha: 0.2) : _slate100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              size: 20, color: isOnline ? Colors.white : _slate500),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isOnline ? 'অনলাইন — রাইড গ্রহণ চলছে' : 'অফলাইন',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
                  color: isOnline ? Colors.white : _slate800)),
            Text(
              !_locationGranted
                ? 'রাইড অনুরোধ পেতে লোকেশন চালু করুন'
                : dueLimitReached
                  ? 'আবার অনলাইনে যেতে নগদ বকেয়া পরিশোধ করুন'
                : isOnline
                  ? 'নিচে রিকোয়েস্ট দেখাবে'
                  : 'রিকোয়েস্ট পেতে অনলাইনে যান',
              style: GoogleFonts.inter(fontSize: 11,
                  color: isOnline ? Colors.white.withValues(alpha: 0.8) : _slate500)),
        ])),
        GestureDetector(
            onTap: (isApproved && !_isTogglingOnline && !_isCheckingLocationPermission)
              ? _toggleOnline
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 50, height: 28,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isOnline ? Colors.white.withValues(alpha: 0.35)
                  : (isApproved ? _slate300 : _slate200),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              alignment: isOnline ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                    color: isOnline ? Colors.white : _slate400, shape: BoxShape.circle),
                child: _isTogglingOnline ? Padding(
                  padding: const EdgeInsets.all(4),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: isOnline ? _emerald : _slate500),
                ) : null,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildনগদDueCard() {
    final profile = _driverProfile;
    if (profile == null || profile.outstandingনগদDueAmount <= 0) {
      return const SizedBox.shrink();
    }

    final dueCount = profile.outstandingনগদDueCount;
    final dueAmount = profile.outstandingনগদDueAmount;
    final limitReached = profile.cashDueLimitReached;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFFFBEB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: limitReached ? const Color(0xFFF59E0B) : const Color(0xFFFCD34D),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'নগদ পেমেন্ট Due',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF92400E)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '৳${dueAmount.toStringAsFixed(0)} pending across $dueCount cash ride${dueCount > 1 ? 's' : ''}.',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF92400E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            limitReached
                ? 'You reached the maximum unpaid cash rides. Pay this due from your Adsy ব্যালেন্স to go online again.'
                : 'You can keep driving for now, but clear this due from your Adsy ব্যালেন্স before it reaches the limit.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF78350F), height: 1.35),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final walletBalance = AuthService.currentUser?.balance ?? 0.0;
              final hasEnough = walletBalance >= dueAmount;
              return Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: (hasEnough && !_isPayingCashDues)
                          ? () => _payOutstandingCashDues(goOnlineAfterPayment: limitReached)
                          : null,
                      icon: _isPayingCashDues
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.account_balance_wallet_rounded, size: 18),
                      label: Text(
                        _isPayingCashDues
                            ? 'পরিশোধ হচ্ছে...'
                            : hasEnough
                                ? 'অ্যাডসি ব্যালেন্স থেকে বকেয়া পরিশোধ করুন'
                                : 'অপর্যাপ্ত ব্যালেন্স (৳${walletBalance.toStringAsFixed(0)})',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: hasEnough ? const Color(0xFFD97706) : _slate400,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  if (!hasEnough) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/deposit-withdraw'),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          'Add Funds to Adsy ওয়ালেট',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6366F1),
                          side: const BorderSide(color: Color(0xFF6366F1)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final isNew = !_hasSubmittedIdentity(_driverProfile);
    final isPending = _driverProfile?.isPending == true;
    final isApproved = _driverProfile?.isApproved == true;
    final isSuspended = _driverProfile?.isSuspended == true;
    final licenseLocked = _licenseLocked;
    final nidLocked = _nidLocked;
    final hasSubmittedIdentity = _hasSubmittedIdentity(_driverProfile);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _slate200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            onTap: () => setState(() => _isProfileExpanded = !_isProfileExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: const BoxDecoration(
                color: _slate50,
                borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
                border: Border(bottom: BorderSide(color: _slate200)),
              ),
              child: Row(children: [
                const Icon(Icons.badge_rounded, size: 16, color: _indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isNew ? 'Become a Driver' : 'Driver Profile',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _slate800),
                  ),
                ),
                if (isSuspended) ...[
                  _buildBadge('Suspended', Colors.red.shade600),
                  const SizedBox(width: 6),
                ],
                if (isPending) ...[
                  _buildBadge('Under Review', const Color(0xFFD97706)),
                  const SizedBox(width: 6),
                ],
                if (isApproved) ...[
                  _buildBadge('Approved', _emerald),
                  const SizedBox(width: 6),
                ],
                GestureDetector(
                  onTap: _openVehicles,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _slate200),
                    ),
                    child: const Icon(Icons.two_wheeler_rounded, size: 16, color: _indigo),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _isProfileExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: _slate500,
                ),
              ]),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: _isProfileExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: _buildExpandedProfileContent(
            isNew: isNew,
            isPending: isPending,
            isSuspended: isSuspended,
            licenseLocked: licenseLocked,
            nidLocked: nidLocked,
          ),
          secondChild: _buildCollapsedProfileSummary(
            hasSubmittedIdentity: hasSubmittedIdentity,
            licenseLocked: licenseLocked,
            nidLocked: nidLocked,
          ),
        ),
      ]),
    );
  }

  Widget _buildExpandedProfileContent({
    required bool isNew,
    required bool isPending,
    required bool isSuspended,
    required bool licenseLocked,
    required bool nidLocked,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isPending)
          _buildNoticeBanner(
            icon: Icons.hourglass_top_rounded,
            msg: 'Your profile is under review. You\'ll be notified once approved.',
            bgColor: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFDE68A),
            iconColor: const Color(0xFFD97706),
            textColor: const Color(0xFF92400E),
          ),
        if (isSuspended)
          _buildNoticeBanner(
            icon: Icons.block_rounded,
            msg: 'Your driver account has been suspended. Contact support.',
            bgColor: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFFECACA),
            iconColor: Colors.red.shade600,
            textColor: Colors.red.shade800,
          ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (isNew)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _driverProfile == null
                      ? 'Submit your identity details to apply as a driver. Admin will review and approve your application.'
                      : 'Fill in your identity details once. After submission, license and NID stay locked.',
                  style: GoogleFonts.inter(fontSize: 12, color: _slate500),
                ),
              ),
            _buildField(
              _licenseController,
              'License Number',
              'Driving license number',
              Icons.credit_card_rounded,
              readOnly: licenseLocked,
              helperText: licenseLocked ? 'Submitted license number cannot be edited.' : null,
            ),
            const SizedBox(height: 10),
            _buildField(
              _nidController,
              'National ID (NID)',
              'National ID number',
              Icons.perm_identity_rounded,
              readOnly: nidLocked,
              helperText: nidLocked ? 'Submitted NID cannot be edited.' : null,
            ),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.radar_rounded, size: 13, color: _slate500),
              const SizedBox(width: 5),
              Text('Minimum Service Radius',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _slate500)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _indigo.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                child: Text('${_serviceRadius.toStringAsFixed(0)} km',
                    style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w700, color: _indigo)),
              ),
            ]),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                activeTrackColor: _indigo,
                inactiveTrackColor: _slate200,
                thumbColor: _indigo,
                overlayColor: _indigo.withValues(alpha: 0.1),
              ),
              child: Slider(
                value: _serviceRadius,
                min: 1,
                max: 30,
                divisions: 29,
                onChanged: (v) => setState(() => _serviceRadius = v),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.route_rounded, size: 13, color: _slate500),
              const SizedBox(width: 5),
              Text('Max Ride দূরত্ব',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _slate500)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _indigo.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                child: Text(_maxRideদূরত্ব == 0 ? 'No limit' : '${_maxRideদূরত্ব.toStringAsFixed(0)} km',
                    style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w700, color: _indigo)),
              ),
            ]),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                activeTrackColor: _indigo,
                inactiveTrackColor: _slate200,
                thumbColor: _indigo,
                overlayColor: _indigo.withValues(alpha: 0.1),
              ),
              child: Slider(
                value: _maxRideদূরত্ব,
                min: 0,
                max: 300,
                divisions: 30,
                onChanged: (v) => setState(() => _maxRideদূরত্ব = v),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSavingProfile ? null : _saveProfile,
                  icon: _isSavingProfile
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded, size: 16),
                  label: Text(
                    _isSavingProfile
                        ? 'Saving...'
                        : _driverProfile == null
                            ? 'Apply as Driver'
                            : 'Save Profile',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _indigo,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _openVehicles,
                icon: const Icon(Icons.two_wheeler_rounded, size: 16),
                label: Text('Vehicles',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _indigo,
                  side: const BorderSide(color: _indigo),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ]),
          ]),
        ),
      ],
    );
  }

  Widget _buildCollapsedProfileSummary({
    required bool hasSubmittedIdentity,
    required bool licenseLocked,
    required bool nidLocked,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildProfileSummaryPill(
                icon: Icons.credit_card_rounded,
                label: licenseLocked ? 'License submitted' : 'License pending',
                color: licenseLocked ? _emerald : _slate500,
                highlighted: licenseLocked,
              ),
              _buildProfileSummaryPill(
                icon: Icons.perm_identity_rounded,
                label: nidLocked ? 'NID submitted' : 'NID pending',
                color: nidLocked ? _emerald : _slate500,
                highlighted: nidLocked,
              ),
              _buildProfileSummaryPill(
                icon: Icons.radar_rounded,
                label: '${_serviceRadius.toStringAsFixed(0)} km radius',
                color: _indigo,
                highlighted: true,
              ),
              _buildProfileSummaryPill(
                icon: Icons.route_rounded,
                label: _maxRideদূরত্ব == 0 ? 'No distance limit' : '${_maxRideদূরত্ব.toStringAsFixed(0)} km max ride',
                color: _indigo,
                highlighted: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasSubmittedIdentity
                ? 'Identity fields are locked after first submission. Open this section only when you need to review status or update service radius.'
                : 'Open this section to complete your driver profile before going online.',
            style: GoogleFonts.inter(fontSize: 11, color: _slate500, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSummaryPill({
    required IconData icon,
    required String label,
    required Color color,
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: highlighted ? color.withValues(alpha: 0.08) : _slate50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: highlighted ? color.withValues(alpha: 0.22) : _slate200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeBanner({
    required IconData icon,
    required String msg,
    required Color bgColor,
    required Color borderColor,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor)),
      child: Row(children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: GoogleFonts.inter(fontSize: 11, color: textColor))),
      ]),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    String hint,
    IconData icon, {
    bool readOnly = false,
    String? helperText,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600, color: _slate500)),
      const SizedBox(height: 5),
      TextField(
        controller: ctrl,
        readOnly: readOnly,
        style: GoogleFonts.inter(fontSize: 13, color: _slate800),
        decoration: InputDecoration(
          hintText: hint,
          helperText: helperText,
          helperMaxLines: 2,
          helperStyle: GoogleFonts.inter(fontSize: 10.5, color: _slate500, height: 1.3),
          hintStyle: GoogleFonts.inter(fontSize: 13, color: _slate400),
          prefixIcon: Icon(icon, size: 15, color: _slate400),
          suffixIcon: readOnly ? const Icon(Icons.lock_rounded, size: 16, color: _slate400) : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          filled: true, fillColor: readOnly ? _slate100 : _slate50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _slate200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _slate200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _indigo, width: 1.5)),
        ),
      ),
    ]);
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildRideRequestsCard() {
    final isOnline = _driverProfile?.isOnline == true;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _slate200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: const BoxDecoration(
            color: _slate50,
            borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            border: Border(bottom: BorderSide(color: _slate200)),
          ),
          child: Row(children: [
            const Icon(Icons.hail_rounded, size: 16, color: _indigo),
            const SizedBox(width: 8),
            Text('রাইড অনুরোধসমূহ',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _slate800)),
            const Spacer(),
            if (isOnline && _availableRequests.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _emerald.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text('${_availableRequests.length}',
                    style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w700, color: _emerald)),
              ),
            if (isOnline)
              GestureDetector(
                onTap: _loadAvailableRequests,
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: _slate100, borderRadius: BorderRadius.circular(6)),
                  child: Text('রিফ্রেশ',
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w600, color: _slate500)),
                ),
              ),
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isOnline ? _emerald.withValues(alpha: 0.12) : _slate100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(isOnline ? 'Online' : 'অফলাইন',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                      color: isOnline ? _emerald : _slate500)),
            ),
          ]),
        ),
        if (!isOnline)
          _buildEmptyRequests(Icons.wifi_off_rounded, 'আপনি অফলাইনে আছেন',
              'রাইড অনুরোধ পেতে উপরের সুইচ থেকে অনলাইনে যান।')
        else if (_availableRequests.isEmpty)
          _buildEmptyRequests(Icons.search_rounded, 'এখনও কোনো অনুরোধ নেই',
              'নতুন রাইড অনুরোধ এখানে স্বয়ংক্রিয়ভাবে দেখাবে।')
        else
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: _availableRequests.map(_buildRequestCard).toList()),
          ),
      ]),
    );
  }

  Widget _buildEmptyRequests(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(color: _slate100, shape: BoxShape.circle),
          child: Icon(icon, size: 28, color: _slate400),
        ),
        const SizedBox(height: 12),
        Text(title, style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w700, color: _slate800)),
        const SizedBox(height: 4),
        Text(subtitle, textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: _slate500)),
      ]),
    );
  }

  Widget _buildRequestCard(Ride ride) {
    final countdown = ride.targetedCountdownSeconds();
    final isTargeted = ride.targetedDriver != null;
    final isমেয়াদোত্তীর্ণ = _isRequestমেয়াদোত্তীর্ণ(ride);
    final isSkipping = _skippingRideIds.contains(ride.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: _slate50, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _slate200)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Text(ride.vehicleIcon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildIdentityRow(
                  name: ride.riderName,
                  isVerified: ride.riderIsVerified,
                  isPro: ride.riderIsPro,
                  completedTrips: ride.riderসম্পন্ন করুনdTrips,
                  textStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _slate800,
                  ),
                ),
                Row(
                  children: [
                    Text('${ride.distanceKm.toStringAsFixed(1)} km • ${ride.etaDisplay}',
                        style: GoogleFonts.inter(fontSize: 11, color: _slate500)),
                    const SizedBox(width: 6),
                    _buildPaymentBadge(ride.paymentMethod),
                  ],
                ),
              ])),
              if (isTargeted)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: isমেয়াদোত্তীর্ণ ? _slate100 : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isমেয়াদোত্তীর্ণ ? _slate300 : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Text(
                    isমেয়াদোত্তীর্ণ ? 'মেয়াদোত্তীর্ণ' : '${countdown}s',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isমেয়াদোত্তীর্ণ ? _slate500 : const Color(0xFFD97706),
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _emerald.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _emerald.withValues(alpha: 0.25)),
                ),
                child: Text('৳${ride.fareEstimate.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w800, color: _emerald)),
              ),
            ]),
            const SizedBox(height: 10),
            _buildRouteWidget(ride),
            const SizedBox(height: 10),
            Row(children: [
              _buildMini('ভাড়া', '৳${ride.fareEstimate.toStringAsFixed(0)}', _indigo),
              const SizedBox(width: 6),
              _buildMini('দূরত্ব', '${ride.distanceKm.toStringAsFixed(1)} km', _slate800),
              const SizedBox(width: 6),
              _buildMini('ETA', ride.etaDisplay, _slate800),
            ]),
          ]),
        ),
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _slate200)),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
          ),
          child: Row(children: [
            SizedBox(
              width: 108,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isSkipping || _isAcceptingRide ? null : () => _skipRide(ride),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(11)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: isSkipping ? _slate100 : Colors.white,
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(11)),
                      border: const Border(right: BorderSide(color: _slate200)),
                    ),
                    child: Center(
                      child: isSkipping
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _indigo),
                            )
                          : Text(
                              'Skip',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _slate500,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isAcceptingRide || isSkipping || isমেয়াদোত্তীর্ণ
                      ? null
                      : () => _acceptRide(ride),
                  borderRadius: const BorderRadius.only(bottomRight: Radius.circular(11)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      gradient: _isAcceptingRide || isSkipping || isমেয়াদোত্তীর্ণ
                          ? null
                          : const LinearGradient(colors: [_emerald, _emeraldDark]),
                      color: (_isAcceptingRide || isSkipping || isমেয়াদোত্তীর্ণ)
                          ? _slate100
                          : null,
                      borderRadius: const BorderRadius.only(bottomRight: Radius.circular(11)),
                    ),
                    child: Center(
                      child: _isAcceptingRide
                          ? Row(mainAxisSize: MainAxisSize.min, children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: _indigo),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Accepting...',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _slate500,
                                ),
                              ),
                            ])
                          : Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(
                                isমেয়াদোত্তীর্ণ ? Icons.schedule_rounded : Icons.check_circle_rounded,
                                size: 16,
                                color: isমেয়াদোত্তীর্ণ ? _slate500 : Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isমেয়াদোত্তীর্ণ ? 'মেয়াদোত্তীর্ণ' : 'রাইড গ্রহণ করুন',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isমেয়াদোত্তীর্ণ ? _slate500 : Colors.white,
                                ),
                              ),
                            ]),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMini(String label, String value, Color vc) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _slate200)),
        child: Column(children: [
          Text(label, style: GoogleFonts.inter(
              fontSize: 9, fontWeight: FontWeight.w600, color: _slate400, letterSpacing: 0.2)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w700, color: vc)),
        ]),
      ),
    );
  }

  Widget _buildRouteWidget(Ride ride) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _slate200)),
      child: Row(children: [
        Column(children: [
          Container(width: 8, height: 8,
              decoration: const BoxDecoration(color: _indigo, shape: BoxShape.circle)),
          Container(width: 1.5, height: 14, color: _slate300),
          Container(width: 8, height: 8,
              decoration: BoxDecoration(
                  color: _emerald, borderRadius: BorderRadius.circular(2))),
        ]),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ride.pickupAddress, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: _slate800)),
          const SizedBox(height: 6),
          Text(ride.dropAddress, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: _slate800)),
        ])),
      ]),
    );
  }

  // ── ACTIVE RIDE ────────────────────────────────────────────────────────────

  Widget _buildActiveRideCard() {
    final ride = _activeRide!;
    return Column(children: [
      Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _slate200)),
        child: Column(children: [
          // Gradient header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_indigo, _violet]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(children: [
              const Icon(Icons.directions_car_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('চলমান রাইড',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))),
              _buildStatusPill(ride.statusDisplay),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              // যাত্রী row
              Row(children: [
                GestureDetector(
                  onTap: () => _openBusinessProfile(ride.riderId),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: _slate100,
                    backgroundImage: ride.riderAvatar != null
                        ? NetworkImage(ride.riderAvatar!) : null,
                    child: ride.riderAvatar == null
                        ? const Icon(Icons.person_rounded, size: 20, color: _slate500) : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(
                  onTap: () => _openBusinessProfile(ride.riderId),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildIdentityRow(
                      name: ride.riderName,
                      isVerified: ride.riderIsVerified,
                      isPro: ride.riderIsPro,
                      completedTrips: ride.riderসম্পন্ন করুনdTrips,
                      textStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _slate800,
                      ),
                    ),
                    Text('যাত্রী',
                        style: GoogleFonts.inter(fontSize: 11, color: _slate500)),
                  ]),
                )),
                if (_canChatWithযাত্রী(ride))
                  GestureDetector(
                    onTap: () => _openযাত্রীChat(ride),
                    child: Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: _emerald.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: _emerald.withValues(alpha: 0.25)),
                      ),
                      child: Image.asset(
                        'assets/images/chat_icon.png',
                        width: 18,
                        height: 18,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.chat_bubble_rounded,
                          size: 18,
                          color: _emerald,
                        ),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 12),
              _buildRouteWidget(ride),
              const SizedBox(height: 10),
              Row(children: [
                _buildMini('ভাড়া', '৳${ride.payableFare.toStringAsFixed(0)}', _indigo),
                const SizedBox(width: 6),
                _buildMini('দূরত্ব', '${ride.distanceKm.toStringAsFixed(1)} km', _slate800),
                const SizedBox(width: 6),
                _buildMini('ETA', ride.etaDisplay, _slate800),
              ]),
              const SizedBox(height: 12),
              _buildRideActions(ride),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      Container(
        height: _mapViewportHeight(context),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14), border: Border.all(color: _slate200)),
        clipBehavior: Clip.antiAlias,
        child: RideshareMapWidget(
          pickupPoint: ride.pickupPoint,
          dropPoint: ride.dropPoint,
          routeGeometry: ride.routeGeometry,
          passengerLocation: _passengerLocation,
          passengerName: ride.riderName.isNotEmpty ? ride.riderName : null,
          passengerAvatar: ride.riderAvatar,
        ),
      ),
    ]);
  }

  Widget _buildStatusPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }

  Widget _buildRideActions(Ride ride) {
    if (_isUpdatingStatus) {
      return const Center(child: CircularProgressIndicator(color: _indigo, strokeWidth: 2));
    }
    switch (ride.status) {
      case 'accepted':
        return Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateRideStatus('cancelled'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('বাতিল',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () => _updateRideStatus('driver_arriving'),
              icon: const Icon(Icons.navigation_rounded, size: 16),
              label: Text('নেভিগেশন শুরু করুন',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
              style: FilledButton.styleFrom(
                backgroundColor: _indigo,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]);
      case 'driver_arriving':
        return Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateRideStatus('cancelled'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('বাতিল',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () => _updateRideStatus('in_progress'),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text('রাইড শুরু করুন',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
              style: FilledButton.styleFrom(
                backgroundColor: _emerald,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]);
      case 'in_progress':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateRideStatus('cancelled'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('বাতিল',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _showসম্পন্ন করুনRideDialog,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text('সম্পন্ন করুন',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                  style: FilledButton.styleFrom(
                    backgroundColor: _emerald,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _requestEarlyCompletion,
              icon: const Icon(Icons.flag_circle_rounded, size: 18),
              label: Text('আগে সম্পন্ন করুন',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      case 'awaiting_passenger_confirmation':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                'আর্লি কমপ্লিশনের পেমেন্ট যাত্রীর নিশ্চিতকরণের অপেক্ষায়।',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF92400E)),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _updateRideStatus('cancelled'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('রাইড বাতিল করুন',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _requestEarlyCompletion() async {
    final ride = _activeRide;
    if (ride == null || _isUpdatingStatus) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('আগে সম্পন্ন করবেন?',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'এটি এখন পর্যন্ত অতিক্রান্ত দূরত্বের ভিত্তিতে আংশিক ভাড়া হিসাব করবে এবং যাত্রীকে কনফার্মেশন পাঠাবে।',
          style: GoogleFonts.inter(fontSize: 13, color: _slate500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('বাতিল', style: GoogleFonts.inter(color: _slate500)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('নিশ্চিত করুন', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isUpdatingStatus = true);

    // Get live GPS coordinates for accurate distance calculation
    double? lat = _driverProfile?.currentLatitude;
    double? lng = _driverProfile?.currentLongitude;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {
      // Fallback: use last known position or profile coordinates
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) { lat = last.latitude; lng = last.longitude; }
      } catch (_) {}
    }

    final result = await RideshareService.requestEarlyCompletion(
      ride.id,
      latitude: lat,
      longitude: lng,
    );
    if (!mounted) return;

    setState(() => _isUpdatingStatus = false);
    if (result.success && result.data != null) {
      setState(() => _activeRide = result.data);
      _syncRealtimeConnections();
      _showSuccess('যাত্রী confirmation requested for early completion.');
    } else {
      _showError(result.message);
    }
  }

  void _showসম্পন্ন করুনRideDialog() {
    final ride = _activeRide;
    if (ride == null) return;
    final fare = ride.fareEstimate;
    final paymentMethod = ride.paymentMethod.isEmpty ? 'wallet' : ride.paymentMethod;
    final isCash = paymentMethod == 'cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _slate200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _emerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flag_rounded, color: _emerald, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'সম্পন্ন করুন Ride',
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: _slate800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // যাত্রী info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _slate200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _slate100,
                    backgroundImage: ride.riderAvatar != null ? NetworkImage(ride.riderAvatar!) : null,
                    child: ride.riderAvatar == null
                        ? const Icon(Icons.person_rounded, size: 18, color: _slate500)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildIdentityRow(
                      name: ride.riderName,
                      isVerified: ride.riderIsVerified,
                      isPro: ride.riderIsPro,
                      completedTrips: ride.riderসম্পন্ন করুনdTrips,
                      textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _slate800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Route summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _slate50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _slate200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 10, color: Color(0xFF6366F1)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ride.pickupAddress.isNotEmpty ? ride.pickupAddress : 'পিকআপ লোকেশন',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Container(width: 2, height: 12, color: _slate200),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.square_rounded, size: 10, color: _emerald),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ride.dropAddress.isNotEmpty ? ride.dropAddress : 'ড্রপ লোকেশন',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Stats + fare row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _slate50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _slate200),
                    ),
                    child: Column(
                      children: [
                        Text('${ride.distanceKm.toStringAsFixed(1)} km',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF334155))),
                        Text('দূরত্ব', style: GoogleFonts.inter(fontSize: 10, color: _slate400)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _slate50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _slate200),
                    ),
                    child: Column(
                      children: [
                        Text(ride.etaDisplay,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF334155))),
                        Text('Duration', style: GoogleFonts.inter(fontSize: 10, color: _slate400)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text('৳${fare.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text('ভাড়া', style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Payment method info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCash ? const Color(0xFFFFFBEB) : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCash ? const Color(0xFFFDE68A) : const Color(0xFFC7D2FE),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCash ? Icons.payments_rounded : Icons.account_balance_wallet_rounded,
                    size: 18,
                    color: isCash ? const Color(0xFFD97706) : const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCash ? 'নগদ পেমেন্ট' : 'ওয়ালেট পেমেন্ট',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isCash ? const Color(0xFF92400E) : const Color(0xFF3730A3),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCash
                              ? 'সংগ্রহ করুন ৳${fare.toStringAsFixed(0)} যাত্রীর কাছ থেকে, তারপর নিশ্চিত করুন।'
                              : '৳${fare.toStringAsFixed(0)} যাত্রীর ওয়ালেট থেকে স্বয়ংক্রিয়ভাবে কেটে যাবে।',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isCash ? const Color(0xFF78350F) : const Color(0xFF4338CA),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: _slate300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('বাতিল', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _updateRideStatus('completed', paymentMethod: paymentMethod);
                    },
                    icon: Icon(
                      isCash ? Icons.payments_rounded : Icons.check_circle_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isCash ? 'নিশ্চিত করুন & নগদ Received' : 'নিশ্চিত করুন Completion',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: isCash ? const Color(0xFFD97706) : _emerald,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



