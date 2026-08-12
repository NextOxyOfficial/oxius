import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'realtime_event_fingerprint.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_service.dart';
import 'auth_service.dart';
import 'telemetry.dart';

class AdsyConnectRealtimeService {
  AdsyConnectRealtimeService._();

  static final AdsyConnectRealtimeService instance =
      AdsyConnectRealtimeService._();

  static const String _tokenKey = 'adsyclub_token';
  static const Duration _initialReconnectDelay = Duration(seconds: 2);
  static const Duration _maxReconnectDelay = Duration(seconds: 60);
  static const Duration _pingInterval = Duration(seconds: 20);
  static const Duration _inboundStaleTimeout = Duration(seconds: 60);
  // Bounded LRU of recent event fingerprints to suppress duplicates that
  // arrive via socket replay after reconnect or simultaneously via the FCM
  // fallback path. Bounded to avoid memory growth on long sessions.
  static const int _dedupWindow = 64;

  final StreamController<Map<String, dynamic>> _eventsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final List<String> _recentFingerprints = <String>[];
  final Connectivity _connectivity = Connectivity();

  WebSocketChannel? _channel;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  Timer? _handshakeTimer;
  String? _connectedUserId;
  bool _shouldStayConnected = false;
  bool _isOffline = false;
  int _reconnectAttempts = 0;
  DateTime? _lastInboundAt;
  final math.Random _jitter = math.Random();

  Stream<Map<String, dynamic>> get events => _eventsController.stream;
  /// True only once the server has actually sent us something.
  ///
  /// This used to be `_channel != null`, which is true the instant the socket
  /// object is constructed — before the handshake, before auth, and while a
  /// dead connection sits there. Every screen throttles its safety poll when
  /// this says "connected", so a socket that looked up but delivered nothing
  /// silently downgraded the whole app to a 24-second poll. That is what made
  /// reactions and read receipts feel like they needed a reload.
  bool get isConnected => _channel != null && _handshakeOk;

  /// Flipped by the first inbound frame; cleared whenever we reconnect.
  bool _handshakeOk = false;

  /// Force the socket to reconnect now (e.g. after AppLifecycleState.resumed).
  /// Safe to call even if already connected — will only reopen if the user is
  /// still authenticated and the channel is actually stale/closed.
  Future<void> forceReconnect() async {
    if (!_shouldStayConnected || _connectedUserId == null) {
      return;
    }
    if (_isOffline) {
      return;
    }
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _openSocket();
  }

  Future<void> connect() async {
    final userId = AuthService.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      await disconnect();
      return;
    }

    if (_channel != null &&
        _shouldStayConnected &&
        _connectedUserId == userId) {
      return;
    }

