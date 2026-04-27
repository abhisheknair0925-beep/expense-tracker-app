import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/profile_model.dart';

class UserService {
  UserService._();
  static final UserService instance = UserService._();

  final _db = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _usersCollection => _db.collection('users');

  /// Fetches user document from Firestore
  Future<UserModel?> getUser(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  /// Creates a new user document if it doesn't exist
  Future<void> createUser(UserModel user) async {
    await _usersCollection.doc(user.userId).set(user.toMap(), SetOptions(merge: true));
  }

  /// Updates existing user document
  Future<void> updateUser(UserModel user) async {
    await _usersCollection.doc(user.userId).update(user.toMap());
  }

  /// Fetches all profiles for a specific user
  Future<List<ProfileModel>> getProfiles(String userId) async {
    final snapshot = await _usersCollection.doc(userId).collection('profiles').get();
    return snapshot.docs.map((doc) => ProfileModel.fromMap(doc.data())).toList();
  }

  /// Creates a new profile for a user
  Future<void> createProfile(String userId, ProfileModel profile) async {
    await _usersCollection
        .doc(userId)
        .collection('profiles')
        .doc(profile.profileId)
        .set(profile.toMap());
  }

  /// Listen to user document changes
  Stream<UserModel?> streamUser(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  /// Listen to profiles collection changes
  Stream<List<ProfileModel>> streamProfiles(String userId) {
    return _usersCollection.doc(userId).collection('profiles').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProfileModel.fromMap(doc.data())).toList();
    });
  }
}
