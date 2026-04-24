import 'package:flutter/foundation.dart';
import '../models/account_model.dart';
import '../models/bill_model.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'firestore_service.dart';

/// Bi-directional sync engine — SQLite ↔ Firestore.
///
/// Strategy:
/// - SQLite = primary (offline-first)
/// - Firestore = cloud backup
/// - Conflict resolution: last updatedAt wins
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _db = DatabaseService.instance;
  final _fs = FirestoreService.instance;

  bool _syncing = false;
  bool get isSyncing => _syncing;

  String? get _uid => AuthService.instance.uid;

  /// Full sync — upload unsynced + download new from cloud.
  Future<void> syncAll() async {
    if (_uid == null || _syncing) return;
    _syncing = true;
    debugPrint('SyncService: Starting full sync for $_uid');

    try {
      await _uploadAll();
      await _downloadAll();
      debugPrint('SyncService: Sync complete');
    } catch (e) {
      debugPrint('SyncService: Sync error: $e');
    } finally {
      _syncing = false;
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

  // ═══════════════════════════════════════════════════════════════════
  // DOWNLOAD — pull cloud data, merge with SQLite (last-write-wins)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _downloadAll() async {
    await _downloadTransactions();
    await _downloadAccounts();
    await _downloadBills();
    await _downloadBudgets();
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
          name: data['name'] as String,
          type: data['type'] as String,
          balance: (data['balance'] as num).toDouble(),
          updatedAt: remoteUpdated, isSynced: true,
        ));
        merged++;
      } else if (remoteUpdated.isAfter(local.updatedAt)) {
        await _db.updateAccount(Account(
          id: local.id, firestoreId: fid, userId: _uid,
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

  /// Sync status text for UI.
  String get statusText {
    if (_uid == null) return 'Not signed in';
    if (_syncing) return 'Syncing...';
    return 'Connected';
  }
}
