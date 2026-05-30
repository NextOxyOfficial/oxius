import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

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
  StreamSubscription<ConnectivityResult>? _connectivitySub;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  String? _connectedUserId;
  bool _shouldStayConnected = false;
  bool _isOffline = false;
  int _reconnectAttempts = 0;
  DateTime? _lastInboundAt;
  final math.Random _jitter = math.Random();

  Stream<Map<String, dynamic>> get events => _eventsController.stream;
  bool get isConnected => _channel != null;

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

  Future<void> _onConnectivityChanged(ConnectivityResult result) async {
    final wasOffline = _isOffline;
    _isOffline = result == ConnectivityResult.none;

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
    _reconnectTimer = null;
    _pingTimer = null;
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
      _lastInboundAt = DateTime.now();
      _pingTimer = Timer.periodic(_pingInterval, (_) {
        _checkSocketHealth();
      });

      channel.stream.listen(
        (message) {
          _lastInboundAt = DateTime.now();
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

  String _eventFingerprint(Map<String, dynamic> event) {
    final eventId = event['event_id'] ?? event['id'] ?? event['message_id'];
    if (eventId != null && eventId.toString().isNotEmpty) {
      return 'id:$eventId';
    }

    final type = event['type']?.toString() ?? '';
    if (type == 'incoming_call' || type == 'call_status') {
      return [
        type,
        event['call_id']?.toString() ?? '',
        event['channel_name']?.toString() ?? '',
        event['status']?.toString() ?? '',
        event['caller_id']?.toString() ?? event['sender_id']?.toString() ?? '',
        event['receiver_id']?.toString() ?? '',
        event['timestamp']?.toString() ?? '',
      ].join('|');
    }

    return '$type|'
        '${event['chatroom_id'] ?? ''}|'
        '${event['user_id'] ?? ''}|'
        '${event['timestamp'] ?? event['created_at'] ?? ''}';
  }

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
    if (expectedChannel != null && !identical(_channel, expectedChannel)) {
      return;
    }
    if (_reconnectTimer?.isActive ?? false) {
      return;
    }
    _channel = null;
    _lastInboundAt = null;
    _pingTimer?.cancel();
    _pingTimer = null;

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
