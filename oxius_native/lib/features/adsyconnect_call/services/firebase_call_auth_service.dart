import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:http/http.dart' as http;

import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';

class FirebaseCallAuthService {
  FirebaseCallAuthService._();

  static final FirebaseCallAuthService instance = FirebaseCallAuthService._();

  Future<bool> ensureSignedIn() async {
    final current = fb.FirebaseAuth.instance.currentUser;
    if (current != null) return true;

    if (!AuthService.isAuthenticated) return false;

    final token = await AuthService.getValidToken();
    if (token == null || token.isEmpty) return false;

    final resp = await http.get(
      Uri.parse('${ApiService.baseUrl}/adsyconnect/firebase-token/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (resp.statusCode != 200) {
      return false;
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is! Map) return false;

    final customToken = decoded['token']?.toString();
    if (customToken == null || customToken.isEmpty) return false;

    await fb.FirebaseAuth.instance.signInWithCustomToken(customToken);
    return fb.FirebaseAuth.instance.currentUser != null;
  }

  String? get uid => fb.FirebaseAuth.instance.currentUser?.uid;
}
