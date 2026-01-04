import 'dart:convert';
import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:http/http.dart' as http;

import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';

class FirebaseCallAuthService {
  FirebaseCallAuthService._();

  static final FirebaseCallAuthService instance = FirebaseCallAuthService._();

  String? _lastError;
  String? get lastError => _lastError;

  Future<bool> ensureSignedIn() async {
    _lastError = null;
    try {
      final current = fb.FirebaseAuth.instance.currentUser;
      if (current != null) {
        dev.log('[FirebaseCallAuth] Already signed in: ${current.uid}');
        return true;
      }

      if (!AuthService.isAuthenticated) {
        _lastError = 'User not authenticated with backend';
        dev.log('[FirebaseCallAuth] ERROR: $_lastError');
        return false;
      }

      final token = await AuthService.getValidToken();
      if (token == null || token.isEmpty) {
        _lastError = 'Failed to get backend auth token';
        dev.log('[FirebaseCallAuth] ERROR: $_lastError');
        return false;
      }

      dev.log('[FirebaseCallAuth] Fetching Firebase custom token...');
      final resp = await http.get(
        Uri.parse('${ApiService.baseUrl}/adsyconnect/firebase-token/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      dev.log('[FirebaseCallAuth] Response status: ${resp.statusCode}');

      if (resp.statusCode != 200) {
        _lastError = 'Firebase token API failed: ${resp.statusCode} - ${resp.body}';
        dev.log('[FirebaseCallAuth] ERROR: $_lastError');
        return false;
      }

      final decoded = jsonDecode(resp.body);
      if (decoded is! Map) {
        _lastError = 'Invalid response format from Firebase token API';
        dev.log('[FirebaseCallAuth] ERROR: $_lastError');
        return false;
      }

      if (decoded['error'] != null) {
        _lastError = 'Firebase token API error: ${decoded['error']}';
        dev.log('[FirebaseCallAuth] ERROR: $_lastError');
        return false;
      }

      final customToken = decoded['token']?.toString();
      if (customToken == null || customToken.isEmpty) {
        _lastError = 'No token in Firebase token API response';
        dev.log('[FirebaseCallAuth] ERROR: $_lastError');
        return false;
      }

      dev.log('[FirebaseCallAuth] Signing in with custom token...');
      await fb.FirebaseAuth.instance.signInWithCustomToken(customToken);
      
      final signedIn = fb.FirebaseAuth.instance.currentUser != null;
      if (signedIn) {
        dev.log('[FirebaseCallAuth] SUCCESS: Signed in as ${fb.FirebaseAuth.instance.currentUser?.uid}');
      } else {
        _lastError = 'Firebase signInWithCustomToken succeeded but currentUser is null';
        dev.log('[FirebaseCallAuth] ERROR: $_lastError');
      }
      return signedIn;
    } catch (e, st) {
      _lastError = 'Exception during Firebase auth: $e';
      dev.log('[FirebaseCallAuth] EXCEPTION: $e\n$st');
      return false;
    }
  }

  String? get uid => fb.FirebaseAuth.instance.currentUser?.uid;
}
