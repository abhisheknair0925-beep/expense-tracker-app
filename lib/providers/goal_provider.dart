import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

class GoalProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;
  List<Goal> _list = [];
  bool _loading = false;
  String? _profileId;

  List<Goal> get goals => _list;
  bool get loading => _loading;
  String? get profileId => _profileId;

  GoalProvider() {
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

  Future<void> loadForProfile(String? profileId) async {
    _profileId = profileId;
    await load();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _list = await _db.getGoals(_profileId);
    _loading = false;
    notifyListeners();
  }

  Future<void> add(Goal g) async {
    final gWithProfile = g.copyWith(profileId: _profileId, updatedAt: DateTime.now());
    final id = await _db.insertGoal(gWithProfile);
    _list.add(gWithProfile.copyWith(id: id));
    notifyListeners();
    SyncService.instance.syncAll();
  }

  Future<void> remove(int id) async {
    await _db.deleteGoal(id);
    _list.removeWhere((g) => g.id == id);
    notifyListeners();
    SyncService.instance.syncAll();
  }

  Future<void> fundGoal(int id, double amount) async {
    final i = _list.indexWhere((g) => g.id == id);
    if (i == -1) return;
    
    final current = _list[i];
    final newAmount = current.currentAmount + amount;
    final isCompleted = newAmount >= current.targetAmount;
    
    final updated = current.copyWith(
      currentAmount: newAmount,
      isCompleted: isCompleted,
      updatedAt: DateTime.now(),
      isSynced: false,
    );
    
    await _db.updateGoal(updated);
    _list[i] = updated;
    notifyListeners();
    SyncService.instance.syncAll();
  }
}
