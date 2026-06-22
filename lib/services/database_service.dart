import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../core/constants/app_constants.dart';
import '../models/account_model.dart';
import '../models/bill_model.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../models/goal_model.dart';
import '../models/group_model.dart';
import '../models/group_expense_model.dart';

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
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
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
        if (oldV < 7) {
          // Add profileId column to all tables
          for (final t in [AppConstants.tableTxn, AppConstants.tableAccounts, AppConstants.tableBills, AppConstants.tableBudgets]) {
            await db.execute('ALTER TABLE $t ADD COLUMN profileId TEXT');
          }
        }
        if (oldV < 8) {
          // Re-create transactions table with FOREIGN KEY constraint
          await db.execute('ALTER TABLE ${AppConstants.tableTxn} RENAME TO old_${AppConstants.tableTxn}');
          
          await db.execute('''
            CREATE TABLE ${AppConstants.tableTxn} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              firestoreId TEXT,
              userId TEXT,
              profileId TEXT,
              title TEXT NOT NULL,
              amount REAL NOT NULL,
              type TEXT NOT NULL,
              category TEXT NOT NULL,
              accountId INTEGER,
              receiptPath TEXT,
              date TEXT NOT NULL,
              updatedAt TEXT,
              isSynced INTEGER NOT NULL DEFAULT 0,
              FOREIGN KEY (accountId) REFERENCES ${AppConstants.tableAccounts}(id) ON DELETE SET NULL
            )
          ''');
          
          // Copy data safely
          await db.execute('''
            INSERT INTO ${AppConstants.tableTxn} (id, firestoreId, userId, profileId, title, amount, type, category, accountId, receiptPath, date, updatedAt, isSynced)
            SELECT id, firestoreId, userId, profileId, title, amount, type, category, accountId, receiptPath, date, updatedAt, isSynced
            FROM old_${AppConstants.tableTxn}
          ''');
          
          await db.execute('DROP TABLE old_${AppConstants.tableTxn}');

          // Add foreign key composite query indexes
          await db.execute('CREATE INDEX IF NOT EXISTS idx_txn_profile_date ON ${AppConstants.tableTxn} (profileId, date DESC)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_txn_account ON ${AppConstants.tableTxn} (accountId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_budgets_profile ON ${AppConstants.tableBudgets} (profileId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_bills_profile ON ${AppConstants.tableBills} (profileId)');
        }
        if (oldV < 9) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ${AppConstants.tableGoals} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              firestoreId TEXT,
              userId TEXT,
              profileId TEXT,
              name TEXT NOT NULL,
              targetAmount REAL NOT NULL,
              currentAmount REAL DEFAULT 0,
              targetDate TEXT NOT NULL,
              category TEXT NOT NULL,
              isCompleted INTEGER NOT NULL DEFAULT 0,
              updatedAt TEXT,
              isSynced INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_goals_profile ON ${AppConstants.tableGoals} (profileId)');
        }
        if (oldV < 10) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ${AppConstants.tableGroups} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              firestoreId TEXT,
              userId TEXT,
              profileId TEXT,
              name TEXT NOT NULL,
              description TEXT,
              members TEXT NOT NULL,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL,
              isSynced INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ${AppConstants.tableGroupExpenses} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              firestoreId TEXT,
              groupId INTEGER NOT NULL,
              title TEXT NOT NULL,
              amount REAL NOT NULL,
              paidBy TEXT NOT NULL,
              date TEXT NOT NULL,
              splitType TEXT NOT NULL,
              splits TEXT NOT NULL,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL,
              isSynced INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_groups_profile ON ${AppConstants.tableGroups} (profileId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_group_expenses_group ON ${AppConstants.tableGroupExpenses} (groupId)');
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
        profileId TEXT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        accountId INTEGER,
        receiptPath TEXT,
        date TEXT NOT NULL,
        updatedAt TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (accountId) REFERENCES ${AppConstants.tableAccounts}(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE ${AppConstants.tableAccounts} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firestoreId TEXT,
        userId TEXT,
        profileId TEXT,
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
        profileId TEXT,
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
        profileId TEXT,
        category TEXT NOT NULL,
        budgetLimit REAL NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        updatedAt TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE ${AppConstants.tableGoals} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firestoreId TEXT,
        userId TEXT,
        profileId TEXT,
        name TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        currentAmount REAL DEFAULT 0,
        targetDate TEXT NOT NULL,
        category TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        updatedAt TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE ${AppConstants.tableGroups} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firestoreId TEXT,
        userId TEXT,
        profileId TEXT,
        name TEXT NOT NULL,
        description TEXT,
        members TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE ${AppConstants.tableGroupExpenses} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firestoreId TEXT,
        groupId INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        paidBy TEXT NOT NULL,
        date TEXT NOT NULL,
        splitType TEXT NOT NULL,
        splits TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create Indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_txn_profile_date ON ${AppConstants.tableTxn} (profileId, date DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_txn_account ON ${AppConstants.tableTxn} (accountId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_budgets_profile ON ${AppConstants.tableBudgets} (profileId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_bills_profile ON ${AppConstants.tableBills} (profileId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_goals_profile ON ${AppConstants.tableGoals} (profileId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_groups_profile ON ${AppConstants.tableGroups} (profileId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_group_expenses_group ON ${AppConstants.tableGroupExpenses} (groupId)');
  }

  // ═══════════════════════════════════════════════════════════════════
  // TRANSACTIONS
  // ═══════════════════════════════════════════════════════════════════

  Future<int> insert(Txn t) async {
    final db = await database;
    return await db.transaction((txn) async {
      final id = await txn.insert(AppConstants.tableTxn, t.toMap());
      if (t.accountId != null) {
        final adjustment = t.isIncome ? t.amount : -t.amount;
        await txn.rawUpdate('''
          UPDATE ${AppConstants.tableAccounts}
          SET balance = balance + ?, updatedAt = ?
          WHERE id = ?
        ''', [adjustment, DateTime.now().toIso8601String(), t.accountId]);
      }
      return id;
    });
  }

  Future<List<Txn>> getAll(String? profileId) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableTxn,
      where: profileId == null ? 'profileId IS NULL' : 'profileId = ?',
      whereArgs: profileId == null ? null : [profileId],
      orderBy: 'date DESC',
    );
    return rows.map(Txn.fromMap).toList();
  }

  Future<int> delete(int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      final rows = await txn.query(AppConstants.tableTxn, where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) {
        final t = Txn.fromMap(rows.first);
        if (t.accountId != null) {
          final adjustment = t.isIncome ? -t.amount : t.amount;
          await txn.rawUpdate('''
            UPDATE ${AppConstants.tableAccounts}
            SET balance = balance + ?, updatedAt = ?
            WHERE id = ?
          ''', [adjustment, DateTime.now().toIso8601String(), t.accountId]);
        }
      }
      return await txn.delete(AppConstants.tableTxn, where: 'id = ?', whereArgs: [id]);
    });
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

  Future<List<Account>> getAccounts(String? profileId) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableAccounts,
      where: profileId == null ? 'profileId IS NULL' : 'profileId = ?',
      whereArgs: profileId == null ? null : [profileId],
    );
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

  Future<List<Bill>> getBills(String? profileId) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableBills,
      where: profileId == null ? 'profileId IS NULL' : 'profileId = ?',
      whereArgs: profileId == null ? null : [profileId],
    );
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

  Future<List<Budget>> getBudgets(String? profileId) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableBudgets,
      where: profileId == null ? 'profileId IS NULL' : 'profileId = ?',
      whereArgs: profileId == null ? null : [profileId],
    );
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

  // ═════════════════════════════════════════════════════════════════
  // GOALS
  // ═════════════════════════════════════════════════════════════════

  Future<int> insertGoal(Goal g) async {
    final db = await database;
    return db.insert(AppConstants.tableGoals, g.toMap());
  }

  Future<List<Goal>> getGoals(String? profileId) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableGoals,
      where: profileId == null ? 'profileId IS NULL' : 'profileId = ?',
      whereArgs: profileId == null ? null : [profileId],
      orderBy: 'targetDate ASC',
    );
    return rows.map(Goal.fromMap).toList();
  }

  Future<int> deleteGoal(int id) async {
    final db = await database;
    return db.delete(AppConstants.tableGoals, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateGoal(Goal g) async {
    final db = await database;
    return db.update(AppConstants.tableGoals, g.toMap(), where: 'id = ?', whereArgs: [g.id]);
  }

  Future<List<Goal>> getUnsyncedGoals() async {
    final db = await database;
    final rows = await db.query(AppConstants.tableGoals, where: 'isSynced = 0');
    return rows.map(Goal.fromMap).toList();
  }

  Future<Goal?> getGoalByFirestoreId(String fid) async {
    final db = await database;
    final rows = await db.query(AppConstants.tableGoals, where: 'firestoreId = ?', whereArgs: [fid]);
    return rows.isEmpty ? null : Goal.fromMap(rows.first);
  }

  // GROUPS
  Future<int> insertGroup(Group g) async {
    final db = await database;
    return db.insert(AppConstants.tableGroups, g.toMap());
  }

  Future<List<Group>> getGroups(String? profileId) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableGroups,
      where: profileId == null ? 'profileId IS NULL' : 'profileId = ?',
      whereArgs: profileId == null ? null : [profileId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(Group.fromMap).toList();
  }

  Future<int> deleteGroup(int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      await txn.delete(AppConstants.tableGroupExpenses, where: 'groupId = ?', whereArgs: [id]);
      return await txn.delete(AppConstants.tableGroups, where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<int> updateGroup(Group g) async {
    final db = await database;
    return db.update(AppConstants.tableGroups, g.toMap(), where: 'id = ?', whereArgs: [g.id]);
  }

  Future<List<Group>> getUnsyncedGroups() async {
    final db = await database;
    final rows = await db.query(AppConstants.tableGroups, where: 'isSynced = 0');
    return rows.map(Group.fromMap).toList();
  }

  Future<Group?> getGroupByFirestoreId(String fid) async {
    final db = await database;
    final rows = await db.query(AppConstants.tableGroups, where: 'firestoreId = ?', whereArgs: [fid]);
    return rows.isEmpty ? null : Group.fromMap(rows.first);
  }

  // GROUP EXPENSES
  Future<int> insertGroupExpense(GroupExpense ge) async {
    final db = await database;
    return db.insert(AppConstants.tableGroupExpenses, ge.toMap());
  }

  Future<List<GroupExpense>> getGroupExpenses(int groupId) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableGroupExpenses,
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'date DESC',
    );
    return rows.map(GroupExpense.fromMap).toList();
  }

  Future<int> deleteGroupExpense(int id) async {
    final db = await database;
    return db.delete(AppConstants.tableGroupExpenses, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateGroupExpense(GroupExpense ge) async {
    final db = await database;
    return db.update(AppConstants.tableGroupExpenses, ge.toMap(), where: 'id = ?', whereArgs: [ge.id]);
  }

  Future<List<GroupExpense>> getUnsyncedGroupExpenses() async {
    final db = await database;
    final rows = await db.query(AppConstants.tableGroupExpenses, where: 'isSynced = 0');
    return rows.map(GroupExpense.fromMap).toList();
  }

  Future<GroupExpense?> getGroupExpenseByFirestoreId(String fid) async {
    final db = await database;
    final rows = await db.query(AppConstants.tableGroupExpenses, where: 'firestoreId = ?', whereArgs: [fid]);
    return rows.isEmpty ? null : GroupExpense.fromMap(rows.first);
  }
}
