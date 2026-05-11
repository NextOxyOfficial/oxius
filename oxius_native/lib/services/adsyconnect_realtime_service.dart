import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_service.dart';
import 'auth_service.dart';

class AdsyConnectRealtimeService {
  AdsyConnectRealtimeService._();

  static final AdsyConnectRealtimeService instance = AdsyConnectRealtimeService._();

  static const String _tokenKey = 'adsyclub_token';
  static const Duration _initialReconnectDelay = Duration(seconds: 2);
  static const Duration _maxReconnectDelay = Duration(seconds: 60);
  static const Duration _pingInterval = Duration(seconds: 20);
  // Bounded LRU of recent event fingerprints to suppress duplicates that
  // arrive via socket replay after reconnect or simultaneously via the FCM
  // fallback path. Bounded to avoid memory growth on long sessions.
  static const int _dedupWindow = 64;

  final StreamController<Map<String, dynamic>> _eventsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final List<String> _recentFingerprints = <String>[];

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  String? _connectedUserId;
  bool _shouldStayConnected = false;
  int _reconnectAttempts = 0;
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

    if (_channel != null && _shouldStayConnected && _connectedUserId == userId) {
      return;
    }

    _shouldStayConnected = true;
    _connectedUserId = userId;
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
    _recentFingerprints.clear();
    await _channel?.sink.close();
    _channel = null;
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

    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    await _channel?.sink.close();

    // Clear the dedup ring on every fresh socket — backend may replay events
    // we already saw on the previous channel, but the UI state may also have
    // missed updates that we want to re-apply on reconnect.
    _recentFingerprints.clear();

    try {
      final channel = WebSocketChannel.connect(await _buildUri(userId));
      _channel = channel;
      _pingTimer = Timer.periodic(_pingInterval, (_) {
        _send({'type': 'ping'});
      });

      channel.stream.listen(
        (message) {
          // First successful frame — reset backoff so transient hiccups don't
          // poison the next reconnect cycle.
          if (_reconnectAttempts != 0) {
            _reconnectAttempts = 0;
          }
          _handleMessage(message);
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
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
        final eventId = decoded['event_id'] ?? decoded['id'] ?? decoded['message_id'];
        final fingerprint = eventId != null
            ? 'id:$eventId'
            : '${decoded['type'] ?? ''}|'
                '${decoded['chatroom_id'] ?? ''}|'
                '${decoded['user_id'] ?? ''}|'
                '${decoded['timestamp'] ?? decoded['created_at'] ?? ''}';

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

  void _scheduleReconnect() {
    _channel = null;
    _pingTimer?.cancel();
    _pingTimer = null;

    if (!_shouldStayConnected || _connectedUserId == null) {
      return;
    }

    _reconnectTimer?.cancel();
    // Exponential backoff with jitter, capped at _maxReconnectDelay.
    // Prevents thundering-herd reconnect storms during backend outages while
    // still recovering quickly from transient drops.
    final attempt = _reconnectAttempts.clamp(0, 10);
    final baseMs = (_initialReconnectDelay.inMilliseconds *
            math.pow(1.5, attempt))
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
      queryParameters: token != null && token.isNotEmpty ? {'token': token} : null,
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