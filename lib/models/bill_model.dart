/// Bill reminder data model. Cloud-sync ready.
class Bill {
  final int? id;
  final String? firestoreId;
  final String? userId;
  final String title;
  final double amount;
  final String category;
  final DateTime dueDate;
  final String repeat; // 'monthly' | 'weekly' | 'yearly'
  final bool isPaid;
  final DateTime updatedAt;
  final bool isSynced;

  Bill({
    this.id, this.firestoreId, this.userId,
    required this.title, required this.amount, required this.category,
    required this.dueDate, this.repeat = 'monthly', this.isPaid = false,
    DateTime? updatedAt, this.isSynced = false,
  }) : updatedAt = updatedAt ?? DateTime.now();

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;
  bool get isOverdue => !isPaid && daysUntilDue < 0;
  bool get isDueSoon => !isPaid && daysUntilDue >= 0 && daysUntilDue <= 7;

  factory Bill.fromMap(Map<String, dynamic> m) => Bill(
        id: m['id'] as int?,
        firestoreId: m['firestoreId'] as String?,
        userId: m['userId'] as String?,
        title: m['title'] as String,
        amount: (m['amount'] as num).toDouble(),
        category: m['category'] as String,
        dueDate: DateTime.parse(m['dueDate'] as String),
        repeat: m['repeat'] as String? ?? 'monthly',
        isPaid: (m['isPaid'] as int?) == 1,
        updatedAt: m['updatedAt'] != null ? DateTime.parse(m['updatedAt'] as String) : DateTime.now(),
        isSynced: (m['isSynced'] as int?) == 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'firestoreId': firestoreId, 'userId': userId,
        'title': title, 'amount': amount, 'category': category,
        'dueDate': dueDate.toIso8601String(), 'repeat': repeat, 'isPaid': isPaid ? 1 : 0,
        'updatedAt': updatedAt.toIso8601String(), 'isSynced': isSynced ? 1 : 0,
      };

  Map<String, dynamic> toFirestore() => {
        'title': title, 'amount': amount, 'category': category,
        'dueDate': dueDate.toIso8601String(), 'repeat': repeat, 'isPaid': isPaid,
        'updatedAt': updatedAt.toIso8601String(),
      };

  Bill copyWith({int? id, bool? isPaid, DateTime? dueDate, String? firestoreId, String? userId, DateTime? updatedAt, bool? isSynced}) => Bill(
        id: id ?? this.id, firestoreId: firestoreId ?? this.firestoreId, userId: userId ?? this.userId,
        title: title, amount: amount, category: category,
        dueDate: dueDate ?? this.dueDate, repeat: repeat, isPaid: isPaid ?? this.isPaid,
        updatedAt: updatedAt ?? this.updatedAt, isSynced: isSynced ?? this.isSynced,
      );
}
