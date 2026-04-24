/// Transaction data model with cloud sync support.
class Txn {
  final int? id;
  final String? firestoreId;
  final String? userId;
  final String title;
  final double amount;
  final String type; // 'income' | 'expense'
  final String category;
  final int? accountId;
  final String? receiptPath;
  final DateTime date;
  final DateTime updatedAt;
  final bool isSynced;

  const Txn({
    this.id,
    this.firestoreId,
    this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    this.accountId,
    this.receiptPath,
    required this.date,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : updatedAt = updatedAt ?? date;

  bool get isIncome => type == 'income';
  bool get hasReceipt => receiptPath != null && receiptPath!.isNotEmpty;

  factory Txn.fromMap(Map<String, dynamic> m) => Txn(
        id: m['id'] as int?,
        firestoreId: m['firestoreId'] as String?,
        userId: m['userId'] as String?,
        title: m['title'] as String,
        amount: (m['amount'] as num).toDouble(),
        type: m['type'] as String,
        category: m['category'] as String,
        accountId: m['accountId'] as int?,
        receiptPath: m['receiptPath'] as String?,
        date: DateTime.parse(m['date'] as String),
        updatedAt: m['updatedAt'] != null ? DateTime.parse(m['updatedAt'] as String) : DateTime.now(),
        isSynced: (m['isSynced'] as int?) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'firestoreId': firestoreId,
        'userId': userId,
        'title': title,
        'amount': amount,
        'type': type,
        'category': category,
        'accountId': accountId,
        'receiptPath': receiptPath,
        'date': date.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isSynced': isSynced ? 1 : 0,
      };

  /// Convert to Firestore-safe map (no SQLite id, no isSynced flag).
  Map<String, dynamic> toFirestore() => {
        'title': title,
        'amount': amount,
        'type': type,
        'category': category,
        'receiptPath': receiptPath,
        'date': date.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Txn copyWith({int? id, int? accountId, String? receiptPath, String? firestoreId, String? userId, DateTime? updatedAt, bool? isSynced}) =>
      Txn(id: id ?? this.id, firestoreId: firestoreId ?? this.firestoreId, userId: userId ?? this.userId, title: title, amount: amount, type: type, category: category, accountId: accountId ?? this.accountId, receiptPath: receiptPath ?? this.receiptPath, date: date, updatedAt: updatedAt ?? this.updatedAt, isSynced: isSynced ?? this.isSynced);
}
