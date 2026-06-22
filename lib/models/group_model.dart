import 'dart:convert';

class Group {
  final int? id;
  final String? firestoreId;
  final String? userId;
  final String? profileId;
  final String name;
  final String? description;
  final List<String> members;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  Group({
    this.id,
    this.firestoreId,
    this.userId,
    this.profileId,
    required this.name,
    this.description,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'firestoreId': firestoreId,
      'userId': userId,
      'profileId': profileId,
      'name': name,
      'description': description,
      'members': json.encode(members),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'firestoreId': firestoreId,
      'userId': userId,
      'profileId': profileId,
      'name': name,
      'description': description,
      'members': members,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    final membersRaw = map['members'];
    List<String> membersList = [];
    if (membersRaw is String) {
      membersList = List<String>.from(json.decode(membersRaw));
    } else if (membersRaw is List) {
      membersList = List<String>.from(membersRaw);
    }

    return Group(
      id: map['id'],
      firestoreId: map['firestoreId'],
      userId: map['userId'],
      profileId: map['profileId'],
      name: map['name'] ?? '',
      description: map['description'],
      members: membersList,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
      isSynced: map['isSynced'] == 1 || map['isSynced'] == true,
    );
  }

  Group copyWith({
    int? id,
    String? firestoreId,
    String? userId,
    String? profileId,
    String? name,
    String? description,
    List<String>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Group(
      id: id ?? this.id,
      firestoreId: firestoreId ?? this.firestoreId,
      userId: userId ?? this.userId,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      description: description ?? this.description,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
