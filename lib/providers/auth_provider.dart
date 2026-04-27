import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import 'user_provider.dart';
import 'session_provider.dart';

/// Auth state management — login, logout, account linking & profile integration.
class AuthProvider extends ChangeNotifier {
  final _auth = AuthService.instance;
  final _sync = SyncService.instance;
  final UserProvider _userProvider;
  final SessionProvider _sessionProvider;

  User? _user;
  bool _loading = false;
  String? _error;
  String? _verificationId;

  User? get user => _user;
  bool get isSignedIn => _user != null;
  bool get loading => _loading;
  String? get error => _error;
  
  // Proxy properties from firebase user
  String get displayName {
    final name = _user?.displayName ?? _userProvider.userProfile?.name;
    if (name == null || name.trim().isEmpty) return 'Guest';
    return name;
  }
  String? get email => _user?.email;
  String? get photoUrl => _user?.photoURL;
  List<String> get linkedProviders => _auth.linkedProviders;

  AuthProvider(this._userProvider, this._sessionProvider) {
    // Listen to auth state changes
    _auth.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        await _userProvider.loadUserData(user.uid);
        await _sessionProvider.startSession(user.uid);
        _sync.syncAll();
      } else {
        _userProvider.clear();
      }
      notifyListeners();
    });
    
    // Check initial user
    _user = _auth.currentUser;
    if (_user != null) {
      _userProvider.loadUserData(_user!.uid);
      _sessionProvider.checkSession();
    }
  }

  /// Sign in with Google or Link Google Account
  Future<bool> signInWithGoogle() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _auth.signInOrLinkWithGoogle();
      _user = user;
      if (user != null) {
        await _userProvider.loadUserData(user.uid);
        await _sessionProvider.startSession(user.uid);
        await _sync.syncAll();
      }
      return user != null;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Google Auth Error: $e';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Step 1: Trigger OTP Sending
  Future<void> sendOtp(String phoneNumber, VoidCallback onCodeSent) async {
    _error = null;
    _loading = true;
    notifyListeners();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _loading = false;
          notifyListeners();
          onCodeSent();
        },
        onVerificationFailed: (e) {
          _loading = false;
          _error = e.message ?? "Verification failed";
          notifyListeners();
        },
        onAutoVerify: (credential) async {
          await _verifyCredential(credential);
        },
      );
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Step 2: Verify OTP and Sign In/Link
  Future<bool> verifyOtp(String smsCode) async {
    if (_verificationId == null) {
      _error = "Verification session expired";
      notifyListeners();
      return false;
    }
    _loading = true;
    notifyListeners();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      return await _verifyCredential(credential);
    } catch (e) {
      _error = "Invalid OTP code";
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _verifyCredential(PhoneAuthCredential credential) async {
    try {
      final user = await _auth.signInOrLinkWithPhone(credential);
      _user = user;
      if (user != null) {
        await _userProvider.loadUserData(user.uid);
        await _sessionProvider.startSession(user.uid);
        await _sync.syncAll();
      }
      return user != null;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    _loading = true;
    notifyListeners();
    await _sessionProvider.logout();
    _user = null;
    _userProvider.clear();
    _loading = false;
    notifyListeners();
  }

  /// Manually trigger a sync
  Future<void> manualSync() async {
    await _sync.syncAll();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
