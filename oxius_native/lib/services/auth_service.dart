import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'adsyconnect_realtime_service.dart';
import 'online_status_service.dart';
import 'rideshare_driver_presence_service.dart';
import 'social_auth_service.dart';
import 'fcm_service.dart';
import '../screens/suspended_account_screen.dart';
import 'package:flutter/foundation.dart';

class User {
  final String id; // Changed from int to String to handle UUID
  final String email;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? profession;
  final String userType;
  final bool isSuperuser;
  final bool isActive;
  final String? profilePicture;
  final String? referralCode;
  final int? referCount;
  final double? commissionEarned;
  final double balance;
  final double pendingBalance;
  final int diamondBalance;
  final bool isPro;
  final bool isVerified;
  final String? address;
  final String? phone;
  final String? city;
  final String? zip;
  final String? storeUsername;
  final String? storeName;
  final int? productLimit;
  final DateTime? proValidity;
  final int profileCompletion;
  final List<Map<String, dynamic>> missingSteps;
  // True when first name, last name, phone and date of birth are all set.
  final bool mandatoryProfileComplete;
  final bool isSuspended;
  final String suspensionReason;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
    this.profession,
    required this.userType,
    required this.isSuperuser,
    required this.isActive,
    this.profilePicture,
    this.referralCode,
    this.referCount,
    this.commissionEarned,
    this.balance = 0.0,
    this.pendingBalance = 0.0,
    this.diamondBalance = 0,
    this.isPro = false,
    this.isVerified = false,
    this.address,
    this.phone,
    this.city,
    this.zip,
    this.storeUsername,
    this.storeName,
    this.productLimit,
    this.proValidity,
    this.profileCompletion = 100,
    this.missingSteps = const [],
    this.mandatoryProfileComplete = true,
    this.isSuspended = false,
    this.suspensionReason = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Construct absolute URL for profile picture
    String? imageUrl;
    if (json['image'] != null && json['image'].toString().isNotEmpty) {
      final imagePath = json['image'].toString();
      // Check if it's already an absolute URL
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        imageUrl = imagePath;
      } else {
        // Construct absolute URL using API base URL
        imageUrl = '${ApiService.baseUrl.replaceAll('/api', '')}$imagePath';
        if (!imagePath.startsWith('/')) {
          imageUrl = '${ApiService.baseUrl.replaceAll('/api', '')}/$imagePath';
        }
      }
    }

    return User(
      id: json['id']?.toString() ??
          '', // Convert to string to handle both int and string IDs
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      profession: json['profession'],
      userType: json['user_type'] ?? 'regular',
      isSuperuser: json['is_superuser'] ?? false,
      isActive: json['is_active'] ?? true,
      profilePicture: imageUrl,
      referralCode: json['referral_code'],
      referCount: json['refer_count'],
      commissionEarned: json['commission_earned'] is String
          ? double.tryParse(json['commission_earned'])
          : (json['commission_earned'] as num?)?.toDouble(),
      balance: json['balance'] is String
          ? double.tryParse(json['balance']) ?? 0.0
          : (json['balance'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: json['pending_balance'] is String
          ? double.tryParse(json['pending_balance']) ?? 0.0
          : (json['pending_balance'] as num?)?.toDouble() ?? 0.0,
      diamondBalance: json['diamond_balance'] is int
          ? json['diamond_balance']
          : int.tryParse(json['diamond_balance']?.toString() ?? '0') ?? 0,
      isPro: json['is_pro'] == true,
      isVerified: json['kyc'] == true || json['is_verified'] == true,
      address: json['address'],
      phone: json['phone'],
      city: json['city'],
      zip: json['zip'],
      storeUsername: json['store_username'],
      storeName: json['store_name'],
      productLimit: json['product_limit'],
      proValidity: json['pro_validity'] != null
          ? DateTime.tryParse(json['pro_validity'].toString())
          : null,
      profileCompletion: json['profile_completion'] is num
          ? (json['profile_completion'] as num).toInt()
          : int.tryParse(json['profile_completion']?.toString() ?? '') ?? 100,
      missingSteps: (json['missing_steps'] is List)
          ? (json['missing_steps'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [],
      isSuspended: json['is_suspended'] == true,
      suspensionReason: (json['suspension_reason'] ?? '').toString(),
      // Default true so older payloads / cached users don't get falsely blocked.
      mandatoryProfileComplete: json['mandatory_profile_complete'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'profession': profession,
      'user_type': userType,
      'is_superuser': isSuperuser,
      'is_active': isActive,
      'image': profilePicture,
      'referral_code': referralCode,
      'refer_count': referCount,
      'commission_earned': commissionEarned,
      'balance': balance,
      'pending_balance': pendingBalance,
      'diamond_balance': diamondBalance,
      'is_pro': isPro,
      'kyc': isVerified,
      'address': address,
      'phone': phone,
      'city': city,
      'zip': zip,
      'store_username': storeUsername,
      'store_name': storeName,
      'product_limit': productLimit,
      'is_suspended': isSuspended,
      'suspension_reason': suspensionReason,
    };
  }

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username;
  }
}

class AuthResponse {
  final User user;
  final String accessToken;
  final String refreshToken;
  final bool loggedIn;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.loggedIn,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user'] ?? {}),
      accessToken:
          json['access'] ?? json['access_token'] ?? json['token'] ?? '',
      refreshToken: json['refresh'] ?? json['refresh_token'] ?? '',
      loggedIn: true,
    );
  }
}

