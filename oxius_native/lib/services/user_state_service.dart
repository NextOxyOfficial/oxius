import 'dart:async';

import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'adsyconnect_realtime_service.dart';
import 'fcm_service.dart';
import 'online_status_service.dart';
import 'rideshare_driver_presence_service.dart';

/// Global user state management service
/// Provides reactive updates to user authentication state across the app
/// Similar to Vue's computed isAuthenticated and useState for user
class UserStateService extends ChangeNotifier {
  static final UserStateService _instance = UserStateService._internal();

  factory UserStateService() {
    return _instance;
  }

  UserStateService._internal();

  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isInitializing = true;

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitializing => _isInitializing;

  String get userName => _currentUser?.displayName ?? 'Guest';
  String get userEmail => _currentUser?.email ?? '';
  String get userType => _currentUser?.userType ?? 'regular';
  bool get isSuperuser => _currentUser?.isSuperuser ?? false;

  // Balance getters
  double get balance => _currentUser?.balance ?? 0.0;
  double get userPendingBalance => _currentUser?.pendingBalance ?? 0.0;
  int get userDiamondBalance => _currentUser?.diamondBalance ?? 0;

  // Subscription getter
  bool get isPro => _currentUser?.isPro ?? false;

  /// Initialize user state from AuthService.
  /// Wrapped in try/finally so [isInitializing] always becomes false even if
  /// the network/storage steps throw or are cancelled by an upstream timeout.
  /// This is critical to prevent the iPad "blank screen / endless splash"
  /// App Store rejection cause.
  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    try {
      // Restore session from storage
      await AuthService.initialize();

      // Validate token with server (bounded so a hung backend doesn't freeze
      // the splash forever on networks like Apple's review lab).
      if (AuthService.isAuthenticated) {
        bool isValid = false;
        try {
          isValid = await AuthService.validateToken()
              .timeout(const Duration(seconds: 6));
        } catch (e) {
          // Network/timeout: keep cached session as authenticated optimistically
          // so the app still renders. Token will be re-validated later.
          isValid = AuthService.currentUser != null;
        }
        if (isValid) {
          _currentUser = AuthService.currentUser;
          _isAuthenticated = true;
        } else {
          _currentUser = null;
          _isAuthenticated = false;
        }
      } else {
        _currentUser = null;
        _isAuthenticated = false;
      }
    } catch (e) {
      // Any unexpected error: render the app as logged-out rather than blank.
      _currentUser = null;
      _isAuthenticated = false;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Update user state after successful login
  void updateUser(User user) {
    _currentUser = user;
    _isAuthenticated = true;
    unawaited(FCMService.handleAuthenticationState(true));
    unawaited(AdsyConnectRealtimeService.instance.connect());
    OnlineStatusService.start();
    unawaited(RideshareDriverPresenceService.restoreIfNeeded());
    notifyListeners();
  }

  /// Clear user state on logout
  Future<void> clearUser() async {
    await AdsyConnectRealtimeService.instance.disconnect();
    OnlineStatusService.stop();
    await RideshareDriverPresenceService.stop();
    await FCMService.handleAuthenticationState(false);
    _currentUser = null;
    _isAuthenticated = false;
    await AuthService.clearAuthData();
    notifyListeners();
  }

  /// Refresh user data from server
  Future<bool> refreshUserData() async {
    if (!_isAuthenticated) {
      await AuthService.initialize();
      if (AuthService.currentUser == null || !AuthService.isAuthenticated) {
        return false;
      }
      _currentUser = AuthService.currentUser;
      _isAuthenticated = true;
      notifyListeners();
    }

    try {
      final refreshed = await AuthService.refreshUserData();
      if (AuthService.currentUser != null) {
        _currentUser = AuthService.currentUser;
        notifyListeners();
        return refreshed;
      }
      final isValid = await AuthService.validateToken();
      if (!isValid) {
        await clearUser();
        return false;
      }
      _currentUser = AuthService.currentUser;
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      return false;
    }
  }

  /// Alias for refreshUserData - matches Vue composable naming
  Future<bool> refreshUser() async {
    return await refreshUserData();
  }

  /// Check if user has specific permissions
  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    if (_currentUser!.isSuperuser) return true;

    // Add custom permission logic here based on user type
    switch (permission) {
      case 'admin':
        return _currentUser!.isSuperuser;
      case 'post':
        return _isAuthenticated;
      case 'comment':
        return _isAuthenticated;
      default:
        return false;
    }
  }
}
