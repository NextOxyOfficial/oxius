import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_service.dart';

class RideshareRealtimeService {
  static const String _tokenKey = 'adsyclub_token';
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _pingInterval = Duration(seconds: 20);

  final StreamController<Map<String, dynamic>> _rideEventsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _dispatchEventsController =
      StreamController<Map<String, dynamic>>.broadcast();

  WebSocketChannel? _rideChannel;
  WebSocketChannel? _dispatchChannel;
  Timer? _rideReconnectTimer;
  Timer? _dispatchReconnectTimer;
  Timer? _ridePingTimer;
  Timer? _dispatchPingTimer;

  String? _activeRideId;
  bool _shouldKeepRideConnection = false;
  bool _shouldKeepDispatchConnection = false;

  Stream<Map<String, dynamic>> get rideEvents => _rideEventsController.stream;
  Stream<Map<String, dynamic>> get dispatchEvents => _dispatchEventsController.stream;

  /// Send a JSON message over the active ride WebSocket channel.
  void sendToRide(Map<String, dynamic> message) {
    if (_rideChannel != null) {
      _rideChannel!.sink.add(jsonEncode(message));
    }
  }

  Future<void> connectRide(String rideId) async {
    _activeRideId = rideId;
    _shouldKeepRideConnection = true;
    await _openRideSocket();
  }

  Future<void> disconnectRide() async {
    _shouldKeepRideConnection = false;
    _activeRideId = null;
    _rideReconnectTimer?.cancel();
    _ridePingTimer?.cancel();
    await _rideChannel?.sink.close();
    _rideChannel = null;
  }

  Future<void> connectDriverDispatch() async {
    _shouldKeepDispatchConnection = true;
    await _openDispatchSocket();
  }

  Future<void> disconnectDriverDispatch() async {
    _shouldKeepDispatchConnection = false;
    _dispatchReconnectTimer?.cancel();
    _dispatchPingTimer?.cancel();
    await _dispatchChannel?.sink.close();
    _dispatchChannel = null;
  }

  Future<void> dispose() async {
    await disconnectRide();
    await disconnectDriverDispatch();
    await _rideEventsController.close();
    await _dispatchEventsController.close();
  }

  Future<void> _openRideSocket() async {
    final rideId = _activeRideId;
    if (!_shouldKeepRideConnection || rideId == null || rideId.isEmpty) {
      return;
    }

    _rideReconnectTimer?.cancel();
    _ridePingTimer?.cancel();
    await _rideChannel?.sink.close();

    try {
      final channel = WebSocketChannel.connect(await _buildRideUri(rideId));
      _rideChannel = channel;
      _ridePingTimer = Timer.periodic(_pingInterval, (_) {
        if (_rideChannel != null) {
          _rideChannel!.sink.add(jsonEncode({'event': 'ping'}));
        }
      });
      channel.stream.listen(
        (message) => _handleSocketMessage(message, _rideEventsController),
        onError: (_) => _scheduleRideReconnect(),
        onDone: _scheduleRideReconnect,
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

    _dispatchReconnectTimer?.cancel();
    _dispatchPingTimer?.cancel();
    await _dispatchChannel?.sink.close();

    try {
      final channel = WebSocketChannel.connect(await _buildDispatchUri());
      _dispatchChannel = channel;
      _dispatchPingTimer = Timer.periodic(_pingInterval, (_) {
        if (_dispatchChannel != null) {
          _dispatchChannel!.sink.add(jsonEncode({'event': 'ping'}));
        }
      });
      channel.stream.listen(
        (message) => _handleSocketMessage(message, _dispatchEventsController),
        onError: (_) => _scheduleDispatchReconnect(),
        onDone: _scheduleDispatchReconnect,
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
        controller.add(decoded);
      }
    } catch (_) {
      // Ignore malformed frames and keep the socket alive.
    }
  }

  void _scheduleRideReconnect() {
    _rideChannel = null;
    _ridePingTimer?.cancel();
    if (!_shouldKeepRideConnection || _activeRideId == null) {
      return;
    }

    _rideReconnectTimer?.cancel();
    _rideReconnectTimer = Timer(_reconnectDelay, _openRideSocket);
  }

  void _scheduleDispatchReconnect() {
    _dispatchChannel = null;
    _dispatchPingTimer?.cancel();
    if (!_shouldKeepDispatchConnection) {
      return;
    }

    _dispatchReconnectTimer?.cancel();
    _dispatchReconnectTimer = Timer(_reconnectDelay, _openDispatchSocket);
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