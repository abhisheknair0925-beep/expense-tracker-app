/// Budget model — per-category monthly spending limit. Cloud-sync ready.
class Budget {
  final int? id;
  final String? firestoreId;
  final String? userId;
  final String category;
  final double limit;
  final int month;
  final int year;
  final DateTime updatedAt;
  final bool isSynced;

  Budget({this.id, this.firestoreId, this.userId, required this.category, required this.limit, required this.month, required this.year, DateTime? updatedAt, this.isSynced = false})
      : updatedAt = updatedAt ?? DateTime.now();

  factory Budget.fromMap(Map<String, dynamic> m) => Budget(
        id: m['id'] as int?,
        firestoreId: m['firestoreId'] as String?,
        userId: m['userId'] as String?,
        category: m['category'] as String,
        limit: (m['budgetLimit'] as num).toDouble(),
        month: m['month'] as int,
        year: m['year'] as int,
        updatedAt: m['updatedAt'] != null ? DateTime.parse(m['updatedAt'] as String) : DateTime.now(),
        isSynced: (m['isSynced'] as int?) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'firestoreId': firestoreId, 'userId': userId,
        'category': category, 'budgetLimit': limit, 'month': month, 'year': year,
        'updatedAt': updatedAt.toIso8601String(), 'isSynced': isSynced ? 1 : 0,
      };

  Map<String, dynamic> toFirestore() => {
        'category': category, 'budgetLimit': limit, 'month': month, 'year': year,
        'updatedAt': updatedAt.toIso8601String(),
      };

  Budget copyWith({int? id, double? limit, String? firestoreId, String? userId, DateTime? updatedAt, bool? isSynced}) =>
      Budget(id: id ?? this.id, firestoreId: firestoreId ?? this.firestoreId, userId: userId ?? this.userId, category: category, limit: limit ?? this.limit, month: month, year: year, updatedAt: updatedAt ?? this.updatedAt, isSynced: isSynced ?? this.isSynced);
}
