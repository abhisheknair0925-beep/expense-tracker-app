import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../services/database_service.dart';

/// Manages category budgets — CRUD + overspending checks.
class BudgetProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;
  List<Budget> _list = [];
  final int _month = DateTime.now().month;
  final int _year = DateTime.now().year;

  List<Budget> get budgets => _list;
  int get month => _month;
  int get year => _year;

  /// Get budget for a specific category this month.
  Budget? forCategory(String cat) {
    try { return _list.firstWhere((b) => b.category == cat && b.month == _month && b.year == _year); }
    catch (_) { return null; }
  }

  /// Check if a category is over budget. Returns (spent, limit, isOver).
  ({double spent, double limit, bool isOver})? checkOverspend(String cat, double spent) {
    final b = forCategory(cat);
    if (b == null) return null;
    return (spent: spent, limit: b.limit, isOver: spent > b.limit);
  }

  Future<void> load() async {
    _list = await _db.getBudgets();
    notifyListeners();
  }

  Future<void> add(Budget b) async {
    // Remove existing budget for same category/month
    final existing = _list.where((x) => x.category == b.category && x.month == b.month && x.year == b.year).toList();
    for (final e in existing) { await _db.deleteBudget(e.id!); }
    _list.removeWhere((x) => x.category == b.category && x.month == b.month && x.year == b.year);

    final id = await _db.insertBudget(b);
    _list.add(b.copyWith(id: id));
    notifyListeners();
  }

  Future<void> remove(int id) async {
    await _db.deleteBudget(id);
    _list.removeWhere((b) => b.id == id);
    notifyListeners();
  }
}
