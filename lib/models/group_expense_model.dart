import 'dart:convert';

class GroupExpense {
  final int? id;
  final String? firestoreId;
  final int groupId;
  final String title;
  final double amount;
  final String paidBy;
  final DateTime date;
  final String splitType; // 'equal', 'unequal', 'percentage'
  final Map<String, double> splits; // memberName -> amountOwed
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  GroupExpense({
    this.id,
    this.firestoreId,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.date,
    required this.splitType,
    required this.splits,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'firestoreId': firestoreId,
      'groupId': groupId,
      'title': title,
      'amount': amount,
      'paidBy': paidBy,
      'date': date.toIso8601String(),
      'splitType': splitType,
      'splits': json.encode(splits),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'firestoreId': firestoreId,
      'groupId': groupId,
      'title': title,
      'amount': amount,
      'paidBy': paidBy,
      'date': date.toIso8601String(),
      'splitType': splitType,
      'splits': splits,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GroupExpense.fromMap(Map<String, dynamic> map) {
    final splitsRaw = map['splits'];
    Map<String, double> splitsMap = {};
    if (splitsRaw is String) {
      final decoded = json.decode(splitsRaw) as Map<String, dynamic>;
      splitsMap = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } else if (splitsRaw is Map) {
      splitsMap = splitsRaw.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    }

    return GroupExpense(
      id: map['id'],
      firestoreId: map['firestoreId'],
      groupId: map['groupId'] ?? 0,
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paidBy: map['paidBy'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      splitType: map['splitType'] ?? 'equal',
      splits: splitsMap,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
      isSynced: map['isSynced'] == 1 || map['isSynced'] == true,
    );
  }

  GroupExpense copyWith({
    int? id,
    String? firestoreId,
    int? groupId,
    String? title,
    double? amount,
    String? paidBy,
    DateTime? date,
    String? splitType,
    Map<String, double>? splits,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return GroupExpense(
      id: id ?? this.id,
      firestoreId: firestoreId ?? this.firestoreId,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      paidBy: paidBy ?? this.paidBy,
      date: date ?? this.date,
      splitType: splitType ?? this.splitType,
      splits: splits ?? this.splits,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
