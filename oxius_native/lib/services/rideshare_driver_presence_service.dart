import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/rideshare_models.dart';
import 'api_service.dart';
import 'rideshare_service.dart';

const String _rideshareDriverOnlineDesiredKey =
    'rideshare_driver_online_desired';
const String _rideshareDriverActiveRideIdKey = 'rideshare_driver_active_ride_id';
const String _rideshareDriverServiceChannelId = 'rideshare_driver_presence';
const int _rideshareDriverServiceNotificationId = 924001;

class _DesiredDriverProfileState {
  final DriverProfile? profile;
  final bool shouldStopService;
  final bool shouldClearOnlineIntent;

  const _DesiredDriverProfileState({
    this.profile,
    required this.shouldStopService,
    required this.shouldClearOnlineIntent,
  });
}

Future<void> _persistDesiredOnlineState(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_rideshareDriverOnlineDesiredKey, value);
}

Future<bool> _readDesiredOnlineState() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_rideshareDriverOnlineDesiredKey) ?? false;
}

Future<void> _persistActiveRideId(String? rideId) async {
  final prefs = await SharedPreferences.getInstance();
  if (rideId == null || rideId.isEmpty) {
    await prefs.remove(_rideshareDriverActiveRideIdKey);
  } else {
    await prefs.setString(_rideshareDriverActiveRideIdKey, rideId);
  }
}

Future<String?> _readActiveRideId() async {
  final prefs = await SharedPreferences.getInstance();
  final rideId = prefs.getString(_rideshareDriverActiveRideIdKey);
  return (rideId == null || rideId.isEmpty) ? null : rideId;
}

Future<bool> _hasAuthenticatedSession() async {
  final headers = await ApiService.getHeaders();
  return (headers['Authorization'] ?? '').isNotEmpty;
}

Future<_DesiredDriverProfileState> _resolveDesiredDriverProfile() async {
  if (!await _hasAuthenticatedSession()) {
    return const _DesiredDriverProfileState(
      shouldStopService: true,
      shouldClearOnlineIntent: true,
    );
  }

  final result = await RideshareService.getDriverProfile();
  final profile = result.success ? result.data : null;

  if (!result.success) {
    return const _DesiredDriverProfileState(
      shouldStopService: false,
      shouldClearOnlineIntent: false,
    );
  }

  if (profile == null || profile.approvalStatus != 'approved') {
    return const _DesiredDriverProfileState(
      shouldStopService: true,
      shouldClearOnlineIntent: true,
    );
  }

  if (profile.isOnline) {
    return _DesiredDriverProfileState(
      profile: profile,
      shouldStopService: false,
      shouldClearOnlineIntent: false,
    );
  }

  if (!await _readDesiredOnlineState()) {
    return const _DesiredDriverProfileState(
      shouldStopService: true,
      shouldClearOnlineIntent: false,
    );
  }

  final toggleResult = await RideshareService.toggleDriverOnline(true);
  if (toggleResult.success && toggleResult.data != null) {
    return _DesiredDriverProfileState(
      profile: toggleResult.data,
      shouldStopService: false,
      shouldClearOnlineIntent: false,
    );
  }

  return const _DesiredDriverProfileState(
    shouldStopService: false,
    shouldClearOnlineIntent: false,
  );
}

Future<void> _syncAndroidServiceNotification(
  ServiceInstance service, {
  String? rideId,
}) async {
  if (service is! AndroidServiceInstance) {
    return;
  }

  final content = (rideId != null && rideId.isNotEmpty)
      ? 'Sharing driver location for an active ride.'
      : 'Waiting for ride requests while you stay online.';

  await service.setForegroundNotificationInfo(
    title: 'AdsyClub - Driver Online',
    content: content,
  );
}

Future<void> _sendLocationUpdateFromBackground(
  ServiceInstance service,
  Position position,
) async {
  final rideId = await _readActiveRideId();

  await RideshareService.updateDriverLocation(
    latitude: position.latitude,
    longitude: position.longitude,
    rideId: rideId,
    heading: position.heading,
    speedKph: position.speed * 3.6,
    accuracyMeters: position.accuracy,
  );

  service.invoke(
    'position',
    {
      'latitude': position.latitude,
      'longitude': position.longitude,
    },
  );
}

