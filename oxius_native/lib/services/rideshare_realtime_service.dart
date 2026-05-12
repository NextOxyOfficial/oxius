import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_service.dart';
import 'telemetry.dart';

class RideshareRealtimeService {
  static const String _tokenKey = 'adsyclub_token';
  static const Duration _initialReconnectDelay = Duration(seconds: 2);
  static const Duration _maxReconnectDelay = Duration(seconds: 60);
  static const Duration _pingInterval = Duration(seconds: 20);
  static const Duration _inboundStaleTimeout = Duration(seconds: 60);
  // If a socket opens and closes within this window, treat as "immediate
  // failure" \u2014 typically caused by auth rejection or server-side reject.
  static const Duration _immediateFailureThreshold = Duration(seconds: 4);
  // After this many immediate failures in a row we stop hammering and
  // broadcast an authFailure so the UI can decide what to do (re-login,
  // show error, etc.). The user can manually retry.
  static const int _maxImmediateFailures = 5;

  final StreamController<Map<String, dynamic>> _rideEventsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _dispatchEventsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _authFailureController =
      StreamController<String>.broadcast();

  WebSocketChannel? _rideChannel;
  WebSocketChannel? _dispatchChannel;
  Timer? _rideReconnectTimer;
  Timer? _dispatchReconnectTimer;
  Timer? _ridePingTimer;
  Timer? _dispatchPingTimer;

  String? _activeRideId;
  bool _shouldKeepRideConnection = false;
  bool _shouldKeepDispatchConnection = false;

  // Exponential backoff bookkeeping.
  int _rideReconnectAttempts = 0;
  int _dispatchReconnectAttempts = 0;
  int _rideImmediateFailures = 0;
  int _dispatchImmediateFailures = 0;
  DateTime? _rideConnectedAt;
  DateTime? _dispatchConnectedAt;
  DateTime? _rideLastInboundAt;
  DateTime? _dispatchLastInboundAt;
  bool _rideAuthSuspended = false;
  bool _dispatchAuthSuspended = false;

  // Connectivity awareness \u2014 force immediate reconnect when the network
  // returns instead of waiting for the next backoff tick.
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySub;
  bool _isOffline = false;

  // Small LRU of recent message fingerprints to suppress duplicates that
  // arrive when the same event is delivered twice (e.g. dispatch socket +
  // ride socket, or a reconnect replay). Bounded to avoid memory growth.
  static const int _dedupWindow = 32;
  final List<String> _recentRideFingerprints = <String>[];
  final List<String> _recentDispatchFingerprints = <String>[];

  RideshareRealtimeService() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  Stream<Map<String, dynamic>> get rideEvents => _rideEventsController.stream;
  Stream<Map<String, dynamic>> get dispatchEvents =>
      _dispatchEventsController.stream;
  Stream<String> get authFailure => _authFailureController.stream;

  /// Send a JSON message over the active ride WebSocket channel.
  void sendToRide(Map<String, dynamic> message) {
    if (_rideChannel != null) {
      _rideChannel!.sink.add(jsonEncode(message));
    }
  }

  Future<void> connectRide(String rideId) async {
    if (_rideChannel != null &&
        _shouldKeepRideConnection &&
        _activeRideId == rideId) {
      return;
    }
    _activeRideId = rideId;
    _shouldKeepRideConnection = true;
    // New connect attempt \u2014 user explicitly opted in, clear any prior
    // suspension/backoff so we try immediately.
    _rideAuthSuspended = false;
    _rideReconnectAttempts = 0;
    _rideImmediateFailures = 0;
    await _openRideSocket();
  }

  Future<void> disconnectRide() async {
    _shouldKeepRideConnection = false;
    _activeRideId = null;
    _rideReconnectTimer?.cancel();
    _ridePingTimer?.cancel();
    _rideReconnectTimer = null;
    _ridePingTimer = null;
    _rideReconnectAttempts = 0;
    _rideImmediateFailures = 0;
    _rideAuthSuspended = false;
    _rideConnectedAt = null;
    _rideLastInboundAt = null;
    await _rideChannel?.sink.close();
    _rideChannel = null;
  }

  Future<void> connectDriverDispatch() async {
    if (_dispatchChannel != null && _shouldKeepDispatchConnection) {
      return;
    }
    _shouldKeepDispatchConnection = true;
    _dispatchAuthSuspended = false;
    _dispatchReconnectAttempts = 0;
    _dispatchImmediateFailures = 0;
    await _openDispatchSocket();
  }

