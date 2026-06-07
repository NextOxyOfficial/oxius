import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Handles the provider side of social login (Google / Facebook) via Firebase
/// Auth and returns a Firebase ID token that the backend (`/auth/social/`)
/// verifies with the Firebase Admin SDK.
///
/// Kept separate from [AuthService] so all firebase_auth / google_sign_in /
/// facebook plugin imports live in one place.
class SocialAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Sign in with Google and return a Firebase ID token.
  /// Returns `null` if the user cancels the picker.
  static Future<String?> signInWithGoogle() async {
    // Ensure a clean picker every time (avoids silently reusing a stale account).
    await _googleSignIn.signOut();

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null; // user cancelled
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCred =
        await FirebaseAuth.instance.signInWithCredential(credential);

    return userCred.user?.getIdToken(true);
  }

  /// Sign in with Facebook and return a Firebase ID token.
  /// Returns `null` if the user cancels.
  static Future<String?> signInWithFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: const ['email', 'public_profile'],
    );

    if (result.status != LoginStatus.success || result.accessToken == null) {
      if (result.status == LoginStatus.cancelled) {
        return null; // user cancelled
      }
      throw Exception(result.message ?? 'Facebook login failed');
    }

    final OAuthCredential credential = FacebookAuthProvider.credential(
      result.accessToken!.tokenString,
    );

    final UserCredential userCred =
        await FirebaseAuth.instance.signInWithCredential(credential);

    return userCred.user?.getIdToken(true);
  }

  /// Clear provider sessions so the next login shows a fresh picker.
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }
}
