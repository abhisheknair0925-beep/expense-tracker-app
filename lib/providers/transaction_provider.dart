import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';

/// Manages all transaction state — list, totals, analytics.
class TransactionProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;

  List<Txn> _all = [];
  bool _loading = false;
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;

  List<Txn> get all => _all;
  bool get loading => _loading;
  int get month => _month;
  int get year => _year;

  // ─── Search & Filter state ────────────────────────────────────────
  String _search = '';
  String _filter = 'All';
  String get search => _search;
  String get filter => _filter;

  void setSearch(String q) { _search = q; notifyListeners(); }
  void setFilter(String f) { _filter = f; notifyListeners(); }

  /// Filtered transactions for the History tab (combines search + filter + month).
  List<Txn> get filtered {
    var list = monthly;
    if (_filter == 'Income') list = list.where((t) => t.isIncome).toList();
    if (_filter == 'Expense') list = list.where((t) => !t.isIncome).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((t) => t.title.toLowerCase().contains(q) || t.category.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  /// Transactions for the selected month.
  List<Txn> get monthly => _all
      .where((t) => t.date.month == _month && t.date.year == _year)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  double get income =>
      monthly.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);

  double get expense =>
      monthly.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);

  double get balance => income - expense;

  /// Recent 5 transactions this month.
  List<Txn> get recent => monthly.take(5).toList();

  /// Category-wise expense totals (sorted descending).
  Map<String, double> get catExpenses {
    final m = <String, double>{};
    for (final t in monthly.where((t) => !t.isIncome)) {
      m[t.category] = (m[t.category] ?? 0) + t.amount;
    }
    final sorted = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  /// Monthly totals for the full year (bar chart data).
  List<({int month, double income, double expense})> get yearlyTrend {
    return List.generate(12, (i) {
      final m = i + 1;
      final txns = _all.where((t) => t.date.month == m && t.date.year == _year);
      return (
        month: m,
        income: txns.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount),
        expense: txns.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount),
      );
    });
  }

  // ─── Actions ──────────────────────────────────────────────────────

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _all = await _db.getAll();
    _loading = false;
    notifyListeners();
  }

  Future<void> add(Txn t) async {
    final id = await _db.insert(t);
    _all.insert(0, t.copyWith(id: id));
    notifyListeners();
  }

  Future<void> remove(int id) async {
    await _db.delete(id);
    _all.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void prevMonth() {
    if (_month == 1) { _month = 12; _year--; } else { _month--; }
    notifyListeners();
  }

  void nextMonth() {
    if (_month == 12) { _month = 1; _year++; } else { _month++; }
    notifyListeners();
  }
}
