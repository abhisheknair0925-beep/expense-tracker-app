import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../models/session_model.dart';

class SessionProvider extends ChangeNotifier {
  final _sessionService = SessionService.instance;
  
  bool _isSessionValid = false;
  bool get isSessionValid => _isSessionValid;
  
  List<SessionModel> _activeSessions = [];
  List<SessionModel> get activeSessions => _activeSessions;

  /// Validates session and updates state
  Future<void> checkSession() async {
    _isSessionValid = await _sessionService.validateSession();
    notifyListeners();
  }

  /// Called on login to initialize session
  Future<void> startSession(String userId) async {
    await _sessionService.createSession(userId);
    _isSessionValid = true;
    notifyListeners();
  }

  /// Manually update activity (e.g. on navigation)
  Future<void> trackActivity() async {
    if (_isSessionValid) {
      await _sessionService.updateActivity();
    }
  }

  /// Device management: Load other devices
  void listenToSessions(String userId) {
    _sessionService.getActiveSessions(userId).listen((sessions) {
      _activeSessions = sessions;
      notifyListeners();
    });
  }

  /// Logout specific device
  Future<void> logoutOtherDevice(String userId, String sessionId) async {
    await _sessionService.inactivateSession(userId, sessionId);
  }

  /// Global logout
  Future<void> logout() async {
    await _sessionService.logoutSession();
    _isSessionValid = false;
    notifyListeners();
  }
}
