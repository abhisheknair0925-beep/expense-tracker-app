import 'package:flutter/material.dart';
import '../models/bill_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

/// Manages bill reminders state — CRUD + notification scheduling.
class BillProvider extends ChangeNotifier {
  final _db = DatabaseService.instance;
  final _notif = NotificationService.instance;
  List<Bill> _list = [];

  List<Bill> get bills => _list;
  List<Bill> get overdue => _list.where((b) => b.isOverdue).toList();
  List<Bill> get dueSoon => _list.where((b) => b.isDueSoon).toList();
  List<Bill> get unpaid => _list.where((b) => !b.isPaid).toList();
  double get totalUpcoming => unpaid.fold(0.0, (s, b) => s + b.amount);

  Future<void> load() async {
    _list = await _db.getBills();
    // Sort: overdue first, then by due date
    _list.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      if (a.isPaid && !b.isPaid) return 1;
      if (!a.isPaid && b.isPaid) return -1;
      return a.dueDate.compareTo(b.dueDate);
    });
    notifyListeners();
  }

  Future<void> add(Bill b) async {
    final id = await _db.insertBill(b);
    final bill = b.copyWith(id: id);
    _list.add(bill);
    // Schedule notification
    await _notif.scheduleBillReminder(
      id: id,
      title: '💰 Bill Reminder',
      body: '${b.title} — ₹${b.amount.toStringAsFixed(0)} is due',
      dueDate: b.dueDate,
    );
    notifyListeners();
  }

  Future<void> togglePaid(int id) async {
    final i = _list.indexWhere((b) => b.id == id);
    if (i == -1) return;
    final updated = _list[i].copyWith(isPaid: !_list[i].isPaid);
    await _db.updateBill(updated);
    _list[i] = updated;
    if (updated.isPaid) await _notif.cancel(id);
    notifyListeners();
  }

  Future<void> remove(int id) async {
    await _db.deleteBill(id);
    await _notif.cancel(id);
    _list.removeWhere((b) => b.id == id);
    notifyListeners();
  }
}
