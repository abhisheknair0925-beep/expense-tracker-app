class Goal {
  final int? id;
  final String? firestoreId;
  final String? userId;
  final String? profileId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String category;
  final bool isCompleted;
  final DateTime updatedAt;
  final bool isSynced;

  Goal({
    this.id,
    this.firestoreId,
    this.userId,
    this.profileId,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.targetDate,
    required this.category,
    this.isCompleted = false,
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
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toIso8601String(),
      'category': category,
      'isCompleted': isCompleted ? 1 : 0,
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
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toIso8601String(),
      'category': category,
      'isCompleted': isCompleted,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      firestoreId: map['firestoreId'],
      userId: map['userId'],
      profileId: map['profileId'],
      name: map['name'] ?? '',
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetDate: map['targetDate'] != null ? DateTime.parse(map['targetDate']) : DateTime.now(),
      category: map['category'] ?? 'Other',
      isCompleted: map['isCompleted'] == 1 || map['isCompleted'] == true,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
      isSynced: map['isSynced'] == 1 || map['isSynced'] == true,
    );
  }

  Goal copyWith({
    int? id,
    String? firestoreId,
    String? userId,
    String? profileId,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? category,
    bool? isCompleted,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Goal(
      id: id ?? this.id,
      firestoreId: firestoreId ?? this.firestoreId,
      userId: userId ?? this.userId,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
