import 'package:flutter/foundation.dart';
import 'auth_service.dart';

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

  /// Initialize user state from AuthService
  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    // Restore session from storage
    await AuthService.initialize();
    
    // Validate token with server
    if (AuthService.isAuthenticated) {
      final isValid = await AuthService.validateToken();
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

    _isInitializing = false;
    notifyListeners();
  }

  /// Update user state after successful login
  void updateUser(User user) {
    _currentUser = user;
    _isAuthenticated = true;
    notifyListeners();
  }

  /// Clear user state on logout
  Future<void> clearUser() async {
    _currentUser = null;
    _isAuthenticated = false;
    await AuthService.clearAuthData();
    notifyListeners();
  }

  /// Refresh user data from server
  Future<bool> refreshUserData() async {
    if (!_isAuthenticated) return false;

    try {
      final isValid = await AuthService.validateToken();
      if (isValid) {
        _currentUser = AuthService.currentUser;
        notifyListeners();
        return true;
      } else {
        await clearUser();
        return false;
      }
    } catch (e) {
      print('Failed to refresh user data: $e');
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
