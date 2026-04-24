import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

/// Auth state management — login, logout, auto-sync on auth change.
class AuthProvider extends ChangeNotifier {
  final _auth = AuthService.instance;
  final _sync = SyncService.instance;

  User? _user;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get isSignedIn => _user != null;
  bool get loading => _loading;
  String? get error => _error;
  String get displayName => _user?.displayName ?? 'Guest';
  String? get email => _user?.email;
  String? get photoUrl => _user?.photoURL;

  AuthProvider() {
    // Listen to auth state changes
    _auth.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
      if (user != null) _sync.syncAll(); // Auto-sync on sign-in
    });
    // Check current user on init
    _user = _auth.currentUser;
  }

  /// Sign in with Google.
  Future<bool> signInWithGoogle() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _auth.signInWithGoogle();
      _user = user;
      _loading = false;
      notifyListeners();

      if (user != null) {
        await _sync.syncAll(); // Sync on first login
        return true;
      }
      _error = 'Sign-in cancelled';
      return false;
    } catch (e) {
      _error = 'Sign-in failed: $e';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    _loading = true;
    notifyListeners();
    await _auth.signOut();
    _user = null;
    _loading = false;
    notifyListeners();
  }

  /// Trigger manual sync.
  Future<void> manualSync() async {
    if (!isSignedIn) return;
    await _sync.syncAll();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
