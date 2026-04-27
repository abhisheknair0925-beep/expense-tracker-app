import 'package:cloud_firestore/cloud_firestore.dart';

enum ProfileType { personal, business }

class ProfileModel {
  final String profileId;
  final ProfileType profileType;
  final DateTime? createdAt;

  ProfileModel({
    required this.profileId,
    required this.profileType,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'profileId': profileId,
      'profileType': profileType.name,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      profileId: map['profileId'] ?? '',
      profileType: ProfileType.values.firstWhere(
        (e) => e.name == map['profileType'],
        orElse: () => ProfileType.personal,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
