import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App security service — PIN and biometric lock.
class SecurityService {
  SecurityService._();
  static final SecurityService instance = SecurityService._();

  final _auth = LocalAuthentication();
  static const _pinKey = 'app_lock_pin';
  static const _lockEnabledKey = 'app_lock_enabled';
  static const _biometricKey = 'biometric_enabled';

  /// Check if device supports biometrics.
  Future<bool> get canUseBiometrics async {
    try { return await _auth.canCheckBiometrics; }
    catch (_) { return false; }
  }

  /// Check if lock is enabled.
  Future<bool> get isLockEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lockEnabledKey) ?? false;
  }

  /// Check if biometric is enabled.
  Future<bool> get isBiometricEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey) ?? false;
  }

  /// Get stored PIN.
  Future<String?> get storedPin async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey);
  }

  /// Set PIN and enable lock.
  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    await prefs.setBool(_lockEnabledKey, true);
  }

  /// Toggle biometric auth.
  Future<void> setBiometric(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, enabled);
  }

  /// Disable lock entirely.
  Future<void> disableLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.setBool(_lockEnabledKey, false);
    await prefs.setBool(_biometricKey, false);
  }

  /// Verify PIN.
  Future<bool> verifyPin(String pin) async {
    final stored = await storedPin;
    return stored != null && stored == pin;
  }

  /// Authenticate with biometrics.
  Future<bool> authenticateBiometric() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Expense Tracker',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      return false;
    }
  }
}
