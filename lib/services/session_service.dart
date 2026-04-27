import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/session_model.dart';
import '../utils/device_info.dart';

class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _storage = const FlutterSecureStorage();
  final _uuid = const Uuid();

  static const String _sessionKey = 'session_id';
  static const Duration sessionTimeout = Duration(hours: 24);

  /// Create a new session on login
  Future<SessionModel?> createSession(String userId) async {
    final deviceInfo = await DeviceInfoUtil.getDeviceInfo();
    final sessionId = _uuid.v4();
    
    final session = SessionModel(
      sessionId: sessionId,
      userId: userId,
      deviceId: deviceInfo['deviceId']!,
      deviceName: deviceInfo['deviceName']!,
      platform: deviceInfo['platform']!,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
      isActive: true,
    );

    try {
      // 1. Save to Firestore
      await _db.collection('users').doc(userId).collection('sessions').doc(sessionId).set(session.toMap());
      
      // 2. Save locally
      await _storage.write(key: _sessionKey, value: sessionId);
      
      return session;
    } catch (e) {
      debugPrint('SessionService: Error creating session: $e');
      return null;
    }
  }

  /// Validate current session on app start or activity
  Future<bool> validateSession() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final sessionId = await _storage.read(key: _sessionKey);
    if (sessionId == null) return false;

    try {
      final doc = await _db.collection('users').doc(user.uid).collection('sessions').doc(sessionId).get();
      
      if (!doc.exists) return false;
      
      final session = SessionModel.fromMap(doc.data()!);
      
      // Check if session is explicitly inactivated
      if (!session.isActive) return false;

      // Check for timeout
      final diff = DateTime.now().difference(session.lastActiveAt);
      if (diff > sessionTimeout) {
        await logoutSession();
        return false;
      }

      // Session is valid, update activity
      await updateActivity();
      return true;
    } catch (e) {
      debugPrint('SessionService: Error validating session: $e');
      return false;
    }
  }

  /// Update last active timestamp
  Future<void> updateActivity() async {
    final user = _auth.currentUser;
    final sessionId = await _storage.read(key: _sessionKey);
    
    if (user != null && sessionId != null) {
      try {
        await _db.collection('users').doc(user.uid).collection('sessions').doc(sessionId).update({
          'lastActiveAt': Timestamp.fromDate(DateTime.now()),
        });
      } catch (e) {
        debugPrint('SessionService: Error updating activity: $e');
      }
    }
  }

  /// Logout current session
  Future<void> logoutSession() async {
    final user = _auth.currentUser;
    final sessionId = await _storage.read(key: _sessionKey);

    if (user != null && sessionId != null) {
      try {
        await _db.collection('users').doc(user.uid).collection('sessions').doc(sessionId).update({
          'isActive': false,
        });
      } catch (e) {
        debugPrint('SessionService: Error inactivating session: $e');
      }
    }

    await _storage.delete(key: _sessionKey);
    await _auth.signOut();
  }

  /// Get all active sessions for a user (Device Management)
  Stream<List<SessionModel>> getActiveSessions(String userId) {
    return _db.collection('users').doc(userId).collection('sessions')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SessionModel.fromMap(doc.data())).toList());
  }

  /// Inactivate a specific session
  Future<void> inactivateSession(String userId, String sessionId) async {
    await _db.collection('users').doc(userId).collection('sessions').doc(sessionId).update({
      'isActive': false,
    });
  }
}
