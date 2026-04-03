import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/rideshare_models.dart';
import '../../services/adsyconnect_service.dart';
import '../../services/auth_service.dart';
import '../../services/rideshare_service.dart';
import '../../services/rideshare_realtime_service.dart';
import '../../services/translation_service.dart';
import '../../utils/network_error_handler.dart';
import '../adsy_connect_chat_interface.dart';
import '../business_network/profile_screen.dart';
import 'rideshare_map_widget.dart';

class RidesharePassengerPanel extends StatefulWidget {
  const RidesharePassengerPanel({super.key});

  @override
  State<RidesharePassengerPanel> createState() => _RidesharePassengerPanelState();
}

class _RidesharePassengerPanelState extends State<RidesharePassengerPanel>
  with WidgetsBindingObserver {
  final TranslationService _ts = TranslationService();
  String t(String key, {required String fallback}) => _ts.t(key, fallback: fallback);

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
  List<NearbyDriver> _nearbyDrivers = [];
  
  // Loading states
  bool _isLoadingLocation = false;
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
  Timer? _statusRefreshTimer;
  String _searchStatusMessage = 'Looking for nearby drivers...';
  int _driverResponseTimeoutSeconds = 60;
  int _dispatchAttempt = 0;
  DateTime? _targetedAtFromEvent;
  String? _targetedDriverNameFromEvent;
  bool _noDriversInRange = false;
  bool _isReportingCancellation = false;
  StreamSubscription<Position>? _passengerLocationSubscription;

  @override
  void initState() {
    super.initState();
    _ts.addListener(_onTranslationsChanged);
    WidgetsBinding.instance.addObserver(this);
    _startStatusRefreshTimer();
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
    _passengerLocationSubscription?.cancel();
    _realtimeService.dispose();
    super.dispose();
  }

  void _onTranslationsChanged() {
    if (mounted) setState(() {});
  }

  void _startStatusRefreshTimer() {
    _statusRefreshTimer?.cancel();
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _activeRide == null) return;
      if (_activeRide!.isSearching) {
        setState(() {});
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

  String _currentTargetedDriverName(Ride ride) {
    final eventName = (_targetedDriverNameFromEvent ?? '').trim();
    if (eventName.isNotEmpty) {
      return eventName;
    }
    return ride.targetedDriver?.userName.trim() ?? '';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshLocationPermissionStatus(
        autoFillCurrentLocation: _pickupPoint == null && _activeRide == null,
      );
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
        _showError('Location service is off. Please enable GPS to use rideshare.');
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
        _showError('Location permission permanently denied. Please enable it in app settings.');
        await Geolocator.openAppSettings();
        return;
      }

      if (mounted) {
        setState(() => _locationGranted = true);
      }

      if (_pickupPoint == null) {
        _didAutoFillCurrentLocation = true;
        await _useCurrentLocation(showSuccessMessage: false);
        _showSuccess('Location enabled. Pickup set from your current location.');
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
      _applyRideState(result.data, isLoading: false);
    }
  }

  Future<void> _loadActiveRideById(String rideId) async {
    setState(() => _isLoadingActiveRide = true);
    final result = await RideshareService.getRide(rideId);
    if (mounted) {
      _applyRideState(result.data, isLoading: false);
    }
  }

  void _applyRideState(Ride? ride, {required bool isLoading}) {
    setState(() {
      _activeRide = ride;
      _searchStatusMessage = _deriveSearchStatusMessage(ride);
      _dispatchAttempt = ride?.dispatchAttempt ?? 0;
      _targetedAtFromEvent = ride == null
          ? null
          : (ride.isSearching ? (ride.targetedAt ?? _targetedAtFromEvent) : null);
      _targetedDriverNameFromEvent = ride == null
          ? null
          : (ride.isSearching
              ? (ride.targetedDriver?.userName ?? _targetedDriverNameFromEvent)
              : null);
      _isLoadingActiveRide = isLoading;
    });
    _syncRideRealtimeConnection();
  }

  String _deriveSearchStatusMessage(Ride? ride) {
    if (ride == null) {
      return t('rideshare_finding_driver_status', fallback: 'Looking for nearby drivers...');
    }

    for (final entry in ride.statusHistory.reversed) {
      final event = entry.metadata['event'];
      if (event == 'driver_skipped') {
        continue;
      }
      final message = entry.metadata['status_text'] ?? entry.metadata['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    final targetedDriverName = _currentTargetedDriverName(ride);
    if (ride.isSearching && targetedDriverName.isNotEmpty) {
      return 'Request sent to $targetedDriverName';
    }
    if (ride.isSearching) {
      return t('rideshare_finding_driver_status', fallback: 'Looking for nearby drivers...');
    }
    if (ride.isCancelled && (ride.cancellationReason?.isNotEmpty ?? false)) {
      return ride.cancellationReason!;
    }
    return ride.statusDisplay;
  }

  void _syncRideRealtimeConnection() {
    final ride = _activeRide;
    if (ride == null) {
      _rideEventSubscription?.cancel();
      _rideEventSubscription = null;
      _realtimeService.disconnectRide();
      return;
    }

    _rideEventSubscription ??= _realtimeService.rideEvents.listen(_handleRideRealtimeEvent);
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
    if (!mounted || _activeRide == null || _isCancellingRide) {
      return;
    }

    final type = event['type']?.toString() ?? '';
    final eventName = event['event']?.toString() ?? '';
    if (type == 'driver.location') {
      final location = RideDriverLocation.fromJson(event);
      setState(() {
        _activeRide = _activeRide?.copyWith(latestDriverLocation: location);
      });
      return;
    }

    if (eventName == 'search_status_updated') {
      final message = event['message']?.toString();
      final timeoutSeconds = _parseInt(
        event['driver_response_timeout_seconds'],
        _driverResponseTimeoutSeconds,
      );
      final dispatchAttempt = _parseInt(event['dispatch_attempt'], _dispatchAttempt);
      final targetedAt = DateTime.tryParse(event['targeted_at']?.toString() ?? '');
      final targetedDriverId = event['targeted_driver_id']?.toString();
      final targetedDriverName = event['targeted_driver_name']?.toString();
      final noDrivers = event['no_drivers_in_range'] == true;

      setState(() {
        if (message != null && message.isNotEmpty) {
          _searchStatusMessage = message;
        }
        _noDriversInRange = noDrivers;
        _driverResponseTimeoutSeconds = timeoutSeconds;
        _dispatchAttempt = dispatchAttempt;
        _targetedDriverNameFromEvent =
          (targetedDriverName == null || targetedDriverName.trim().isEmpty)
            ? null
            : targetedDriverName.trim();
        _targetedAtFromEvent = (targetedDriverId == null || targetedDriverId.isEmpty)
            ? null
            : targetedAt;
      });
    }

    if (type == 'ride.event') {
      final rideId = event['ride_id']?.toString() ?? '';
      if (rideId.isEmpty) {
        return;
      }
      await _loadActiveRideById(rideId);
      if (eventName == 'ride_auto_cancelled') {
        _showError(event['message']?.toString() ?? 'No drivers available, please try again.');
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
        _showError('Location permission permanently denied. Please enable in settings.');
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
    if (query.length < 3) {
      setState(() => _pickupSuggestions = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final result = await RideshareService.searchLocations(query);
      if (mounted && result.success) {
        setState(() => _pickupSuggestions = result.data ?? []);
      }
    });
  }

  void _onDropSearch(String query) {
    _searchDebounce?.cancel();
    if (query.length < 3) {
      setState(() => _dropSuggestions = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final result = await RideshareService.searchLocations(query);
      if (mounted && result.success) {
        setState(() => _dropSuggestions = result.data ?? []);
      }
    });
  }

  void _selectPickupSuggestion(RidePoint point) {
    setState(() {
      _pickupPoint = point;
      _pickupController.text = point.name;
      _pickupSuggestions = [];
      _activeInput = 'drop';
    });
    _loadNearbyDrivers();
    _requestEstimate();
  }

  void _selectDropSuggestion(RidePoint point) {
    setState(() {
      _dropPoint = point;
      _dropController.text = point.name;
      _dropSuggestions = [];
    });
    _requestEstimate();
  }

  Future<void> _loadNearbyDrivers() async {
    if (_pickupPoint == null) return;
    final result = await RideshareService.getNearbyDrivers(
      _pickupPoint!.latitude,
      _pickupPoint!.longitude,
      vehicleType: _selectedVehicleType,
    );
    if (mounted && result.success) {
      setState(() => _nearbyDrivers = result.data ?? []);
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
      _showError(t('rideshare_location_required', fallback: 'Location access required before booking a ride.'));
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
        _showSuccess(t('rideshare_ride_requested', fallback: 'Ride requested! Looking for a driver...'));
      } else {
        final msg = result.message.toLowerCase();
        if (msg.contains('active ride') || msg.contains('already have')) {
          // Hide booking form with spinner. Use the ride_id from the error
          // response to fetch the specific ride directly â€” more reliable than
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
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          t('rideshare_cancel_ride_confirm', fallback: 'Are you sure you want to cancel? You can book a new ride after cancellation.'),
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('rideshare_keep_ride', fallback: 'Keep Ride'),
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: const Color(0xFF6366F1))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

    // Disconnect realtime immediately to prevent incoming events from
    // overwriting state while the cancel API call is in flight.
    _rideEventSubscription?.cancel();
    _rideEventSubscription = null;
    _realtimeService.disconnectRide();

    setState(() => _isCancellingRide = true);

    final result = await RideshareService.cancelRide(
      _activeRide!.id,
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
          _nearbyDrivers = [];
          _pickupSuggestions = [];
          _dropSuggestions = [];
          _activeInput = 'pickup';
          _searchStatusMessage = t('rideshare_finding_driver_status', fallback: 'Looking for nearby drivers...');
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

      final chatroom = await AdsyConnectService.getOrCreateChatRoom(driver.userId);
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
        builder: (_) => DraggableScrollableSheet(
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
              userId: driver.userId,
              userName: driver.userName,
              userAvatar: driver.userAvatar,
              profession: 'Driver',
              isOnline: driver.isOnline,
            ),
          ),
        ),
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

  Widget _buildVerifiedBadge() {
    return const Icon(
      Icons.verified,
      size: 15,
      color: Color(0xFF3B82F6),
    );
  }

  Widget _buildProBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5),
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
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0369A1),
        ),
      ),
    );
  }

  Widget _buildIdentityRow({
    required String name,
    required bool isVerified,
    required bool isPro,
    required int completedTrips,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        if (isVerified) _buildVerifiedBadge(),
        if (isPro) _buildProBadge(),
        _buildTripsBadge(completedTrips),
      ],
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
          t('rideshare_report_driver_cancellation', fallback: 'Report Driver Cancellation'),
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: t('rideshare_add_details_hint', fallback: 'Add details for support...'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('rideshare_close', fallback: 'Close'), style: GoogleFonts.inter()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('rideshare_submit', fallback: 'Submit'), style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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
    if (ride.assignedDriver?.currentLatitude != null && ride.assignedDriver?.currentLongitude != null) {
      return RidePoint(
        name: 'Driver',
        latitude: ride.assignedDriver!.currentLatitude!,
        longitude: ride.assignedDriver!.currentLongitude!,
      );
    }
    return null;
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
                ? t('rideshare_cash_completion_note', fallback: 'Ride complete. Please pay the driver in cash.')
                : t('rideshare_wallet_completion_note', fallback: 'Ride complete and wallet payment confirmed.'))
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
                t('rideshare_choose_payment_method', fallback: 'Choose Payment Method'),
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
'${t('rideshare_trip_fare', fallback: 'Trip Fare')}: ৳${payableFare.toStringAsFixed(0)}',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              _buildPaymentMethodTile(
                ctx,
                value: 'wallet',
                title: t('rideshare_wallet_payment_title', fallback: 'Pay with Adsy Balance'),
                subtitle: t('rideshare_wallet_subtitle', fallback: 'Fare will be deducted from your in-app balance instantly.'),
                icon: Icons.account_balance_wallet_rounded,
                accent: const Color(0xFF6366F1),
              ),
              const SizedBox(height: 10),
              _buildPaymentMethodTile(
                ctx,
                value: 'cash',
                title: t('rideshare_cash_payment_title', fallback: 'Pay Driver in Cash'),
                subtitle: t('rideshare_cash_subtitle', fallback: 'You will pay the driver directly in cash at the end of the ride.'),
                icon: Icons.payments_rounded,
                accent: const Color(0xFF10B981),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(
    BuildContext context, {
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
          color: accent.withValues(alpha: 0.06),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B), height: 1.35),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: accent),
          ],
        ),
      ),
    );
  }

  void _onMapTap(double latitude, double longitude) async {
    final result = await RideshareService.reverseGeocode(latitude, longitude);
    if (!mounted || !result.success || result.data == null) return;
    
    final point = result.data!;
    setState(() {
      if (_activeInput == 'pickup') {
        _pickupPoint = point;
        _pickupController.text = point.name;
        _activeInput = 'drop';
        _loadNearbyDrivers();
      } else {
        _dropPoint = point;
        _dropController.text = point.name;
      }
    });
    _requestEstimate();
  }

  void _showError(String message) {
    if (!mounted) return;
    final resolvedMessage = _resolveErrorMessage(message);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(resolvedMessage, style: GoogleFonts.inter(fontSize: 13)),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  String _resolveErrorMessage(String message) {
    final raw = message.trim();
    if (raw.isEmpty) {
      return 'Something went wrong. Please try again.';
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

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.inter(fontSize: 13)),
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

    // Active ride takes full priority â€” booking form is completely hidden
    if (_activeRide != null) {
      return RefreshIndicator(
        color: const Color(0xFF6366F1),
        onRefresh: _loadActiveRide,
        child: _buildActiveRideView(),
      );
    }

    // No active ride â€” show booking form
    return _buildBookingView();
  }

  Widget _buildActiveRideView() {
    final ride = _activeRide!;
    final canCancelRide =
      ride.passengerCanCancel &&
      !ride.isInProgress &&
      !ride.isAwaitingPassengerConfirmation &&
      !ride.isCompleted &&
      !ride.isCancelled;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          // Status Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Gradient header with status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: ride.isSearching
                          ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                          : ride.isInProgress
                              ? [const Color(0xFF10B981), const Color(0xFF059669)]
                              : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: Row(
                    children: [
                      if (ride.isSearching)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _passengerStatusLabel(ride),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        ride.vehicleIcon,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Route info
                      _buildRouteInfo(ride),

                      if (ride.isCancelled && _shouldShowCancellationReason(ride)) ...[
                        const SizedBox(height: 12),
                        _buildCancellationReasonCard(ride),
                      ],

                      if (ride.isSearching) ...[
                        const SizedBox(height: 12),
                        _buildSearchStatusCard(ride),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Stats row
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            _buildStatItem(t('rideshare_fare', fallback: 'Fare'), '৳${ride.payableFare.toStringAsFixed(0)}'),
                            _buildStatDivider(),
                            _buildStatItem(t('rideshare_distance', fallback: 'Distance'), '${ride.distanceKm.toStringAsFixed(1)} km'),
                            _buildStatDivider(),
                            _buildStatItem(t('rideshare_eta', fallback: 'ETA'), ride.etaDisplay),
                          ],
                        ),
                      ),
                      
                      // Driver info (if assigned)
                      if (ride.assignedDriver != null) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        _buildDriverInfo(ride.assignedDriver!),
                      ],
                      
                      const SizedBox(height: 16),

                      if (ride.isAwaitingPassengerConfirmation)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _confirmEarlyCompletion(false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF6366F1),
                                  side: const BorderSide(color: Color(0xFF6366F1)),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  t('rideshare_continue_ride', fallback: 'Continue Ride'),
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _confirmEarlyCompletion(true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  t('rideshare_confirm_payment', fallback: 'Confirm Payment'),
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        )
                      else if (canCancelRide)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isCancellingRide ? null : _confirmCancelRide,
                            icon: _isCancellingRide
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : const Icon(Icons.cancel_outlined, size: 18),
                            label: Text(
                              _isCancellingRide
                                  ? 'Cancelling...'
                                  : (ride.isSearching ? t('rideshare_cancel_request', fallback: 'Cancel Request') : t('rideshare_cancel_ride', fallback: 'Cancel Ride')),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade600,
                              side: BorderSide(color: Colors.red.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        )
                      else if (ride.canReportDriver)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isReportingCancellation ? null : _reportDriverCancellation,
                            icon: _isReportingCancellation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.report_problem_rounded, size: 18),
                            label: Text(
                              _isReportingCancellation ? t('rideshare_submitting', fallback: 'Submitting...') : t('rideshare_report_driver_cancellation', fallback: 'Report Driver Cancellation'),
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFEA580C),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Map
          Container(
            height: _mapViewportHeight(context),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: RideshareMapWidget(
              pickupPoint: ride.pickupPoint,
              dropPoint: ride.dropPoint,
              routeGeometry: ride.routeGeometry,
              driverLocation: _currentDriverPoint(ride),
              driverHeading: ride.latestDriverLocation?.heading,
              followDriver: ride.isDriverArriving || ride.isInProgress,
              onMapTap: null,
            ),
          ),
        ],
      ),
    );
  }

  String _passengerStatusLabel(Ride ride) {
    if (ride.isSearching) {
      return t('rideshare_finding_driver_status', fallback: 'Looking for a driver');
    }
    if (ride.isAccepted) {
      return t('rideshare_driver_assigned', fallback: 'Driver confirmed');
    }
    return ride.statusDisplay;
  }

  Widget _buildSearchStatusCard(Ride ride) {
    final now = DateTime.now();
    final secondsRemaining = _targetedRemainingSeconds(ride, now: now);
    final targetedDriverName = _currentTargetedDriverName(ride);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _noDriversInRange ? Icons.location_off_rounded : Icons.radar_rounded,
                size: 18,
                color: _noDriversInRange ? const Color(0xFFDC2626) : const Color(0xFFD97706),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _searchStatusMessage,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _noDriversInRange ? const Color(0xFFDC2626) : const Color(0xFF92400E),
                  ),
                ),
              ),
              if (targetedDriverName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _formatDuration(secondsRemaining),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (_noDriversInRange) ...[
            Text(
              'à¦†à¦ªà¦¨à¦¾à¦° à¦à¦²à¦¾à¦•à¦¾à¦¯à¦¼ à¦•à§‹à¦¨à§‹ à¦¡à§à¦°à¦¾à¦‡à¦­à¦¾à¦° à¦ªà¦¾à¦“à¦¯à¦¼à¦¾ à¦¯à¦¾à¦šà§à¦›à§‡ à¦¨à¦¾à¥¤ à¦¶à¦¹à¦° à¦à¦²à¦¾à¦•à¦¾ à¦¥à§‡à¦•à§‡ à¦šà§‡à¦·à§à¦Ÿà¦¾ à¦•à¦°à§à¦¨à¥¤',
              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFFDC2626), height: 1.4),
            ),
            const SizedBox(height: 4),
          ],
          if (targetedDriverName.isNotEmpty) ...[
            Text(
              'Current driver: $targetedDriverName',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF92400E)),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteInfo(Ride ride) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('rideshare_pickup', fallback: 'Pickup').toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6366F1),
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      ride.pickupAddress,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 18,
                  color: const Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
            Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('rideshare_drop', fallback: 'Drop').toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      ride.dropAddress,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _shouldShowCancellationReason(Ride ride) {
    final reason = ride.cancellationReason?.trim() ?? '';
    if (reason.isEmpty) {
      return false;
    }

    final lower = reason.toLowerCase();
    return lower.contains('no drivers available') ||
        lower.contains('driver available') ||
        lower.contains('remote area');
  }

  Widget _buildCancellationReasonCard(Ride ride) {
    final reason = ride.cancellationReason?.trim() ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reason,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFB91C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 30,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildDriverInfo(DriverProfile driver) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _openBusinessProfile(driver.userId),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFF1F5F9),
            backgroundImage: driver.userAvatar != null
                ? NetworkImage(driver.userAvatar!)
                : null,
            child: driver.userAvatar == null
                ? const Icon(Icons.person_rounded, color: Color(0xFF64748B))
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _openBusinessProfile(driver.userId),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIdentityRow(
                  name: driver.userName,
                  isVerified: driver.userIsVerified,
                  isPro: driver.userIsPro,
                  completedTrips: driver.totalTrips,
                ),
                if (driver.defaultVehicle != null)
                  Text(
                    '${driver.defaultVehicle!.vehicleIcon} ${driver.defaultVehicle!.registrationNumber}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_activeRide != null && _canChatWithDriver(_activeRide!)) ...[
          GestureDetector(
            onTap: () => _openDriverChat(_activeRide!),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
              ),
              child: Image.asset(
                'assets/images/chat_icon.png',
                width: 18,
                height: 18,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.chat_bubble_rounded,
                    size: 18,
                    color: Color(0xFF10B981),
                  );
                },
              ),
            ),
          ),
        ],
        if (driver.userPhone.isNotEmpty)
          GestureDetector(
            onTap: () async {
              final uri = Uri(scheme: 'tel', path: driver.userPhone);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                ),
              ),
              child: const Icon(
                Icons.phone_rounded,
                size: 20,
                color: Color(0xFF10B981),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBookingView() {
    if (_isCheckingLocationPermission) {
      return RefreshIndicator(
        color: const Color(0xFF6366F1),
        onRefresh: () => _refreshLocationPermissionStatus(
          autoFillCurrentLocation: _pickupPoint == null,
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
          child: const SizedBox(
            height: 420,
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
              ),
            ),
          ),
        ),
      );
    }

    if (!_locationGranted) {
      return RefreshIndicator(
        color: const Color(0xFF6366F1),
        onRefresh: () => _refreshLocationPermissionStatus(
          autoFillCurrentLocation: _pickupPoint == null,
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
          child: SizedBox(
            height: 460,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFEA580C),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      t('rideshare_location_required_title', fallback: 'Location Access Required'),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t('rideshare_enable_location_desc', fallback: 'Enable location to book rides and auto-set pickup.'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isLoadingLocation ? null : _requestLocationPermission,
                        icon: _isLoadingLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.my_location_rounded, size: 18),
                        label: Text(
                          _isLoadingLocation ? t('rideshare_enabling', fallback: 'Enabling...') : t('rideshare_enable_location', fallback: 'Enable Location'),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF6366F1),
      onRefresh: _loadActiveRide,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
        child: Column(
          children: [
            // Booking form card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.route_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('rideshare_book_ride', fallback: 'Book Ride'),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            t('rideshare_enter_location_to_start', fallback: 'Enter location to start'),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildLocationInputs(),
                  const SizedBox(height: 16),
                  _buildVehicleSelector(),
                  const SizedBox(height: 16),
                  _buildPaymentMethodSelector(),
                  if (_estimate != null || _isEstimating) ...[
                    const SizedBox(height: 16),
                    _buildEstimateCard(),
                  ],
                  const SizedBox(height: 16),
                  _buildBookButton(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: _mapViewportHeight(context),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: RideshareMapWidget(
                pickupPoint: _pickupPoint,
                dropPoint: _dropPoint,
                routeGeometry: _estimate?.routeGeometry,
                nearbyDrivers: _nearbyDrivers,
                activeSelection: _activeInput,
                onMapTap: _onMapTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    final walletBalance = AuthService.currentUser?.balance ?? 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.payment_rounded, size: 15, color: Color(0xFF6366F1)),
            const SizedBox(width: 6),
            Text(
              t('rideshare_payment_method', fallback: 'Payment Method'),
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedPaymentMethod = 'wallet'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedPaymentMethod == 'wallet'
                        ? const Color(0xFF6366F1).withValues(alpha: 0.08)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedPaymentMethod == 'wallet'
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFE2E8F0),
                      width: _selectedPaymentMethod == 'wallet' ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 16,
                            color: _selectedPaymentMethod == 'wallet'
                                ? const Color(0xFF6366F1)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            t('rideshare_wallet', fallback: 'Wallet'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _selectedPaymentMethod == 'wallet'
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          if (_selectedPaymentMethod == 'wallet')
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF6366F1)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '৳${walletBalance.toStringAsFixed(0)} ${t("rideshare_balance", fallback: "Balance")}',
                        style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/deposit-withdraw'),
                        child: Text(
                          t('rideshare_add_funds', fallback: '+ Add Funds'),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedPaymentMethod = 'cash'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedPaymentMethod == 'cash'
                        ? const Color(0xFF10B981).withValues(alpha: 0.08)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedPaymentMethod == 'cash'
                          ? const Color(0xFF10B981)
                          : const Color(0xFFE2E8F0),
                      width: _selectedPaymentMethod == 'cash' ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.payments_rounded,
                            size: 16,
                            color: _selectedPaymentMethod == 'cash'
                                ? const Color(0xFF10B981)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            t('rideshare_cash', fallback: 'Cash'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _selectedPaymentMethod == 'cash'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          if (_selectedPaymentMethod == 'cash')
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF10B981)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t('rideshare_pay_driver_directly', fallback: 'Pay driver directly'),
                        style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t('rideshare_no_wallet_needed', fallback: 'No wallet needed'),
                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFCBD5E1)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationInputs() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Route indicator
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 50,
              color: const Color(0xFFE2E8F0),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        
        // Input fields
        Expanded(
          child: Column(
            children: [
              // Pickup input
              _buildLocationInput(
                controller: _pickupController,
                label: t('rideshare_pickup_location', fallback: 'Pickup Location'),
                hint: t('rideshare_search_pickup', fallback: 'Search pickup...').toString(),
                isActive: _activeInput == 'pickup',
                onTap: () => setState(() => _activeInput = 'pickup'),
                onChanged: _onPickupSearch,
                suggestions: _pickupSuggestions,
                onSuggestionTap: _selectPickupSuggestion,
                trailing: _buildCurrentLocationButton(),
              ),
              const SizedBox(height: 12),
              
              // Drop input
              _buildLocationInput(
                controller: _dropController,
                label: t('rideshare_drop_location', fallback: 'Drop Location'),
                hint: t('rideshare_search_drop', fallback: 'Search drop...').toString(),
                isActive: _activeInput == 'drop',
                onTap: () => setState(() => _activeInput = 'drop'),
                onChanged: _onDropSearch,
                suggestions: _dropSuggestions,
                onSuggestionTap: _selectDropSuggestion,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isActive,
    required VoidCallback onTap,
    required Function(String) onChanged,
    required List<RidePoint> suggestions,
    required Function(RidePoint) onSuggestionTap,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? Colors.white : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                width: isActive ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TextField(
                        controller: controller,
                        onChanged: onChanged,
                        onTap: onTap,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
        
        // Suggestions dropdown
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return InkWell(
                  onTap: () => onSuggestionTap(suggestion),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            suggestion.name,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF1E293B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentLocationButton() {
    return GestureDetector(
      onTap: _isLoadingLocation ? null : _useCurrentLocation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _isLoadingLocation
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.my_location_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    t('rideshare_current_location_btn', fallback: 'Current'),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildVehicleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('rideshare_vehicle_type', fallback: 'Vehicle Type'),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildVehicleOption('bike', '🏍', t('rideshare_vehicle_bike', fallback: 'Bike')),
            const SizedBox(width: 8),
            _buildVehicleOption('car', '🚗', t('rideshare_vehicle_car', fallback: 'Car')),
            const SizedBox(width: 8),
            _buildVehicleOption('cng', '🛺', t('rideshare_vehicle_cng', fallback: 'CNG')),
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleOption(String type, String icon, String label) {
    final isSelected = _selectedVehicleType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedVehicleType = type);
          _loadNearbyDrivers();
          _requestEstimate();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  )
                : null,
            color: isSelected ? null : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstimateCard() {
    if (_isEstimating) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              t('rideshare_calculating_fare', fallback: 'Calculating fare...'),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('rideshare_estimated_fare', fallback: 'Estimated Fare').toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16A34A),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '৳${_estimate!.fare.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.straighten_rounded,
                      size: 12,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_estimate!.distanceKm.toStringAsFixed(1)} km',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _estimate!.etaDisplay,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    final canBook = _pickupPoint != null && _dropPoint != null && _estimate != null;
    
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: canBook
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : null,
        child: ElevatedButton(
          onPressed: canBook && !_isCreatingRide ? _createRide : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canBook ? Colors.transparent : const Color(0xFFE2E8F0),
            foregroundColor: canBook ? Colors.white : const Color(0xFF94A3B8),
            disabledForegroundColor: const Color(0xFF94A3B8),
            disabledBackgroundColor: const Color(0xFFE2E8F0),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: _isCreatingRide
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      canBook ? Icons.directions_car_rounded : Icons.edit_location_alt_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      canBook ? t('rideshare_book_ride_now', fallback: 'Book Ride Now') : t('rideshare_enter_locations', fallback: 'Enter Locations'),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}