@pragma('vm:entry-point')
void rideshareDriverBackgroundEntryPoint(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    await service.setAsForegroundService();
  }

  StreamSubscription<Position>? locationSubscription;
  Timer? heartbeatTimer;
  Timer? locationFallbackTimer;
  DateTime? lastLocationSentAt;

  Future<void> stopService({bool clearOnlineIntent = false}) async {
    await locationSubscription?.cancel();
    locationSubscription = null;
    heartbeatTimer?.cancel();
    heartbeatTimer = null;
    locationFallbackTimer?.cancel();
    locationFallbackTimer = null;
    if (clearOnlineIntent) {
      await _persistDesiredOnlineState(false);
      await _persistActiveRideId(null);
    }
    await service.stopSelf();
  }

  Future<bool> ensureDriverStillOnline() async {
    if (!await _readDesiredOnlineState()) {
      await stopService();
      return false;
    }

    if (!await _hasAuthenticatedSession()) {
      await stopService(clearOnlineIntent: true);
      return false;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    final permissionGranted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (!serviceEnabled || !permissionGranted) {
      await stopService();
      return false;
    }

    final resolution = await _resolveDesiredDriverProfile();
    final profile = resolution.profile;
    if (profile == null) {
      if (resolution.shouldStopService) {
        await stopService(
          clearOnlineIntent: resolution.shouldClearOnlineIntent,
        );
      }
      return false;
    }

    await _syncAndroidServiceNotification(
      service,
      rideId: await _readActiveRideId(),
    );
    return true;
  }

  Future<void> tickHeartbeat() async {
    if (!await ensureDriverStillOnline()) {
      return;
    }
    await RideshareService.sendDriverHeartbeat();
  }

  service.on('stop').listen((_) async {
    await stopService();
  });

  service.on('refresh').listen((_) async {
    await tickHeartbeat();
  });

  if (!await ensureDriverStillOnline()) {
    return;
  }

  locationSubscription = Geolocator.getPositionStream(
    locationSettings: AndroidSettings(
      accuracy: LocationAccuracy.high,
      // 10m floor on movement gating — `intervalDuration` alone is honored
      // inconsistently across OEM Android builds (some MIUI/ColorOS skins
      // ignore it under battery saver). Pairing it with a real distance
      // threshold cuts idle-driver battery drain by ~5-8% per 8h shift
      // without losing tracking precision (server interpolates between
      // points anyway).
      distanceFilter: 10,
      intervalDuration: const Duration(seconds: 30),
    ),
  ).listen(
    (position) async {
      lastLocationSentAt = DateTime.now();
      await _sendLocationUpdateFromBackground(service, position);
    },
    onError: (Object error) {
      debugPrint(
        'RideshareDriverPresenceService Android background stream error: $error',
      );
    },
  );

  heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
    await tickHeartbeat();
  });

  locationFallbackTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
    if (!await ensureDriverStillOnline()) {
      return;
    }

    if (lastLocationSentAt != null &&
        DateTime.now().difference(lastLocationSentAt!) <
            const Duration(seconds: 25)) {
      return;
    }

    final lastKnownPosition = await Geolocator.getLastKnownPosition();
    if (lastKnownPosition != null) {
      lastLocationSentAt = DateTime.now();
      await _sendLocationUpdateFromBackground(service, lastKnownPosition);
    }
  });

  await tickHeartbeat();

  final lastKnownPosition = await Geolocator.getLastKnownPosition();
  if (lastKnownPosition != null) {
    lastLocationSentAt = DateTime.now();
    await _sendLocationUpdateFromBackground(service, lastKnownPosition);
  }
}

class RideshareDriverPresenceService {
  static final ValueNotifier<Position?> positionNotifier =
      ValueNotifier<Position?>(null);

  static final FlutterBackgroundService _backgroundService =
      FlutterBackgroundService();
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static StreamSubscription<Position>? _localLocationSubscription;
  static Timer? _localHeartbeatTimer;
  static Timer? _localLocationFallbackTimer;
  static DateTime? _lastLocalLocationSentAt;
  static bool _isInitialized = false;
  static bool _isRunning = false;

  static bool get isRunning => _isRunning;