  Future<void> disconnectDriverDispatch() async {
    _shouldKeepDispatchConnection = false;
    _dispatchReconnectTimer?.cancel();
    _dispatchPingTimer?.cancel();
    _dispatchReconnectTimer = null;
    _dispatchPingTimer = null;
    _dispatchReconnectAttempts = 0;
    _dispatchImmediateFailures = 0;
    _dispatchAuthSuspended = false;
    _dispatchConnectedAt = null;
    _dispatchLastInboundAt = null;
    await _dispatchChannel?.sink.close();
    _dispatchChannel = null;
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    await disconnectRide();
    await disconnectDriverDispatch();
    await _rideEventsController.close();
    await _dispatchEventsController.close();
    await _authFailureController.close();
  }

  Future<void> _onConnectivityChanged(ConnectivityResult result) async {
    final wasOffline = _isOffline;
    _isOffline = result == ConnectivityResult.none;

    if (_isOffline) {
      // Don't churn reconnect timers while we know we have no network.
      _rideReconnectTimer?.cancel();
      _dispatchReconnectTimer?.cancel();
      return;
    }

    // Network just came back \u2014 reset backoff and reconnect now so the user
    // doesn't sit on stale UI waiting for the next exponential tick.
    if (wasOffline) {
      if (_shouldKeepRideConnection && _activeRideId != null) {
        _rideReconnectAttempts = 0;
        _rideImmediateFailures = 0;
        _rideAuthSuspended = false;
        unawaited(_openRideSocket());
      }
      if (_shouldKeepDispatchConnection) {
        _dispatchReconnectAttempts = 0;
        _dispatchImmediateFailures = 0;
        _dispatchAuthSuspended = false;
        unawaited(_openDispatchSocket());
      }
    }
  }

