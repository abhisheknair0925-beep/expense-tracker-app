import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';
import '../utils/formatters.dart';

/// Manages category budgets — CRUD + overspending checks.
class BudgetProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;
  List<Budget> _list = [];
  final int _month = DateTime.now().month;
  final int _year = DateTime.now().year;
  String? _profileId;

  BudgetProvider() {
    SyncService.instance.addListener(_onSyncChange);
  }

  void _onSyncChange() {
    if (!SyncService.instance.isSyncing) {
      load();
    }
  }

  @override
  void dispose() {
    SyncService.instance.removeListener(_onSyncChange);
    super.dispose();
  }

  List<Budget> get budgets => _list;
  int get month => _month;
  int get year => _year;
  String? get profileId => _profileId;

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

  Future<void> loadForProfile(String? profileId) async {
    _profileId = profileId;
    await load();
  }

  Future<void> load() async {
    _list = await _db.getBudgets(_profileId);
    notifyListeners();
  }

  Future<void> add(Budget b) async {
    // Remove existing budget for same category/month
    final existing = _list.where((x) => x.category == b.category && x.month == b.month && x.year == b.year).toList();
    for (final e in existing) { await _db.deleteBudget(e.id!); }
    _list.removeWhere((x) => x.category == b.category && x.month == b.month && x.year == b.year);

    final bWithProfile = b.copyWith(profileId: _profileId);
    final id = await _db.insertBudget(bWithProfile);
    final savedBudget = bWithProfile.copyWith(id: id);
    _list.add(savedBudget);
    notifyListeners();
    SyncService.instance.syncAll();

    // Check if new budget is already exceeded or near limit
    try {
      final txns = await _db.getAll(_profileId);
      final spent = txns
          .where((x) => !x.isIncome && x.category == savedBudget.category && x.date.month == savedBudget.month && x.date.year == savedBudget.year)
          .fold(0.0, (s, x) => s + x.amount);
      
      if (spent >= savedBudget.limit) {
        await NotificationService.instance.showNow(
          id: savedBudget.category.hashCode + savedBudget.month + savedBudget.year,
          title: '🚨 Budget Exceeded for ${savedBudget.category}',
          body: 'You have spent ${Fmt.money(spent)} which exceeds your new monthly limit of ${Fmt.money(savedBudget.limit)}.',
        );
      } else if (spent >= savedBudget.limit * 0.8) {
        await NotificationService.instance.showNow(
          id: savedBudget.category.hashCode + savedBudget.month + savedBudget.year + 1,
          title: '⚠️ 80% Budget Warning for ${savedBudget.category}',
          body: 'You have reached 80% of your new ${savedBudget.category} budget. Spent: ${Fmt.money(spent)} / Limit: ${Fmt.money(savedBudget.limit)}.',
        );
      }
    } catch (e) {
      debugPrint('Error checking budget on add: $e');
    }
  }

  Future<void> remove(int id) async {
    await _db.deleteBudget(id);
    _list.removeWhere((b) => b.id == id);
    notifyListeners();
    SyncService.instance.syncAll();
  }
}
