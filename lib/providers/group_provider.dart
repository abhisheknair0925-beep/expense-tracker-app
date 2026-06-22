import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../models/group_expense_model.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

class _MemberBalance {
  final String name;
  double balance;
  _MemberBalance(this.name, this.balance);
}

class GroupProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;
  List<Group> _groups = [];
  final Map<int, List<GroupExpense>> _groupExpenses = {};
  bool _loading = false;
  String? _profileId;

  List<Group> get groups => _groups;
  bool get loading => _loading;
  String? get profileId => _profileId;

  GroupProvider() {
    SyncService.instance.addListener(_onSyncChange);
  }

  void _onSyncChange() {
    if (!SyncService.instance.isSyncing) {
      loadGroups();
    }
  }

  @override
  void dispose() {
    SyncService.instance.removeListener(_onSyncChange);
    super.dispose();
  }

  List<GroupExpense> expensesForGroup(int groupId) => _groupExpenses[groupId] ?? [];

  Future<void> loadForProfile(String? profileId) async {
    _profileId = profileId;
    await loadGroups();
  }

  Future<void> loadGroups() async {
    _loading = true;
    notifyListeners();
    _groups = await _db.getGroups(_profileId);
    _groupExpenses.clear();
    for (final g in _groups) {
      if (g.id != null) {
        _groupExpenses[g.id!] = await _db.getGroupExpenses(g.id!);
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> addGroup(Group g) async {
    final gWithProfile = g.copyWith(profileId: _profileId, updatedAt: DateTime.now());
    final id = await _db.insertGroup(gWithProfile);
    _groups.insert(0, gWithProfile.copyWith(id: id));
    _groupExpenses[id] = [];
    notifyListeners();
    SyncService.instance.syncAll();
  }

  Future<void> removeGroup(int id) async {
    await _db.deleteGroup(id);
    _groups.removeWhere((g) => g.id == id);
    _groupExpenses.remove(id);
    notifyListeners();
    SyncService.instance.syncAll();
  }

  Future<void> updateGroup(Group g) async {
    final updated = g.copyWith(updatedAt: DateTime.now(), isSynced: false);
    await _db.updateGroup(updated);
    final idx = _groups.indexWhere((x) => x.id == g.id);
    if (idx != -1) {
      _groups[idx] = updated;
    }
    notifyListeners();
    SyncService.instance.syncAll();
  }

  Future<void> addExpense(GroupExpense ge) async {
    final geWithUpdate = ge.copyWith(updatedAt: DateTime.now());
    final id = await _db.insertGroupExpense(geWithUpdate);
    final saved = geWithUpdate.copyWith(id: id);
    if (!_groupExpenses.containsKey(ge.groupId)) {
      _groupExpenses[ge.groupId] = [];
    }
    _groupExpenses[ge.groupId]!.insert(0, saved);
    notifyListeners();
    SyncService.instance.syncAll();
  }

  Future<void> removeExpense(int expenseId, int groupId) async {
    await _db.deleteGroupExpense(expenseId);
    if (_groupExpenses.containsKey(groupId)) {
      _groupExpenses[groupId]!.removeWhere((ge) => ge.id == expenseId);
    }
    notifyListeners();
    SyncService.instance.syncAll();
  }

  /// Calculate the net balance for each member in the group.
  Map<String, double> getNetBalances(Group group) {
    final expenses = expensesForGroup(group.id ?? -1);
    final balances = <String, double>{};
    for (final m in group.members) {
      balances[m] = 0.0;
    }

    for (final exp in expenses) {
      final paidBy = exp.paidBy;
      if (balances.containsKey(paidBy)) {
        balances[paidBy] = balances[paidBy]! + exp.amount;
      }
      
      exp.splits.forEach((member, owedAmount) {
        if (balances.containsKey(member)) {
          balances[member] = balances[member]! - owedAmount;
        }
      });
    }
    return balances;
  }

  /// Simplify debt settlements using Splitwise matching strategy.
  List<({String from, String to, double amount})> getSettlements(Group group) {
    final balances = getNetBalances(group);
    final debtors = <_MemberBalance>[];
    final creditors = <_MemberBalance>[];

    balances.forEach((member, bal) {
      if (bal < -0.01) {
        debtors.add(_MemberBalance(member, bal));
      } else if (bal > 0.01) {
        creditors.add(_MemberBalance(member, bal));
      }
    });

    debtors.sort((a, b) => a.balance.compareTo(b.balance));
    creditors.sort((a, b) => b.balance.compareTo(a.balance));

    final settlements = <({String from, String to, double amount})>[];
    int dIdx = 0;
    int cIdx = 0;

    while (dIdx < debtors.length && cIdx < creditors.length) {
      final debtor = debtors[dIdx];
      final creditor = creditors[cIdx];

      final dOwed = -debtor.balance;
      final cOwed = creditor.balance;
      
      final amount = dOwed < cOwed ? dOwed : cOwed;

      settlements.add((from: debtor.name, to: creditor.name, amount: amount));

      debtor.balance += amount;
      creditor.balance -= amount;

      if (debtor.balance.abs() < 0.01) {
        dIdx++;
      }
      if (creditor.balance.abs() < 0.01) {
        cIdx++;
      }
    }

    return settlements;
  }
}
