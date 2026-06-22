import 'package:flutter/foundation.dart';
import '../models/account_model.dart';
import '../models/bill_model.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';
import '../models/group_model.dart';
import '../models/group_expense_model.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'firestore_service.dart';

/// Bi-directional sync engine — SQLite ↔ Firestore.
///
/// Strategy:
/// - SQLite = primary (offline-first)
/// - Firestore = cloud backup
/// - Conflict resolution: last updatedAt wins
class SyncService extends ChangeNotifier {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _db = DatabaseService.instance;
  final _fs = FirestoreService.instance;

  bool _syncing = false;
  bool get isSyncing => _syncing;

  String? _lastError;
  String? get lastError => _lastError;

  String? get _uid => AuthService.instance.uid;

  /// Full sync — upload unsynced + download new from cloud.
  Future<void> syncAll() async {
    if (_uid == null || _syncing) return;
    _syncing = true;
    _lastError = null;
    notifyListeners();
    debugPrint('SyncService: Starting full sync for $_uid');

    try {
      await _uploadAll();
      await _downloadAll();
      debugPrint('SyncService: Sync complete');
    } catch (e) {
      _lastError = e.toString();
      debugPrint('SyncService: Sync error: $e');
      if (_lastError!.contains('firestore.googleapis.com')) {
        _lastError = 'Firestore API not enabled. Please enable it in Firebase Console.';
      }
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // UPLOAD — push unsynced local data to Firestore
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _uploadAll() async {
    await _uploadTransactions();
    await _uploadAccounts();
    await _uploadBills();
    await _uploadBudgets();
    await _uploadGoals();
    await _uploadGroups();
    await _uploadGroupExpenses();
  }

  Future<void> _uploadTransactions() async {
    final unsynced = await _db.getUnsyncedTxns();
    for (final t in unsynced) {
      final fid = await _fs.upsert(_uid!, 'transactions', t.firestoreId, t.toFirestore());
      await _db.updateTxn(t.copyWith(firestoreId: fid, userId: _uid, isSynced: true));
    }
    debugPrint('SyncService: Uploaded ${unsynced.length} transactions');
  }

  Future<void> _uploadAccounts() async {
    final unsynced = await _db.getUnsyncedAccounts();
    for (final a in unsynced) {
      final fid = await _fs.upsert(_uid!, 'accounts', a.firestoreId, a.toFirestore());
      await _db.updateAccount(a.copyWith(firestoreId: fid, userId: _uid, isSynced: true));
    }
    debugPrint('SyncService: Uploaded ${unsynced.length} accounts');
  }

  Future<void> _uploadBills() async {
    final unsynced = await _db.getUnsyncedBills();
    for (final b in unsynced) {
      final fid = await _fs.upsert(_uid!, 'bills', b.firestoreId, b.toFirestore());
      await _db.updateBill(b.copyWith(firestoreId: fid, userId: _uid, isSynced: true));
    }
    debugPrint('SyncService: Uploaded ${unsynced.length} bills');
  }

  Future<void> _uploadBudgets() async {
    final unsynced = await _db.getUnsyncedBudgets();
    for (final b in unsynced) {
      final fid = await _fs.upsert(_uid!, 'budgets', b.firestoreId, b.toFirestore());
      await _db.updateBudget(b.copyWith(firestoreId: fid, userId: _uid, isSynced: true));
    }
    debugPrint('SyncService: Uploaded ${unsynced.length} budgets');
  }

  Future<void> _uploadGoals() async {
    final unsynced = await _db.getUnsyncedGoals();
    for (final g in unsynced) {
      final fid = await _fs.upsert(_uid!, 'goals', g.firestoreId, g.toFirestore());
      await _db.updateGoal(g.copyWith(firestoreId: fid, userId: _uid, isSynced: true));
    }
    debugPrint('SyncService: Uploaded ${unsynced.length} goals');
  }

  // ═══════════════════════════════════════════════════════════════════
  // DOWNLOAD — pull cloud data, merge with SQLite (last-write-wins)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _downloadAll() async {
    await _downloadTransactions();
    await _downloadAccounts();
    await _downloadBills();
    await _downloadBudgets();
    await _downloadGoals();
    await _downloadGroups();
    await _downloadGroupExpenses();
  }

  Future<void> _downloadTransactions() async {
    final remote = await _fs.getAll(_uid!, 'transactions');
    int merged = 0;
    for (final data in remote) {
      final fid = data['firestoreId'] as String;
      final local = await _db.getTxnByFirestoreId(fid);
      final remoteUpdated = DateTime.parse(data['updatedAt'] as String);

      if (local == null) {
        // New from cloud — insert locally
        await _db.insert(Txn(
          firestoreId: fid, userId: _uid,
          profileId: data['profileId'] as String?,
          title: data['title'] as String,
          amount: (data['amount'] as num).toDouble(),
          type: data['type'] as String,
          category: data['category'] as String,
          receiptPath: data['receiptPath'] as String?,
          date: DateTime.parse(data['date'] as String),
          updatedAt: remoteUpdated,
          isSynced: true,
        ));
        merged++;
      } else if (remoteUpdated.isAfter(local.updatedAt)) {
        // Cloud is newer — update local
        await _db.updateTxn(Txn(
          id: local.id, firestoreId: fid, userId: _uid,
          profileId: data['profileId'] as String?,
          title: data['title'] as String,
          amount: (data['amount'] as num).toDouble(),
          type: data['type'] as String,
          category: data['category'] as String,
          accountId: local.accountId,
          receiptPath: data['receiptPath'] as String?,
          date: DateTime.parse(data['date'] as String),
          updatedAt: remoteUpdated,
          isSynced: true,
        ));
        merged++;
      }
    }
    debugPrint('SyncService: Downloaded/merged $merged transactions');
  }

  Future<void> _downloadAccounts() async {
    final remote = await _fs.getAll(_uid!, 'accounts');
    int merged = 0;
    for (final data in remote) {
      final fid = data['firestoreId'] as String;
      final local = await _db.getAccountByFirestoreId(fid);
      final remoteUpdated = DateTime.parse(data['updatedAt'] as String);

      if (local == null) {
        await _db.insertAccount(Account(
          firestoreId: fid, userId: _uid,
          profileId: data['profileId'] as String?,
          name: data['name'] as String,
          type: data['type'] as String,
          balance: (data['balance'] as num).toDouble(),
          updatedAt: remoteUpdated, isSynced: true,
        ));
        merged++;
      } else if (remoteUpdated.isAfter(local.updatedAt)) {
        await _db.updateAccount(Account(
          id: local.id, firestoreId: fid, userId: _uid,
          profileId: data['profileId'] as String?,
          name: data['name'] as String,
          type: data['type'] as String,
          balance: (data['balance'] as num).toDouble(),
          updatedAt: remoteUpdated, isSynced: true,
        ));
        merged++;
      }
    }
    debugPrint('SyncService: Downloaded/merged $merged accounts');
  }

  Future<void> _downloadBills() async {
    final remote = await _fs.getAll(_uid!, 'bills');
    int merged = 0;
    for (final data in remote) {
      final fid = data['firestoreId'] as String;
      final local = await _db.getBillByFirestoreId(fid);
      final remoteUpdated = DateTime.parse(data['updatedAt'] as String);

      if (local == null) {
        await _db.insertBill(Bill(
          firestoreId: fid, userId: _uid,
          profileId: data['profileId'] as String?,
          title: data['title'] as String,
          amount: (data['amount'] as num).toDouble(),
          category: data['category'] as String,
          dueDate: DateTime.parse(data['dueDate'] as String),
          repeat: data['repeat'] as String? ?? 'monthly',
          isPaid: data['isPaid'] == true || data['isPaid'] == 1,
          updatedAt: remoteUpdated, isSynced: true,
        ));
        merged++;
      } else if (remoteUpdated.isAfter(local.updatedAt)) {
        await _db.updateBill(Bill(
          id: local.id, firestoreId: fid, userId: _uid,
          profileId: data['profileId'] as String?,
          title: data['title'] as String,
          amount: (data['amount'] as num).toDouble(),
          category: data['category'] as String,
          dueDate: DateTime.parse(data['dueDate'] as String),
          repeat: data['repeat'] as String? ?? 'monthly',
          isPaid: data['isPaid'] == true || data['isPaid'] == 1,
          updatedAt: remoteUpdated, isSynced: true,
        ));
        merged++;
      }
    }
    debugPrint('SyncService: Downloaded/merged $merged bills');
  }

  Future<void> _downloadBudgets() async {
    final remote = await _fs.getAll(_uid!, 'budgets');
    int merged = 0;
    for (final data in remote) {
      final fid = data['firestoreId'] as String;
      final local = await _db.getBudgetByFirestoreId(fid);
      final remoteUpdated = DateTime.parse(data['updatedAt'] as String);

      if (local == null) {
        await _db.insertBudget(Budget(
          firestoreId: fid, userId: _uid,
          profileId: data['profileId'] as String?,
          category: data['category'] as String,
          limit: (data['budgetLimit'] as num).toDouble(),
          month: data['month'] as int,
          year: data['year'] as int,
          updatedAt: remoteUpdated, isSynced: true,
        ));
        merged++;
      } else if (remoteUpdated.isAfter(local.updatedAt)) {
        await _db.updateBudget(Budget(
          id: local.id, firestoreId: fid, userId: _uid,
          profileId: data['profileId'] as String?,
          category: data['category'] as String,
          limit: (data['budgetLimit'] as num).toDouble(),
          month: data['month'] as int,
          year: data['year'] as int,
          updatedAt: remoteUpdated, isSynced: true,
        ));
        merged++;
      }
    }
    debugPrint('SyncService: Downloaded/merged $merged budgets');
  }

  Future<void> _downloadGoals() async {
    final remote = await _fs.getAll(_uid!, 'goals');
    int merged = 0;
    for (final data in remote) {
      final fid = data['firestoreId'] as String;
      final local = await _db.getGoalByFirestoreId(fid);
      final remoteUpdated = DateTime.parse(data['updatedAt'] as String);

      if (local == null) {
        await _db.insertGoal(Goal(
          firestoreId: fid, userId: _uid,
          profileId: data['profileId'] as String?,
          name: data['name'] as String,
          targetAmount: (data['targetAmount'] as num).toDouble(),
          currentAmount: (data['currentAmount'] as num).toDouble(),
          targetDate: DateTime.parse(data['targetDate'] as String),
          category: data['category'] as String,
          isCompleted: data['isCompleted'] == true || data['isCompleted'] == 1,
          updatedAt: remoteUpdated, isSynced: true,
        ));
        merged++;
      } else if (remoteUpdated.isAfter(local.updatedAt)) {
        await _db.updateGoal(Goal(
          id: local.id, firestoreId: fid, userId: _uid,
          profileId: data['profileId'] as String?,
          name: data['name'] as String,
          targetAmount: (data['targetAmount'] as num).toDouble(),
          currentAmount: (data['currentAmount'] as num).toDouble(),
          targetDate: DateTime.parse(data['targetDate'] as String),
          category: data['category'] as String,
          isCompleted: data['isCompleted'] == true || data['isCompleted'] == 1,
          updatedAt: remoteUpdated, isSynced: true,
        ));
        merged++;
      }
    }
    debugPrint('SyncService: Downloaded/merged $merged goals');
  }

  Future<void> _uploadGroups() async {
    final unsynced = await _db.getUnsyncedGroups();
    for (final g in unsynced) {
      final fid = await _fs.upsert(_uid!, 'groups', g.firestoreId, g.toFirestore());
      await _db.updateGroup(g.copyWith(firestoreId: fid, userId: _uid, isSynced: true));
    }
    debugPrint('SyncService: Uploaded ${unsynced.length} groups');
  }

  Future<void> _uploadGroupExpenses() async {
    final unsynced = await _db.getUnsyncedGroupExpenses();
    for (final ge in unsynced) {
      final fid = await _fs.upsert(_uid!, 'group_expenses', ge.firestoreId, ge.toFirestore());
      await _db.updateGroupExpense(ge.copyWith(firestoreId: fid, isSynced: true));
    }
    debugPrint('SyncService: Uploaded ${unsynced.length} group expenses');
  }

  Future<void> _downloadGroups() async {
    final remote = await _fs.getAll(_uid!, 'groups');
    int merged = 0;
    for (final data in remote) {
      final fid = data['firestoreId'] as String;
      final local = await _db.getGroupByFirestoreId(fid);
      final remoteUpdated = DateTime.parse(data['updatedAt'] as String);

      if (local == null) {
        await _db.insertGroup(Group(
          firestoreId: fid,
          userId: _uid,
          profileId: data['profileId'] as String?,
          name: data['name'] as String,
          description: data['description'] as String?,
          members: List<String>.from(data['members'] as List),
          createdAt: DateTime.parse(data['createdAt'] as String),
          updatedAt: remoteUpdated,
          isSynced: true,
        ));
        merged++;
      } else if (remoteUpdated.isAfter(local.updatedAt)) {
        await _db.updateGroup(Group(
          id: local.id,
          firestoreId: fid,
          userId: _uid,
          profileId: data['profileId'] as String?,
          name: data['name'] as String,
          description: data['description'] as String?,
          members: List<String>.from(data['members'] as List),
          createdAt: DateTime.parse(data['createdAt'] as String),
          updatedAt: remoteUpdated,
          isSynced: true,
        ));
        merged++;
      }
    }
    debugPrint('SyncService: Downloaded/merged $merged groups');
  }

  Future<void> _downloadGroupExpenses() async {
    final remote = await _fs.getAll(_uid!, 'group_expenses');
    int merged = 0;
    for (final data in remote) {
      final fid = data['firestoreId'] as String;
      final local = await _db.getGroupExpenseByFirestoreId(fid);
      final remoteUpdated = DateTime.parse(data['updatedAt'] as String);

      if (local == null) {
        final rawSplits = data['splits'] as Map<String, dynamic>;
        final splits = rawSplits.map((k, v) => MapEntry(k, (v as num).toDouble()));

        await _db.insertGroupExpense(GroupExpense(
          firestoreId: fid,
          groupId: data['groupId'] as int,
          title: data['title'] as String,
          amount: (data['amount'] as num).toDouble(),
          paidBy: data['paidBy'] as String,
          date: DateTime.parse(data['date'] as String),
          splitType: data['splitType'] as String,
          splits: splits,
          createdAt: DateTime.parse(data['createdAt'] as String),
          updatedAt: remoteUpdated,
          isSynced: true,
        ));
        merged++;
      } else if (remoteUpdated.isAfter(local.updatedAt)) {
        final rawSplits = data['splits'] as Map<String, dynamic>;
        final splits = rawSplits.map((k, v) => MapEntry(k, (v as num).toDouble()));

        await _db.updateGroupExpense(GroupExpense(
          id: local.id,
          firestoreId: fid,
          groupId: data['groupId'] as int,
          title: data['title'] as String,
          amount: (data['amount'] as num).toDouble(),
          paidBy: data['paidBy'] as String,
          date: DateTime.parse(data['date'] as String),
          splitType: data['splitType'] as String,
          splits: splits,
          createdAt: DateTime.parse(data['createdAt'] as String),
          updatedAt: remoteUpdated,
          isSynced: true,
        ));
        merged++;
      }
    }
    debugPrint('SyncService: Downloaded/merged $merged group expenses');
  }

  /// Sync status text for UI.
  String get statusText {
    if (_uid == null) return 'Not signed in';
    if (_syncing) return 'Syncing...';
    if (_lastError != null) return _lastError!;
    return 'Connected';
  }
}
