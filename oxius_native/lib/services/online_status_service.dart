import 'dart:async';

import 'adsyconnect_service.dart';
import 'auth_service.dart';

/// Service to manage user's online status via periodic heartbeats
class OnlineStatusService {
  static Timer? _heartbeatTimer;
  static bool _isRunning = false;
  
  /// Start sending periodic heartbeats to keep user online
  static void start() {
    if (_isRunning) return;
    if (!AuthService.isAuthenticated) return;
    
    _isRunning = true;
    print('💚 OnlineStatusService started');

    unawaited(AdsyConnectService.updateOnlineStatus(true));
    
    // Send initial heartbeat
    _sendHeartbeat();
    
    // Send heartbeat every 30 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendHeartbeat();
    });
  }
  
  /// Stop sending heartbeats
  static void stop() {
    final shouldNotifyOffline = AuthService.isAuthenticated;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _isRunning = false;

    if (shouldNotifyOffline) {
      unawaited(AdsyConnectService.updateOnlineStatus(false));
    }

    print('💔 OnlineStatusService stopped');
  }
  
  /// Send a single heartbeat
  static Future<void> _sendHeartbeat() async {
    if (!AuthService.isAuthenticated) {
      stop();
      return;
    }
    
    try {
      await AdsyConnectService.sendHeartbeat();
    } catch (e) {
      print('Error sending heartbeat: $e');
    }
  }
  
  /// Check if service is running
  static bool get isRunning => _isRunning;
}