    _shouldStayConnected = true;
    _connectedUserId = userId;
    _ensureConnectivityListener();
    await _openSocket();
  }

  Future<void> disconnect() async {
    _shouldStayConnected = false;
    _connectedUserId = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _handshakeTimer?.cancel();
    _handshakeTimer = null;
    _handshakeOk = false;
    _reconnectAttempts = 0;
    _lastInboundAt = null;
    _recentFingerprints.clear();
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    _isOffline = false;
    await _channel?.sink.close();
    _channel = null;
  }

  void _ensureConnectivityListener() {
    if (_connectivitySub != null) {
      return;
    }

    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
    unawaited(_connectivity.checkConnectivity().then(_onConnectivityChanged));
  }

  // connectivity_plus 6 reports a LIST of active transports (a phone can be
  // on wifi and mobile at once). Offline means every one of them is none.
  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final wasOffline = _isOffline;
    _isOffline = results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);

    if (_isOffline) {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      return;
    }

    if (wasOffline && _shouldStayConnected && _connectedUserId != null) {
      await forceReconnect();
    }
  }

  void sendTypingStatus({
    required String chatroomId,
    required bool isTyping,
  }) {
    _send(
      {
        'type': 'typing_status',
        'chatroom_id': chatroomId,
        'is_typing': isTyping,
      },
    );
  }

  Future<void> _openSocket() async {
    final userId = _connectedUserId;
    if (!_shouldStayConnected || userId == null || userId.isEmpty) {
      return;
    }
    if (_isOffline) {
      return;
    }

    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _handshakeTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer = null;
    _handshakeTimer = null;
    final previousChannel = _channel;
    _channel = null;
    await previousChannel?.sink.close();

    // Clear the dedup ring on every fresh socket — backend may replay events
    // we already saw on the previous channel, but the UI state may also have
    // missed updates that we want to re-apply on reconnect.
    _recentFingerprints.clear();

    try {
      final channel = WebSocketChannel.connect(await _buildUri(userId));
      _channel = channel;
      _handshakeOk = false;
      _lastInboundAt = DateTime.now();
      // A socket that accepted but never speaks is worse than no socket: every
      // screen backs its safety poll off believing it is live. So we make the
      // server prove it. The consumer greets us with `connection_ready`, and we
      // also fire our own ping below in case an older backend is deployed —
      // either reply flips _handshakeOk.
      //
      // The window has to clear a real round-trip on a bad mobile connection,
      // and it must be cancellable: a tab-out or logout closes the socket, and
      // a surviving timer would resurrect it.
      _handshakeTimer?.cancel();
      _handshakeTimer = Timer(const Duration(seconds: 12), () {
        if (identical(_channel, channel) && !_handshakeOk) {
          _scheduleReconnect(expectedChannel: channel);
        }
      });
      _pingTimer = Timer.periodic(_pingInterval, (_) {
        _checkSocketHealth();
      });
      channel.stream.listen(
        (message) {
          _lastInboundAt = DateTime.now();
          _handshakeOk = true;
          // First successful frame — reset backoff so transient hiccups don't
          // poison the next reconnect cycle.
          if (_reconnectAttempts != 0) {
            _reconnectAttempts = 0;
          }
          _handleMessage(message);
        },
        onDone: () => _scheduleReconnect(expectedChannel: channel),
        onError: (_) => _scheduleReconnect(expectedChannel: channel),
        cancelOnError: true,
      );

      // Prove the socket now instead of waiting 20s for the first periodic
      // health tick. Sent after listen() so the pong can't land unheard.
      _send({'type': 'ping'});
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    if (message is! String) {
      return;
    }

    try {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, dynamic>) {
        // Dedup by stable identifier when the server provides one. Falls back
        // to a composite fingerprint so legacy events without event_id still
        // get a basic duplicate filter without blocking legitimate updates.
        final fingerprint = _eventFingerprint(decoded);

        if (fingerprint.isNotEmpty && fingerprint != 'id:null') {
          if (_recentFingerprints.contains(fingerprint)) {
            return; // duplicate — drop silently
          }
          _recentFingerprints.add(fingerprint);
          if (_recentFingerprints.length > _dedupWindow) {
            _recentFingerprints.removeAt(0);
          }
        }

        _eventsController.add(decoded);
      }
    } catch (_) {
      // Ignore malformed frames and keep the socket alive.
    }
  }

  /// Delegates to the pure function in realtime_event_fingerprint.dart.
  ///
  /// It was inline and private here, which made it untestable — and it was
  /// wrong: every bn_notification collapsed to one constant fingerprint, so
  /// the user received exactly one live notification per socket.
  String _eventFingerprint(Map<String, dynamic> event) =>
      eventFingerprint(event);

  void _send(Map<String, dynamic> payload) {
    final channel = _channel;
    if (channel == null) {
      return;
    }
    try {
      channel.sink.add(jsonEncode(payload));
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _checkSocketHealth() {
    final channel = _channel;
    if (channel == null) {
      return;
    }

    final lastInboundAt = _lastInboundAt;
    if (lastInboundAt != null) {
      final silence = DateTime.now().difference(lastInboundAt);
      if (silence > _inboundStaleTimeout) {
        Telemetry.event('ws.stale_socket',
            tags: {
              'socket': 'adsyconnect',
              if (_connectedUserId != null) 'user_id': _connectedUserId,
              'silence_ms': silence.inMilliseconds,
              'threshold_ms': _inboundStaleTimeout.inMilliseconds,
            },
            severity: TelemetrySeverity.warning);
        _scheduleReconnect(expectedChannel: channel);
        unawaited(channel.sink.close());
        return;
      }
    }

    _send({'type': 'ping'});
  }

  void _scheduleReconnect({WebSocketChannel? expectedChannel}) {
    // The identity guard comes FIRST. A superseded channel's late onDone must
    // not clear the handshake flag of the live one that replaced it — that
    // would report a healthy socket as dead and drop every screen back to
    // polling until the next inbound frame.
    if (expectedChannel != null && !identical(_channel, expectedChannel)) {
      unawaited(expectedChannel.sink.close());
      return;
    }
    _handshakeOk = false;
    if (_reconnectTimer?.isActive ?? false) {
      return;
    }
    final dying = _channel;
    _channel = null;
    _lastInboundAt = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _handshakeTimer?.cancel();
    _handshakeTimer = null;
    // Abandoning a channel without closing it leaks a live socket server-side:
    // every broadcast keeps fanning out to it and its listener keeps pushing
    // into our stream controller until nginx reaps it.
    if (dying != null) {
      unawaited(dying.sink.close());
    }

    if (!_shouldStayConnected || _connectedUserId == null || _isOffline) {
      return;
    }

    _reconnectTimer?.cancel();
    // Exponential backoff with jitter, capped at _maxReconnectDelay.
    // Prevents thundering-herd reconnect storms during backend outages while
    // still recovering quickly from transient drops.
    final attempt = _reconnectAttempts.clamp(0, 10);
    final baseMs =
        (_initialReconnectDelay.inMilliseconds * math.pow(1.5, attempt))
            .toInt()
            .clamp(_initialReconnectDelay.inMilliseconds,
                _maxReconnectDelay.inMilliseconds);
    final jitterMs = _jitter.nextInt(1000);
    _reconnectAttempts++;
    _reconnectTimer = Timer(Duration(milliseconds: baseMs + jitterMs), () {
      unawaited(connect());
    });
  }

  Future<Uri> _buildUri(String userId) async {
    final token = await _loadToken();
    final apiUri = Uri.parse(ApiService.baseUrl);
    final scheme = apiUri.scheme == 'https' ? 'wss' : 'ws';
    return Uri(
      scheme: scheme,
      host: apiUri.host,
      port: apiUri.hasPort ? apiUri.port : null,
      path: '/ws/chat/$userId/',
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
