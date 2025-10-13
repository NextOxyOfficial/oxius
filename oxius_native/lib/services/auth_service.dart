import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class User {
  final String id; // Changed from int to String to handle UUID
  final String email;
  final String username;
  final String? firstName;
  final String? lastName;
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

  User({
    required this.id,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
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
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '', // Convert to string to handle both int and string IDs
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      userType: json['user_type'] ?? 'regular',
      isSuperuser: json['is_superuser'] ?? false,
      isActive: json['is_active'] ?? true,
      profilePicture: json['profile_picture'],
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'user_type': userType,
      'is_superuser': isSuperuser,
      'is_active': isActive,
      'profile_picture': profilePicture,
      'referral_code': referralCode,
      'refer_count': referCount,
      'commission_earned': commissionEarned,
      'balance': balance,
      'pending_balance': pendingBalance,
      'diamond_balance': diamondBalance,
      'is_pro': isPro,
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
      accessToken: json['access'] ?? json['access_token'] ?? json['token'] ?? '',
      refreshToken: json['refresh'] ?? json['refresh_token'] ?? '',
      loggedIn: true,
    );
  }
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
  static bool get isAuthenticated => _currentUser != null && _accessToken != null;
  
  // Get token method for compatibility
  static Future<String?> getToken() async {
    return _accessToken;
  }

  // Initialize auth service and restore session if available
  static Future<void> initialize() async {
    await _restoreAuthFromStorage();
  }

  // Login function matching the Vue implementation
  static Future<AuthResponse?> login(String email, String password) async {
    try {
      print('Attempting login with email: $email'); // Debug log
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

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

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
          throw Exception(errorData['error'] ?? errorData['detail'] ?? 'Login failed');
        } catch (jsonError) {
          throw Exception('Login failed with status ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      print('Login error details: $e'); // Debug log
      throw Exception('Login error: $e');
    }
  }

  // Logout function
  static Future<void> logout() async {
    try {
      // Call backend logout endpoint if we have a token
      if (_accessToken != null) {
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
      }
    } catch (e) {
      // Continue with local logout even if backend call fails
      print('Logout API call failed: $e');
    } finally {
      // Clear local auth data
      await clearAuthData();
    }
  }

  // Clear all authentication data
  static Future<void> clearAuthData() async {
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
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
      print('Token refresh error: $e');
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
            print('Token expires soon, refreshing...');
            final refreshSuccess = await refreshTokens();
            if (!refreshSuccess) {
              return null;
            }
          }
        }
      }
    } catch (e) {
      print('Could not decode JWT token: $e');
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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Update user data if provided
        if (data['user'] != null) {
          _currentUser = User.fromJson(data['user']);
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
        print('Token validation failed, attempting refresh');
        final refreshSuccess = await refreshTokens();
        
        if (refreshSuccess) {
          // Retry validation with new token
          return await validateToken();
        }
        
        return false;
      }
    } catch (e) {
      print('Token validation error: $e');
      return false;
    }
  }

  // Generate or get device ID
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    
    if (deviceId == null) {
      deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().millisecondsSinceEpoch * 1000) % 1000}';
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
  }

  // Private method to restore authentication data from storage
  static Future<void> _restoreAuthFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try to restore from comprehensive auth data first
      final authDataString = prefs.getString('adsyclub_auth');
      if (authDataString != null) {
        final authData = jsonDecode(authDataString);
        final timestamp = authData['timestamp'] ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // Check if data is not too old (within 30 days)
        if (now - timestamp < (30 * 24 * 60 * 60 * 1000)) {
          _currentUser = User.fromJson(authData['user']);
          _accessToken = authData['token'];
          _refreshToken = authData['refreshToken'];
          print('Auth data restored from storage');
          return;
        }
      }
      
      // Fallback to individual storage items
      final userString = prefs.getString(_userKey);
      final token = prefs.getString(_tokenKey);
      final refreshToken = prefs.getString(_refreshTokenKey);
      
      if (userString != null && token != null && refreshToken != null) {
        _currentUser = User.fromJson(jsonDecode(userString));
        _accessToken = token;
        _refreshToken = refreshToken;
        print('Auth data restored from individual storage items');
      }
    } catch (e) {
      print('Failed to restore auth data: $e');
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
}