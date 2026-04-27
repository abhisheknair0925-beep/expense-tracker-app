import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Authentication service — Google Sign-In, Phone Auth + Account Linking.
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

  /// Gets list of provider IDs linked to current user
  List<String> get linkedProviders {
    return currentUser?.providerData.map((info) => info.providerId).toList() ?? [];
  }

  /// Sign in with Google or Link Google Account
  Future<User?> signInOrLinkWithGoogle() async {
    try {
      final googleUser = await _google.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      if (currentUser != null) {
        // SCENARIO: Account Linking
        try {
          final authResult = await currentUser!.linkWithCredential(credential);
          return authResult.user;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            debugPrint('AuthService: Credential already in use by another account.');
            // This error means the google account is already linked to another firebase user.
            throw 'This Google account is already linked to another user.';
          }
          rethrow;
        }
      } else {
        // SCENARIO: Fresh Sign-in
        final result = await _auth.signInWithCredential(credential);
        return result.user;
      }
    } catch (e) {
      debugPrint('AuthService: Google sign-in/linking failed: $e');
      rethrow;
    }
  }

  /// Verifies OTP and signs in or links the account.
  Future<User?> signInOrLinkWithPhone(PhoneAuthCredential credential) async {
    try {
      if (currentUser != null) {
        // SCENARIO: Account Linking
        try {
          final authResult = await currentUser!.linkWithCredential(credential);
          return authResult.user;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' || e.code == 'provider-already-linked') {
            debugPrint('AuthService: Phone credential already linked or in use.');
            throw 'This phone number is already linked to another user.';
          }
          rethrow;
        }
      } else {
        // SCENARIO: Fresh Sign-in
        final authResult = await _auth.signInWithCredential(credential);
        return authResult.user;
      }
    } catch (e) {
      debugPrint('AuthService: Phone sign-in/linking failed: $e');
      rethrow;
    }
  }

  /// Starts the phone verification process.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onAutoVerify,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onAutoVerify,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (String vid) {},
      timeout: const Duration(seconds: 60),
    );
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
}
