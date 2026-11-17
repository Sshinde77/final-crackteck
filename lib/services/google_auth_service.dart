import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoogleAuthService {
  GoogleAuthService({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn;

  // Keep construction lazy. google_sign_in_web validates the OAuth client ID
  // in its constructor, so creating this service while the login screen is
  // being built can crash the whole screen when web configuration is absent.
  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _client =>
      _googleSignIn ??= GoogleSignIn(scopes: const <String>['email', 'profile']);

  Future<GoogleAuthResult> signIn() async {
    try {
      await _client.signOut();

      final GoogleSignInAccount? googleUser = await _client.signIn();
      if (googleUser == null) {
        throw const GoogleAuthException('Google sign-in was cancelled.');
      }
      debugPrint('Google user selected');

      final GoogleSignInAuthentication authentication =
          await googleUser.authentication;

      final String accessToken = authentication.accessToken ?? '';
      debugPrint('Access Token: $accessToken');
      if (accessToken.trim().isEmpty) {
        throw const GoogleAuthException(
          'Google sign-in did not return an access token.',
        );
      }

      return GoogleAuthResult(
        displayName: googleUser.displayName,
        email: googleUser.email,
        photoUrl: googleUser.photoUrl,
        googleUserId: googleUser.id,
        accessToken: accessToken,
      );
    } catch (error) {
      debugPrint('Unexpected Google sign-in error: $error');
      if (error is GoogleAuthException) {
        rethrow;
      }
      throw const GoogleAuthException('Unable to sign in with Google.');
    }
  }

  Future<void> signOut() async {
    final googleSignIn = _googleSignIn;
    if (googleSignIn == null) return;

    try {
      await googleSignIn.disconnect();
    } catch (_) {
      await googleSignIn.signOut();
    }
  }
}

class GoogleAuthResult {
  const GoogleAuthResult({
    required this.accessToken,
    this.displayName,
    this.email,
    this.photoUrl,
    this.googleUserId,
  });

  final String accessToken;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String? googleUserId;
}
