/// Account data model — Bank, Cash, or Wallet. Cloud-sync ready.
class Account {
  final int? id;
  final String? firestoreId;
  final String? userId;
  final String name;
  final String type; // 'bank' | 'cash' | 'wallet'
  final double balance;
  final DateTime updatedAt;
  final bool isSynced;

  Account({this.id, this.firestoreId, this.userId, required this.name, required this.type, this.balance = 0, DateTime? updatedAt, this.isSynced = false})
      : updatedAt = updatedAt ?? DateTime.now();

  factory Account.fromMap(Map<String, dynamic> m) => Account(
        id: m['id'] as int?,
        firestoreId: m['firestoreId'] as String?,
        userId: m['userId'] as String?,
        name: m['name'] as String,
        type: m['type'] as String,
        balance: (m['balance'] as num).toDouble(),
        updatedAt: m['updatedAt'] != null ? DateTime.parse(m['updatedAt'] as String) : DateTime.now(),
        isSynced: (m['isSynced'] as int?) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'firestoreId': firestoreId,
        'userId': userId,
        'name': name,
        'type': type,
        'balance': balance,
        'updatedAt': updatedAt.toIso8601String(),
        'isSynced': isSynced ? 1 : 0,
      };

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'type': type,
        'balance': balance,
        'updatedAt': updatedAt.toIso8601String(),
      };

  Account copyWith({int? id, double? balance, String? firestoreId, String? userId, DateTime? updatedAt, bool? isSynced}) => Account(
        id: id ?? this.id, firestoreId: firestoreId ?? this.firestoreId, userId: userId ?? this.userId,
        name: name, type: type, balance: balance ?? this.balance,
        updatedAt: updatedAt ?? this.updatedAt, isSynced: isSynced ?? this.isSynced,
      );
}