  Future<void> _openRideSocket() async {
    final rideId = _activeRideId;
    if (!_shouldKeepRideConnection || rideId == null || rideId.isEmpty) {
      return;
    }
    if (_rideAuthSuspended || _isOffline) {
      return;
    }

    _rideReconnectTimer?.cancel();
    _ridePingTimer?.cancel();
    _rideReconnectTimer = null;
    _ridePingTimer = null;
    final previousChannel = _rideChannel;
    _rideChannel = null;
    await previousChannel?.sink.close();

    try {
      final channel = WebSocketChannel.connect(await _buildRideUri(rideId));
      _rideChannel = channel;
      _rideConnectedAt = DateTime.now();
      _rideLastInboundAt = _rideConnectedAt;
      Telemetry.event('ws.connected', tags: {
        'socket': 'ride',
        'ride_id': rideId,
        'attempt': _rideReconnectAttempts,
      });
      _ridePingTimer = Timer.periodic(_pingInterval, (_) {
        _checkRideSocketHealth();
      });
      channel.stream.listen(
        (message) {
          _rideLastInboundAt = DateTime.now();
          // First successful frame proves the socket is healthy \u2014 reset
          // attempt counters so transient hiccups don't poison backoff.
          if (_rideReconnectAttempts != 0 || _rideImmediateFailures != 0) {
            _rideReconnectAttempts = 0;
            _rideImmediateFailures = 0;
          }
          _handleSocketMessage(message, _rideEventsController);
        },
        onError: (_) => _scheduleRideReconnect(expectedChannel: channel),
        onDone: () => _scheduleRideReconnect(expectedChannel: channel),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleRideReconnect();
    }
  }

  Future<void> _openDispatchSocket() async {
    if (!_shouldKeepDispatchConnection) {
      return;
    }
    if (_dispatchAuthSuspended || _isOffline) {
      return;
    }

    _dispatchReconnectTimer?.cancel();
    _dispatchPingTimer?.cancel();
    _dispatchReconnectTimer = null;
    _dispatchPingTimer = null;
    final previousChannel = _dispatchChannel;
    _dispatchChannel = null;
    await previousChannel?.sink.close();

    try {
      final channel = WebSocketChannel.connect(await _buildDispatchUri());
      _dispatchChannel = channel;
      _dispatchConnectedAt = DateTime.now();
      _dispatchLastInboundAt = _dispatchConnectedAt;
      Telemetry.event('ws.connected', tags: {
        'socket': 'dispatch',
        'attempt': _dispatchReconnectAttempts,
      });
      _dispatchPingTimer = Timer.periodic(_pingInterval, (_) {
        _checkDispatchSocketHealth();
      });
      channel.stream.listen(
        (message) {
          _dispatchLastInboundAt = DateTime.now();
          if (_dispatchReconnectAttempts != 0 ||
              _dispatchImmediateFailures != 0) {
            _dispatchReconnectAttempts = 0;
            _dispatchImmediateFailures = 0;
          }
          _handleSocketMessage(message, _dispatchEventsController);
        },
        onError: (_) => _scheduleDispatchReconnect(expectedChannel: channel),
        onDone: () => _scheduleDispatchReconnect(expectedChannel: channel),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleDispatchReconnect();
    }
  }

  void _handleSocketMessage(
    dynamic message,
    StreamController<Map<String, dynamic>> controller,
  ) {
    if (message is! String) {
      return;
    }

    try {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, dynamic>) {
        // Build a fingerprint from stable identifying fields when available,
        // otherwise fall back to the full payload. This is intentionally
        // conservative so server-driven "refresh" events still pass through.
        final eventId = decoded['event_id'] ?? decoded['id'];
        final fingerprint = eventId != null
            ? 'id:$eventId'
            : '${decoded['event'] ?? decoded['type'] ?? ''}|'
                '${decoded['ride_id'] ?? ''}|'
                '${decoded['status'] ?? ''}|'
                '${decoded['timestamp'] ?? decoded['updated_at'] ?? ''}';

        final ring = identical(controller, _rideEventsController)
            ? _recentRideFingerprints
            : _recentDispatchFingerprints;

        if (fingerprint.isNotEmpty && ring.contains(fingerprint)) {
          return; // drop duplicate
        }
        if (fingerprint.isNotEmpty) {
          ring.add(fingerprint);
          if (ring.length > _dedupWindow) {
            ring.removeAt(0);
          }
        }

        controller.add(decoded);
      }
    } catch (_) {
      // Ignore malformed frames and keep the socket alive.
    }
  }

  void _checkRideSocketHealth() {
    final channel = _rideChannel;
    if (channel == null) {
      return;
    }

    final lastInboundAt = _rideLastInboundAt;
    if (lastInboundAt != null) {
      final silence = DateTime.now().difference(lastInboundAt);
      if (silence > _inboundStaleTimeout) {
        Telemetry.event('ws.stale_socket',
            tags: {
              'socket': 'ride',
              if (_activeRideId != null) 'ride_id': _activeRideId,
              'silence_ms': silence.inMilliseconds,
              'threshold_ms': _inboundStaleTimeout.inMilliseconds,
            },
            severity: TelemetrySeverity.warning);
        _scheduleRideReconnect(expectedChannel: channel);
        unawaited(channel.sink.close());
        return;
      }
    }

    try {
      channel.sink.add(jsonEncode({'event': 'ping'}));
    } catch (_) {
      _scheduleRideReconnect(expectedChannel: channel);
    }
  }

  void _checkDispatchSocketHealth() {
    final channel = _dispatchChannel;
    if (channel == null) {
      return;
    }

    final lastInboundAt = _dispatchLastInboundAt;
    if (lastInboundAt != null) {
      final silence = DateTime.now().difference(lastInboundAt);
      if (silence > _inboundStaleTimeout) {
        Telemetry.event('ws.stale_socket',
            tags: {
              'socket': 'dispatch',
              'silence_ms': silence.inMilliseconds,
              'threshold_ms': _inboundStaleTimeout.inMilliseconds,
            },
            severity: TelemetrySeverity.warning);
        _scheduleDispatchReconnect(expectedChannel: channel);
        unawaited(channel.sink.close());
        return;
      }
    }

    try {
      channel.sink.add(jsonEncode({'event': 'ping'}));
    } catch (_) {
      _scheduleDispatchReconnect(expectedChannel: channel);
    }
  }

  void _scheduleRideReconnect({WebSocketChannel? expectedChannel}) {
    if (expectedChannel != null && !identical(_rideChannel, expectedChannel)) {
      return;
    }
    if (_rideReconnectTimer?.isActive ?? false) {
      return;
    }
    final wasOpenedAt = _rideConnectedAt;
    _rideChannel = null;
    _rideConnectedAt = null;
    _rideLastInboundAt = null;
    _ridePingTimer?.cancel();
    _ridePingTimer = null;
    if (!_shouldKeepRideConnection || _activeRideId == null) {
      return;
    }
    if (_rideAuthSuspended) {
      return;
    }

    // Detect immediate-failure pattern: socket opened then closed within a
    // few seconds without producing useful traffic. Repeated immediate
    // failures almost always mean the auth token in the WS query string is
    // bad (expired/revoked) and continuing to reconnect just wastes battery
    // and server resources.
    if (wasOpenedAt != null &&
        DateTime.now().difference(wasOpenedAt) < _immediateFailureThreshold) {
      _rideImmediateFailures += 1;
    } else {
      _rideImmediateFailures = 0;
    }

    if (_rideImmediateFailures >= _maxImmediateFailures) {
      _rideAuthSuspended = true;
      Telemetry.event('ws.auth_suspended',
          tags: {
            'socket': 'ride',
            'immediate_failures': _rideImmediateFailures,
          },
          severity: TelemetrySeverity.error);
      if (!_authFailureController.isClosed) {
        _authFailureController.add('ride_socket_auth_failed');
      }
      return;
    }

    _rideReconnectAttempts += 1;
    final delay = _computeBackoff(_rideReconnectAttempts);
    Telemetry.event('ws.reconnect_scheduled', tags: {
      'socket': 'ride',
      'attempt': _rideReconnectAttempts,
      'backoff_ms': delay.inMilliseconds,
      'immediate_failures': _rideImmediateFailures,
    });

    _rideReconnectTimer?.cancel();
    _rideReconnectTimer = Timer(delay, _openRideSocket);
  }

  void _scheduleDispatchReconnect({WebSocketChannel? expectedChannel}) {
    if (expectedChannel != null &&
        !identical(_dispatchChannel, expectedChannel)) {
      return;
    }
    if (_dispatchReconnectTimer?.isActive ?? false) {
      return;
    }
    final wasOpenedAt = _dispatchConnectedAt;
    _dispatchChannel = null;
    _dispatchConnectedAt = null;
    _dispatchLastInboundAt = null;
    _dispatchPingTimer?.cancel();
    _dispatchPingTimer = null;
    if (!_shouldKeepDispatchConnection) {
      return;
    }
    if (_dispatchAuthSuspended) {
      return;
    }

    if (wasOpenedAt != null &&
        DateTime.now().difference(wasOpenedAt) < _immediateFailureThreshold) {
      _dispatchImmediateFailures += 1;
    } else {
      _dispatchImmediateFailures = 0;
    }

    if (_dispatchImmediateFailures >= _maxImmediateFailures) {
      _dispatchAuthSuspended = true;
      Telemetry.event('ws.auth_suspended',
          tags: {
            'socket': 'dispatch',
            'immediate_failures': _dispatchImmediateFailures,
          },
          severity: TelemetrySeverity.error);
      if (!_authFailureController.isClosed) {
        _authFailureController.add('dispatch_socket_auth_failed');
      }
      return;
    }

    _dispatchReconnectAttempts += 1;
    final delay = _computeBackoff(_dispatchReconnectAttempts);
    Telemetry.event('ws.reconnect_scheduled', tags: {
      'socket': 'dispatch',
      'attempt': _dispatchReconnectAttempts,
      'backoff_ms': delay.inMilliseconds,
      'immediate_failures': _dispatchImmediateFailures,
    });

    _dispatchReconnectTimer?.cancel();
    _dispatchReconnectTimer = Timer(delay, _openDispatchSocket);
  }

  /// Exponential backoff with jitter, capped at [_maxReconnectDelay].
  Duration _computeBackoff(int attempt) {
    final exp = math.min(attempt - 1, 6); // cap exponent so we don't overflow
    final base = _initialReconnectDelay.inMilliseconds * (1 << exp);
    final capped = math.min(base, _maxReconnectDelay.inMilliseconds);
    // \u00b125% jitter to avoid thundering-herd reconnect after a server blip.
    final jitter =
        (capped * 0.25 * (math.Random().nextDouble() * 2 - 1)).toInt();
    return Duration(milliseconds: math.max(500, capped + jitter));
  }

  /// Manually retry after an authFailure was broadcast. Callers (e.g. after
  /// the user re-logs in or pulls to refresh) can invoke this to break out
  /// of the suspended state.
  Future<void> retryAfterAuthFailure() async {
    _rideAuthSuspended = false;
    _dispatchAuthSuspended = false;
    _rideReconnectAttempts = 0;
    _dispatchReconnectAttempts = 0;
    _rideImmediateFailures = 0;
    _dispatchImmediateFailures = 0;
    if (_shouldKeepRideConnection && _activeRideId != null) {
      await _openRideSocket();
    }
    if (_shouldKeepDispatchConnection) {
      await _openDispatchSocket();
    }
  }

  Future<Uri> _buildRideUri(String rideId) async {
    final token = await _loadToken();
    return _buildWebSocketUri('/ws/rides/$rideId/', token: token);
  }

  Future<Uri> _buildDispatchUri() async {
    final token = await _loadToken();
    return _buildWebSocketUri('/ws/rides/driver/dispatch/', token: token);
  }

  Uri _buildWebSocketUri(String path, {String? token}) {
    final apiUri = Uri.parse(ApiService.baseUrl);
    final scheme = apiUri.scheme == 'https' ? 'wss' : 'ws';
    return Uri(
      scheme: scheme,
      host: apiUri.host,
      port: apiUri.hasPort ? apiUri.port : null,
      path: path,
      queryParameters:
          token != null && token.isNotEmpty ? {'token': token} : null,
    );
  }

  Future<String?> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }
}