/// Result of a social login/registration attempt.
class SocialAuthOutcome {
  final AuthResponse? auth; // non-null on success
  final bool cancelled; // user dismissed the provider picker
  final bool accountNotFound; // no account for this email (login page confirms)
  final String? idToken; // reuse to create after the user confirms
  final String provider;
  final String? errorMessage; // human-readable failure, if any

  const SocialAuthOutcome({
    this.auth,
    this.cancelled = false,
    this.accountNotFound = false,
    this.idToken,
    required this.provider,
    this.errorMessage,
  });

  bool get isSuccess => auth != null;
}

class AuthService {
  static const String _userKey = 'adsyclub_user';
  static const String _tokenKey = 'adsyclub_token';
  static const String _refreshTokenKey = 'adsyclub_refresh';
  static const String _deviceIdKey = 'adsyclub_device_id';

  // Current user state
  static User? _currentUser;
  static String? _accessToken;
  static String? _refreshToken;

  // Getters
  static User? get currentUser => _currentUser;
  static String? get accessToken => _accessToken;
  static bool get isAuthenticated =>
      _currentUser != null && _accessToken != null;

  // Get token method for compatibility
  static Future<String?> getToken() async {
    return _accessToken;
  }

  /// Show the full-screen suspended lock if the account is suspended. Safe to
  /// call from anywhere — uses the app's global navigator.
  static void lockIfSuspended(User user) {
    if (!user.isSuspended) return;
    final ctx = FCMService.navigatorKey.currentContext;
    if (ctx != null) {
      SuspendedAccountScreen.lock(ctx, reason: user.suspensionReason);
    }
  }

