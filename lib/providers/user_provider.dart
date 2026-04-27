import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/profile_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final _userService = UserService.instance;

  UserModel? _userProfile;
  List<ProfileModel> _profiles = [];
  ProfileModel? _selectedProfile;
  bool _loading = false;

  UserModel? get userProfile => _userProfile;
  List<ProfileModel> get profiles => _profiles;
  ProfileModel? get selectedProfile => _selectedProfile;
  bool get loading => _loading;

  bool get needsOnboarding => _userProfile == null;

  /// Loads the user profile and their associated sub-profiles.
  Future<void> loadUserData(String userId) async {
    _loading = true;
    notifyListeners();

    try {
      _userProfile = await _userService.getUser(userId);
      if (_userProfile != null) {
        _profiles = await _userService.getProfiles(userId);
        if (_profiles.isNotEmpty) {
          _selectedProfile = _profiles.first;
        }
      }
    } catch (e) {
      debugPrint('UserProvider: Error loading user data: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Completes the onboarding process by creating the user profile and the first sub-profile.
  Future<void> completeOnboarding({
    required String userId,
    required String name,
    required ProfileType initialProfileType,
    String? email,
    String? phone,
    String? photoUrl,
    List<String> providers = const [],
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final newUser = UserModel(
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        linkedProviders: providers,
      );

      await _userService.createUser(newUser);
      _userProfile = newUser;

      // Create initial profile
      final firstProfile = ProfileModel(
        profileId: const Uuid().v4(),
        profileType: initialProfileType,
        createdAt: DateTime.now(),
      );

      await _userService.createProfile(userId, firstProfile);
      _profiles = [firstProfile];
      _selectedProfile = firstProfile;

    } catch (e) {
      debugPrint('UserProvider: Onboarding failed: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Switches the active profile.
  void selectProfile(ProfileModel profile) {
    _selectedProfile = profile;
    notifyListeners();
    // Here you would typically also trigger a reload of profile-specific data (transactions, etc.)
  }

  /// Adds a new profile (e.g., adding Business profile if only Personal exists).
  Future<void> addProfile(String userId, ProfileType type) async {
    try {
      final newProfile = ProfileModel(
        profileId: const Uuid().v4(),
        profileType: type,
        createdAt: DateTime.now(),
      );
      await _userService.createProfile(userId, newProfile);
      _profiles.add(newProfile);
      notifyListeners();
    } catch (e) {
      debugPrint('UserProvider: Error adding profile: $e');
    }
  }

  void clear() {
    _userProfile = null;
    _profiles = [];
    _selectedProfile = null;
    notifyListeners();
  }
}
