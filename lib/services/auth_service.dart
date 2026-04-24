import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Authentication service — Google Sign-In + session management.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _google = GoogleSignIn();

  /// Current Firebase user (null if not signed in).
  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;
  String? get uid => currentUser?.uid;

  /// Listen to auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google.
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _google.signIn();
      if (googleUser == null) return null; // User cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      debugPrint('AuthService: Signed in as ${result.user?.displayName}');
      return result.user;
    } catch (e) {
      debugPrint('AuthService: Google sign-in failed: $e');
      return null;
    }
  }

  /// Sign out from Google + Firebase.
  Future<void> signOut() async {
    try {
      await _google.signOut();
      await _auth.signOut();
      debugPrint('AuthService: Signed out');
    } catch (e) {
      debugPrint('AuthService: Sign out error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PHONE OTP — Structure ready for future implementation
  // ═══════════════════════════════════════════════════════════════════

  /// Phone OTP stub — ready for implementation.
  ///
  /// ```dart
  /// await _auth.verifyPhoneNumber(
  ///   phoneNumber: '+91$phone',
  ///   verificationCompleted: (credential) async {
  ///     await _auth.signInWithCredential(credential);
  ///   },
  ///   verificationFailed: (e) => debugPrint('Phone auth failed: $e'),
  ///   codeSent: (verificationId, resendToken) { /* Show OTP input */ },
  ///   codeAutoRetrievalTimeout: (verificationId) {},
  /// );
  /// ```
  Future<void> sendOtp(String phone) async {
    debugPrint('AuthService: Phone OTP stub — not yet implemented for $phone');
  }
}