  /// Inspect any API response for the backend's suspension block
  /// (`403 {"code": "account_suspended"}` from AccountSuspendedMiddleware) and,
  /// if present, lock the app behind the suspended screen.
  ///
  /// This is the catch-all for users who get suspended *while already logged
  /// in*: every authenticated service call returns this 403, so routing the
  /// busiest ones (e.g. the home screen's 10s chat-rooms poll) through here
  /// locks the app within seconds — no re-login or restart needed. Returns
  /// true when the response was a suspension block so callers can stop.
  static bool maybeHandleSuspendedResponse(int statusCode, String body) {
    if (statusCode != 403) return false;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['code'] == 'account_suspended') {
        final reason =
            (decoded['reason'] ?? decoded['detail'] ?? '').toString();
        final ctx = FCMService.navigatorKey.currentContext;
        if (ctx != null) {
          SuspendedAccountScreen.lock(ctx, reason: reason);
        }
        return true;
      }
    } catch (_) {
      // A non-JSON 403 (plain "permission denied") is not a suspension.
    }
    return false;
  }

  // Initialize auth service and restore session if available
  static Future<void> initialize() async {
    await _restoreAuthFromStorage();
  }

  // Login function matching the Vue implementation
  static Future<AuthResponse?> login(String email, String password) async {
    try {
      debugPrint('Attempting login with email: $email'); // Debug log
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/login/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('Response status: ${response.statusCode}'); // Debug log
      debugPrint('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(data);

        // Store auth data
        await _persistAuthData(authResponse);

        return authResponse;
      } else {
        // Handle login error
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          throw Exception(
              errorData['error'] ?? errorData['detail'] ?? 'Login failed');
        } catch (jsonError) {
          throw Exception(
              'Login failed with status ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('Login error details: $e'); // Debug log
      throw Exception('Login error: $e');
    }
  }

  /// Social login / registration via Google or Facebook.
  ///
  /// [provider] must be `'google'` or `'facebook'`. Returns `null` if the user
  /// cancels the provider picker. On success the backend find-or-creates the
  /// user and we persist the session just like a normal login.
  /// Roll back the Google/Facebook provider session (e.g. when the user
  /// declines the "create account?" confirmation on the login page).
  static Future<void> socialSignOut() => SocialAuthService.signOut();

  /// Social login / registration.
  ///
  /// [createIfMissing]: the login page passes `false` so the backend will NOT
  /// silently create a brand-new account — instead it returns `accountNotFound`
  /// and the UI asks the user to confirm (with terms acceptance) before calling
  /// again with `createIfMissing: true`. The register page passes `true`.
  ///
  /// [reuseIdToken]: pass the token from a prior `accountNotFound` outcome so the
  /// confirmed create doesn't pop the provider picker a second time.
  static Future<SocialAuthOutcome> socialLogin(
    String provider, {
    bool createIfMissing = true,
    String? reuseIdToken,
    String? referralCode,
  }) async {
    String? idToken = reuseIdToken;
    if (idToken == null) {
      if (provider == 'google') {
        idToken = await SocialAuthService.signInWithGoogle();
      } else if (provider == 'facebook') {
        idToken = await SocialAuthService.signInWithFacebook();
      } else {
        throw Exception('Unsupported provider: $provider');
      }
    }

    if (idToken == null) {
      return SocialAuthOutcome(cancelled: true, provider: provider);
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/social/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'provider': provider,
          'id_token': idToken,
          'create_if_missing': createIfMissing,
          if (referralCode != null && referralCode.trim().isNotEmpty)
            'refer': referralCode.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(data);
        await _persistAuthData(authResponse);
        return SocialAuthOutcome(
            auth: authResponse, provider: provider, idToken: idToken);
      }

      Map<String, dynamic>? data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      // No account for this email yet — let the login page confirm + create.
      if (response.statusCode == 404 && data?['code'] == 'account_not_found') {
        return SocialAuthOutcome(
            accountNotFound: true, provider: provider, idToken: idToken);
      }

      // Any other failure: roll back the provider session, surface a clean msg.
      await SocialAuthService.signOut();
      final msg = (data?['error'] ?? data?['detail'] ?? '').toString().trim();
      return SocialAuthOutcome(
        provider: provider,
        errorMessage:
            msg.isNotEmpty ? msg : 'সাইন ইন করা যায়নি। আবার চেষ্টা করুন।',
      );
    } catch (e) {
      await SocialAuthService.signOut();
      rethrow;
    }
  }

  // Logout function
  static Future<void> logout() async {
    debugPrint('🚀🚀🚀 NEW LOGOUT CODE IS RUNNING! 🚀🚀🚀');
    try {
      // Call backend logout endpoint if we have a token
      if (_accessToken != null) {
        debugPrint('📡 Calling backend logout endpoint...');
        await http.post(
          Uri.parse('${ApiService.baseUrl}/auth/logout/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_accessToken',
          },
          body: jsonEncode({
            'refresh': _refreshToken,
          }),
        );
        debugPrint('✅ Backend logout call completed');
      } else {
        debugPrint('⚠️ No access token, skipping backend call');
      }
    } catch (e) {
      // Continue with local logout even if backend call fails
      debugPrint('❌ Logout API call failed: $e');
    } finally {
      // Detach this device's push token from the account while creds are still
      // valid, so it stops receiving this account's notifications immediately.
      await FCMService.removeBackendToken(_accessToken);
      // Clear local auth data
      debugPrint('🧹 About to call clearAuthData()...');
      await clearAuthData();
      debugPrint('✅ clearAuthData() completed');
    }
  }

  // Clear all authentication data
  static Future<void> clearAuthData() async {
    debugPrint('🔴 Clearing all auth data...');

    await AdsyConnectRealtimeService.instance.disconnect();
    OnlineStatusService.stop();
    await RideshareDriverPresenceService.stop();
    await SocialAuthService.signOut();

    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;

    final prefs = await SharedPreferences.getInstance();

    // Set a logout flag to prevent session restoration
    await prefs.setBool('adsyclub_logged_out', true);
    debugPrint('🚩 Set logout flag to prevent session restoration');

    // Remove all auth-related keys
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove('adsyclub_auth'); // Remove comprehensive auth data

    // Also clear any legacy keys that might exist
    await prefs.remove('token');
    await prefs.remove('user');

    // List all remaining keys for debugging
    final remainingKeys = prefs.getKeys();
    debugPrint(
        '📋 Remaining keys after clear: ${remainingKeys.where((k) => k.contains('adsy') || k.contains('token') || k.contains('user'))}');

    debugPrint('✅ All auth data cleared from SharedPreferences');
  }

  // Refresh access token using refresh token
  static Future<bool> refreshTokens() async {
    if (_refreshToken == null) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/token/refresh/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refresh': _refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        _accessToken = data['access'];

        // Update stored token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _accessToken!);

        return true;
      } else {
        // Refresh token is invalid, clear auth data
        await clearAuthData();
        return false;
      }
    } catch (e) {
      debugPrint('Token refresh error: $e');
      await clearAuthData();
      return false;
    }
  }

  // Get valid token (refresh if needed) - Enhanced with JWT expiry check
  static Future<String?> getValidToken() async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      // Try to restore from storage before giving up
      await _restoreAuthFromStorage();
      if (_accessToken == null) {
        return null;
      }
    }

    // Check if token is expired by decoding JWT
    try {
      final parts = _accessToken!.split('.');
      if (parts.length == 3) {
        // Decode payload (add padding if needed)
        String payload = parts[1];
        // Add padding if needed for base64 decoding
        while (payload.length % 4 != 0) {
          payload += '=';
        }

        final normalizedPayload = base64.normalize(payload);
        final decodedPayload = utf8.decode(base64.decode(normalizedPayload));
        final Map<String, dynamic> payloadMap = jsonDecode(decodedPayload);

        final exp = payloadMap['exp'];
        if (exp != null) {
          final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          final now = DateTime.now();

          // If token expires in less than 5 minutes, refresh it
          if (expiryTime.difference(now).inMinutes < 5) {
            debugPrint('Token expires soon, refreshing...');
            final refreshSuccess = await refreshTokens();
            if (!refreshSuccess) {
              return null;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Could not decode JWT token: $e');
      // If we can't decode it, try to refresh
      if (_refreshToken != null) {
        final refreshSuccess = await refreshTokens();
        if (!refreshSuccess) {
          return null;
        }
      }
    }

    return _accessToken;
  }

  // Validate token with server - Similar to Vue's jwtLogin
  static Future<bool> validateToken() async {
    if (_accessToken == null) {
      await _restoreAuthFromStorage();
      if (_accessToken == null) {
        return false;
      }
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/auth/validate-token/'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Update user data if provided
        if (data['user'] != null) {
          _currentUser = User.fromJson(data['user']);
          // If the account was suspended (possibly while logged in), lock the
          // app immediately — they can only log out from here.
          if (_currentUser?.isSuspended == true) {
            lockIfSuspended(_currentUser!);
          }
        }

        // Update tokens if provided
        if (data['access'] != null) {
          _accessToken = data['access'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, _accessToken!);
        }

        if (data['refresh'] != null) {
          _refreshToken = data['refresh'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_refreshTokenKey, _refreshToken!);
        }

        return true;
      } else {
        // Token validation failed, try to refresh
        debugPrint('Token validation failed, attempting refresh');
        final refreshSuccess = await refreshTokens();

        if (refreshSuccess) {
          // Retry validation with new token
          return await validateToken();
        }

        return false;
      }
    } catch (e) {
      debugPrint('Token validation error: $e');
      return false;
    }
  }

  // Generate or get device ID
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      deviceId =
          'device_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().millisecondsSinceEpoch * 1000) % 1000}';
      await prefs.setString(_deviceIdKey, deviceId);
    }

    return deviceId;
  }

  // Private method to persist authentication data
  static Future<void> _persistAuthData(AuthResponse authResponse) async {
    _currentUser = authResponse.user;
    _accessToken = authResponse.accessToken;
    _refreshToken = authResponse.refreshToken;

    final prefs = await SharedPreferences.getInstance();

    // Clear logout flag on successful login
    await prefs.remove('adsyclub_logged_out');
    debugPrint('🔓 Cleared logout flag - user is now logged in');

    // Store user data
    await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));

    // Store tokens
    await prefs.setString(_tokenKey, _accessToken!);
    await prefs.setString(_refreshTokenKey, _refreshToken!);

    // Store additional metadata
    final authData = {
      'user': _currentUser!.toJson(),
      'token': _accessToken,
      'refreshToken': _refreshToken,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'deviceId': await getDeviceId(),
    };

    await prefs.setString('adsyclub_auth', jsonEncode(authData));
    debugPrint('💾 Auth data persisted to storage');
  }

  // Private method to restore authentication data from storage
  static Future<void> _restoreAuthFromStorage() async {
    try {
      debugPrint('🔍 Attempting to restore auth from storage...');
      final prefs = await SharedPreferences.getInstance();

      // Check if user explicitly logged out
      final loggedOut = prefs.getBool('adsyclub_logged_out') ?? false;
      if (loggedOut) {
        debugPrint('🚫 User previously logged out - skipping session restoration');
        debugPrint('🧹 Clearing logout flag for next login...');
        await prefs.remove('adsyclub_logged_out');
        return;
      }

      // Try to restore from comprehensive auth data first
      final authDataString = prefs.getString('adsyclub_auth');
      if (authDataString != null) {
        debugPrint('📦 Found adsyclub_auth in storage');
        final authData = jsonDecode(authDataString);
        final timestamp = authData['timestamp'] ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;

        // Check if data is not too old (within 30 days)
        if (now - timestamp < (30 * 24 * 60 * 60 * 1000)) {
          _currentUser = User.fromJson(authData['user']);
          _accessToken = authData['token'];
          _refreshToken = authData['refreshToken'];
          debugPrint('✅ Auth data restored from comprehensive storage');
          return;
        } else {
          debugPrint('⏰ Auth data expired (older than 30 days)');
        }
      }

      // Fallback to individual storage items
      final userString = prefs.getString(_userKey);
      final token = prefs.getString(_tokenKey);
      final refreshToken = prefs.getString(_refreshTokenKey);

      if (userString != null && token != null && refreshToken != null) {
        debugPrint('📦 Found individual auth items');
        _currentUser = User.fromJson(jsonDecode(userString));
        _accessToken = token;
        _refreshToken = refreshToken;
        debugPrint('✅ Auth data restored from individual storage items');
      } else {
        debugPrint('❌ No auth data found in storage');
      }
    } catch (e) {
      debugPrint('❌ Failed to restore auth data: $e');
      // Clear corrupted data
      await clearAuthData();
    }
  }

  // Helper method to make authenticated API requests
  static Future<http.Response> authenticatedRequest({
    required String endpoint,
    required String method,
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final token = await getValidToken();
    if (token == null) {
      throw Exception('No valid authentication token available');
    }

    final uri = Uri.parse('${ApiService.baseUrl}$endpoint');
    final authHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      ...?headers,
    };

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: authHeaders);
      case 'POST':
        return await http.post(uri, headers: authHeaders, body: body);
      case 'PUT':
        return await http.put(uri, headers: authHeaders, body: body);
      case 'DELETE':
        return await http.delete(uri, headers: authHeaders);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  // Refresh current user data from API
  static Future<bool> refreshUserData() async {
    try {
      final token = await getValidToken();
      if (token == null) return false;

      // Try validate-token endpoint which returns user data
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/auth/validate-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // validate-token returns user data in 'user' field
        if (data['user'] != null) {
          _currentUser = User.fromJson(data['user']);

          // Account may have been suspended while the session was alive.
          lockIfSuspended(_currentUser!);

          // Update stored user data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
          final authDataString = prefs.getString('adsyclub_auth');
          if (authDataString != null) {
            final authData = jsonDecode(authDataString);
            authData['user'] = _currentUser!.toJson();
            authData['token'] = _accessToken;
            authData['refreshToken'] = _refreshToken;
            authData['timestamp'] = DateTime.now().millisecondsSinceEpoch;
            await prefs.setString('adsyclub_auth', jsonEncode(authData));
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
      return false;
    }
  }

  // Send OTP for password reset
  static Future<Map<String, dynamic>> sendOtp({
    required String method,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/send-otp/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'method': method,
          method: phone,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['error'] ?? errorData['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Verify OTP
  static Future<Map<String, dynamic>> verifyOtp({
    required String method,
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/verify-otp/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'method': method,
          method: phone,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ??
            errorData['message'] ??
            'Invalid verification code');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Register new user
  static Future<Map<String, dynamic>?> register(
      Map<String, dynamic> formData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/register/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(formData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ??
            errorData['message'] ??
            'Registration failed');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Reset password
  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/reset-password/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        // If auto-login is enabled, save tokens
        if (result['auto_login'] == true && result['tokens'] != null) {
          _accessToken = result['tokens']['access'];
          _refreshToken = result['tokens']['refresh'];

          // Save tokens
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, _accessToken!);
          await prefs.setString(_refreshTokenKey, _refreshToken!);

          // Parse and save user data if provided
          if (result['user'] != null) {
            _currentUser = User.fromJson(result['user']);
            await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
          }
        }

        return result;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ??
            errorData['message'] ??
            'Failed to reset password');
      }
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
