import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String? name;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final List<String> linkedProviders;

  UserModel({
    required this.userId,
    this.name,
    this.email,
    this.phone,
    this.photoUrl,
    this.createdAt,
    this.lastLogin,
    this.linkedProviders = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : FieldValue.serverTimestamp(),
      'linkedProviders': linkedProviders,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] ?? '',
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      lastLogin: (map['lastLogin'] as Timestamp?)?.toDate(),
      linkedProviders: List<String>.from(map['linkedProviders'] ?? []),
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    DateTime? lastLogin,
    List<String>? linkedProviders,
  }) {
    return UserModel(
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      linkedProviders: linkedProviders ?? this.linkedProviders,
    );
  }
}