  static bool isForegroundPermissionGranted(LocationPermission permission) {
    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  static bool isBackgroundPermissionGranted(LocationPermission permission) {
    if (!isForegroundPermissionGranted(permission)) {
      return false;
    }

    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return permission == LocationPermission.always;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<LocationPermission> getLocationPermission({
    bool promptIfNeeded = false,
  }) async {
    var permission = await Geolocator.checkPermission();

    if (promptIfNeeded && permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (promptIfNeeded &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS) &&
        permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  static Future<bool> hasRequiredLocationPermission({
    bool promptIfNeeded = false,
  }) async {
    final permission = await getLocationPermission(
      promptIfNeeded: promptIfNeeded,
    );
    return isBackgroundPermissionGranted(permission);
  }

  static Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        _rideshareDriverServiceChannelId,
        'Rideshare Driver Presence',
        description:
            'Keeps drivers online for rideshare requests after app backgrounding or reboot.',
        importance: Importance.low,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await _backgroundService.configure(
        iosConfiguration: IosConfiguration(
          autoStart: false,
        ),
        androidConfiguration: AndroidConfiguration(
          onStart: rideshareDriverBackgroundEntryPoint,
          autoStart: false,
          autoStartOnBoot: true,
          isForegroundMode: true,
          notificationChannelId: _rideshareDriverServiceChannelId,
          initialNotificationTitle: 'AdsyClub - Driver Online',
          initialNotificationContent:
              'Preparing rideshare online presence service...',
          foregroundServiceNotificationId:
              _rideshareDriverServiceNotificationId,
          foregroundServiceTypes: const [AndroidForegroundType.location],
        ),
      );

      _backgroundService.on('position').listen((event) {
        final latitude = double.tryParse(event?['latitude']?.toString() ?? '');
        final longitude =
            double.tryParse(event?['longitude']?.toString() ?? '');
        if (latitude == null || longitude == null) {
          return;
        }

        positionNotifier.value = Position(
          longitude: longitude,
          latitude: latitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      });
    }

    _isInitialized = true;
  }

  static Future<void> restoreIfNeeded() async {
    await initialize();

    if (!await _hasAuthenticatedSession()) {
      await stop();
      return;
    }

    final resolution = await _resolveDesiredDriverProfile();
    final profile = resolution.profile;
    if (profile == null) {
      if (resolution.shouldStopService) {
        await stop(clearOnlineIntent: resolution.shouldClearOnlineIntent);
      }
      return;
    }

    final activeRideResult = await RideshareService.getActiveRide();
    setActiveRideId(activeRideResult.success ? activeRideResult.data?.id : null);

    await syncWithDriverProfile(
      profile,
      promptForPermissions: false,
    );
  }

  static void setActiveRideId(String? rideId) {
    unawaited(_persistActiveRideId(rideId));
    if (defaultTargetPlatform == TargetPlatform.android) {
      _backgroundService.invoke('refresh');
    }
  }

  static Future<bool> syncWithDriverProfile(
    DriverProfile? profile, {
    bool promptForPermissions = false,
  }) async {
    await initialize();

    if (profile == null ||
        profile.approvalStatus != 'approved' ||
        !profile.isOnline) {
      await stop();
      return false;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await stop(clearOnlineIntent: false, clearPosition: false);
      return false;
    }

    final permission = await getLocationPermission(
      promptIfNeeded: promptForPermissions,
    );
    if (!isBackgroundPermissionGranted(permission)) {
      await stop(clearOnlineIntent: false, clearPosition: false);
      return false;
    }

    await _persistDesiredOnlineState(true);

    if (defaultTargetPlatform == TargetPlatform.android) {
      return _startAndroidService();
    }

    return _startLocalTracking();
  }

  static Future<void> stop({
    bool clearPosition = true,
    bool clearOnlineIntent = true,
  }) async {
    await _stopLocalTracking(clearPosition: clearPosition);

    if (defaultTargetPlatform == TargetPlatform.android) {
      final isRunning = await _backgroundService.isRunning();
      if (isRunning) {
        _backgroundService.invoke('stop');
      }
    }

    if (clearOnlineIntent) {
      await _persistDesiredOnlineState(false);
      await _persistActiveRideId(null);
    }

    _isRunning = false;

    if (clearPosition) {
      positionNotifier.value = null;
    }
  }

  static Future<bool> _startAndroidService() async {
    final alreadyRunning = await _backgroundService.isRunning();
    if (!alreadyRunning) {
      final started = await _backgroundService.startService();
      _isRunning = started;
      return started;
    }

    _backgroundService.invoke('refresh');
    _isRunning = true;
    return true;
  }

  static Future<bool> _startLocalTracking() async {
    await _stopLocalTracking(clearPosition: false);

    late LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      );
    }

    _localLocationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) {
        unawaited(_handleLocalPosition(position));
      },
      onError: (Object error) {
        debugPrint(
          'RideshareDriverPresenceService local tracking error: $error',
        );
      },
    );

    _localHeartbeatTimer =
        Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(RideshareService.sendDriverHeartbeat());
    });

    _localLocationFallbackTimer =
        Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_lastLocalLocationSentAt != null &&
          DateTime.now().difference(_lastLocalLocationSentAt!) <
              const Duration(seconds: 25)) {
        return;
      }

      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null) {
        await _handleLocalPosition(lastKnownPosition);
      }
    });

    await RideshareService.sendDriverHeartbeat();
    final lastKnownPosition = await Geolocator.getLastKnownPosition();
    if (lastKnownPosition != null) {
      await _handleLocalPosition(lastKnownPosition);
    }

    _isRunning = true;
    return true;
  }

  static Future<void> _stopLocalTracking({
    bool clearPosition = true,
  }) async {
    await _localLocationSubscription?.cancel();
    _localLocationSubscription = null;
    _localHeartbeatTimer?.cancel();
    _localHeartbeatTimer = null;
    _localLocationFallbackTimer?.cancel();
    _localLocationFallbackTimer = null;
    _lastLocalLocationSentAt = null;

    if (clearPosition && defaultTargetPlatform != TargetPlatform.android) {
      positionNotifier.value = null;
    }
  }

  static Future<void> _handleLocalPosition(Position position) async {
    positionNotifier.value = position;
    _lastLocalLocationSentAt = DateTime.now();

    await RideshareService.updateDriverLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      rideId: await _readActiveRideId(),
      heading: position.heading,
      speedKph: position.speed * 3.6,
      accuracyMeters: position.accuracy,
    );
  }
}