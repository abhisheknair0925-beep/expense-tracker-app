import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../services/database_service.dart';

/// Manages account state — CRUD + balance adjustments.
class AccountProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;
  List<Account> _list = [];
  bool _loading = false;

  List<Account> get accounts => _list;
  bool get loading => _loading;
  double get totalBalance => _list.fold(0.0, (s, a) => s + a.balance);

  Account? getById(int id) {
    try { return _list.firstWhere((a) => a.id == id); }
    catch (_) { return null; }
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _list = await _db.getAccounts();
    _loading = false;
    notifyListeners();
  }

  Future<void> add(Account a) async {
    final id = await _db.insertAccount(a);
    _list.add(a.copyWith(id: id));
    notifyListeners();
  }

  Future<void> remove(int id) async {
    await _db.deleteAccount(id);
    _list.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  /// Adjust balance when a transaction is saved.
  Future<void> adjustBalance(int accountId, double amount, String type) async {
    final a = getById(accountId);
    if (a == null) return;
    final newBal = type == 'income' ? a.balance + amount : a.balance - amount;
    final updated = a.copyWith(balance: newBal);
    await _db.updateAccount(updated);
    final i = _list.indexWhere((x) => x.id == accountId);
    if (i != -1) _list[i] = updated;
    notifyListeners();
  }
}
