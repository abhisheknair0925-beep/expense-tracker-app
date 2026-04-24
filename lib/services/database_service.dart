import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../core/constants/app_constants.dart';
import '../models/account_model.dart';
import '../models/bill_model.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';

/// SQLite CRUD service — offline-first, sync-ready.
class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();
  Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final p = join(await getDatabasesPath(), AppConstants.dbName);
    return openDatabase(p, version: AppConstants.dbVersion,
      onCreate: (db, v) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          await db.execute('ALTER TABLE ${AppConstants.tableTxn} ADD COLUMN accountId INTEGER');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ${AppConstants.tableAccounts} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              balance REAL NOT NULL DEFAULT 0
            )
          ''');
          await db.insert(AppConstants.tableAccounts, {'name': 'Cash', 'type': 'cash', 'balance': 0});
          await db.insert(AppConstants.tableAccounts, {'name': 'Bank Account', 'type': 'bank', 'balance': 0});
        }
        if (oldV < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ${AppConstants.tableBills} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              amount REAL NOT NULL,
              category TEXT NOT NULL,
              dueDate TEXT NOT NULL,
              repeat TEXT NOT NULL DEFAULT 'monthly',
              isPaid INTEGER NOT NULL DEFAULT 0
            )
          ''');
        }
        if (oldV < 4) {
          await db.execute('ALTER TABLE ${AppConstants.tableTxn} ADD COLUMN receiptPath TEXT');
        }
        if (oldV < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ${AppConstants.tableBudgets} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              category TEXT NOT NULL,
              budgetLimit REAL NOT NULL,
              month INTEGER NOT NULL,
              year INTEGER NOT NULL
            )
          ''');
        }
        if (oldV < 6) {
          // Add sync columns to all tables
          for (final t in [AppConstants.tableTxn, AppConstants.tableAccounts, AppConstants.tableBills, AppConstants.tableBudgets]) {
            await db.execute('ALTER TABLE $t ADD COLUMN firestoreId TEXT');
            await db.execute('ALTER TABLE $t ADD COLUMN userId TEXT');
            await db.execute('ALTER TABLE $t ADD COLUMN updatedAt TEXT');
            await db.execute('ALTER TABLE $t ADD COLUMN isSynced INTEGER NOT NULL DEFAULT 0');
          }
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableTxn} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firestoreId TEXT,
        userId TEXT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        accountId INTEGER,
        receiptPath TEXT,
        date TEXT NOT NULL,
        updatedAt TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE ${AppConstants.tableAccounts} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firestoreId TEXT,
        userId TEXT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0,
        updatedAt TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.insert(AppConstants.tableAccounts, {'name': 'Cash', 'type': 'cash', 'balance': 0, 'updatedAt': DateTime.now().toIso8601String(), 'isSynced': 0});
    await db.insert(AppConstants.tableAccounts, {'name': 'Bank Account', 'type': 'bank', 'balance': 0, 'updatedAt': DateTime.now().toIso8601String(), 'isSynced': 0});
    await db.execute('''
      CREATE TABLE ${AppConstants.tableBills} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firestoreId TEXT,
        userId TEXT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        repeat TEXT NOT NULL DEFAULT 'monthly',
        isPaid INTEGER NOT NULL DEFAULT 0,
        updatedAt TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE ${AppConstants.tableBudgets} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firestoreId TEXT,
        userId TEXT,
        category TEXT NOT NULL,
        budgetLimit REAL NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        updatedAt TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // ═══════════════════════════════════════════════════════════════════
  // TRANSACTIONS
  // ═══════════════════════════════════════════════════════════════════

  Future<int> insert(Txn t) async {
    final db = await database;
    return db.insert(AppConstants.tableTxn, t.toMap());
  }

  Future<List<Txn>> getAll() async {
    final db = await database;
    final rows = await db.query(AppConstants.tableTxn, orderBy: 'date DESC');
    return rows.map(Txn.fromMap).toList();
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete(AppConstants.tableTxn, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateTxn(Txn t) async {
    final db = await database;
    return db.update(AppConstants.tableTxn, t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<List<Txn>> getUnsyncedTxns() async {
    final db = await database;
    final rows = await db.query(AppConstants.tableTxn, where: 'isSynced = 0');
    return rows.map(Txn.fromMap).toList();
  }

  Future<Txn?> getTxnByFirestoreId(String fid) async {
    final db = await database;
    final rows = await db.query(AppConstants.tableTxn, where: 'firestoreId = ?', whereArgs: [fid]);
    return rows.isEmpty ? null : Txn.fromMap(rows.first);
  }

  // ═══════════════════════════════════════════════════════════════════
  // ACCOUNTS
  // ═══════════════════════════════════════════════════════════════════

  Future<int> insertAccount(Account a) async {
    final db = await database;
    return db.insert(AppConstants.tableAccounts, a.toMap());
  }

  Future<List<Account>> getAccounts() async {
    final db = await database;
    final rows = await db.query(AppConstants.tableAccounts);
    return rows.map(Account.fromMap).toList();
  }

  Future<int> updateAccount(Account a) async {
    final db = await database;
    return db.update(AppConstants.tableAccounts, a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  Future<int> deleteAccount(int id) async {
    final db = await database;
    return db.delete(AppConstants.tableAccounts, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Account>> getUnsyncedAccounts() async {
    final db = await database;
    final rows = await db.query(AppConstants.tableAccounts, where: 'isSynced = 0');
    return rows.map(Account.fromMap).toList();
  }

  Future<Account?> getAccountByFirestoreId(String fid) async {
    final db = await database;
    final rows = await db.query(AppConstants.tableAccounts, where: 'firestoreId = ?', whereArgs: [fid]);
    return rows.isEmpty ? null : Account.fromMap(rows.first);
  }

  // ═════════════════════════════════════════════════════════════════
  // BILLS
  // ═════════════════════════════════════════════════════════════════

  Future<int> insertBill(Bill b) async {
    final db = await database;
    return db.insert(AppConstants.tableBills, b.toMap());
  }

  Future<List<Bill>> getBills() async {
    final db = await database;
    final rows = await db.query(AppConstants.tableBills);
    return rows.map(Bill.fromMap).toList();
  }

  Future<int> updateBill(Bill b) async {
    final db = await database;
    return db.update(AppConstants.tableBills, b.toMap(), where: 'id = ?', whereArgs: [b.id]);
  }

  Future<int> deleteBill(int id) async {
    final db = await database;
    return db.delete(AppConstants.tableBills, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Bill>> getUnsyncedBills() async {
    final db = await database;
    final rows = await db.query(AppConstants.tableBills, where: 'isSynced = 0');
    return rows.map(Bill.fromMap).toList();
  }

  Future<Bill?> getBillByFirestoreId(String fid) async {
    final db = await database;
    final rows = await db.query(AppConstants.tableBills, where: 'firestoreId = ?', whereArgs: [fid]);
    return rows.isEmpty ? null : Bill.fromMap(rows.first);
  }

  // ═════════════════════════════════════════════════════════════════
  // BUDGETS
  // ═════════════════════════════════════════════════════════════════

  Future<int> insertBudget(Budget b) async {
    final db = await database;
    return db.insert(AppConstants.tableBudgets, b.toMap());
  }

  Future<List<Budget>> getBudgets() async {
    final db = await database;
    final rows = await db.query(AppConstants.tableBudgets);
    return rows.map(Budget.fromMap).toList();
  }

  Future<int> deleteBudget(int id) async {
    final db = await database;
    return db.delete(AppConstants.tableBudgets, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateBudget(Budget b) async {
    final db = await database;
    return db.update(AppConstants.tableBudgets, b.toMap(), where: 'id = ?', whereArgs: [b.id]);
  }

  Future<List<Budget>> getUnsyncedBudgets() async {
    final db = await database;
    final rows = await db.query(AppConstants.tableBudgets, where: 'isSynced = 0');
    return rows.map(Budget.fromMap).toList();
  }

  Future<Budget?> getBudgetByFirestoreId(String fid) async {
    final db = await database;
    final rows = await db.query(AppConstants.tableBudgets, where: 'firestoreId = ?', whereArgs: [fid]);
    return rows.isEmpty ? null : Budget.fromMap(rows.first);
  }
}
