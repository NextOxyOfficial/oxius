import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_service.dart';
import 'auth_service.dart';

class AdsyConnectRealtimeService {
  AdsyConnectRealtimeService._();

  static final AdsyConnectRealtimeService instance = AdsyConnectRealtimeService._();

  static const String _tokenKey = 'adsyclub_token';
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _pingInterval = Duration(seconds: 20);

  final StreamController<Map<String, dynamic>> _eventsController =
      StreamController<Map<String, dynamic>>.broadcast();

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  String? _connectedUserId;
  bool _shouldStayConnected = false;

  Stream<Map<String, dynamic>> get events => _eventsController.stream;
  bool get isConnected => _channel != null;

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

    try {
      final channel = WebSocketChannel.connect(await _buildUri(userId));
      _channel = channel;
      _pingTimer = Timer.periodic(_pingInterval, (_) {
        _send({'type': 'ping'});
      });

      channel.stream.listen(
        _handleMessage,
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
    _reconnectTimer = Timer(_reconnectDelay, () {
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