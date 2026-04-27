import '../../../models/transaction_model.dart';
import 'package:collection/collection.dart';

class AnalyticsService {
  /// Compares two months and returns difference and percentage change.
  static Map<String, dynamic> compareMonths(List<Txn> current, List<Txn> previous) {
    final currentTotal = current.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final previousTotal = previous.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
    
    final diff = currentTotal - previousTotal;
    final percent = previousTotal == 0 ? 0.0 : (diff / previousTotal) * 100;
    
    return {
      'difference': diff,
      'percentage': percent,
      'currentTotal': currentTotal,
      'previousTotal': previousTotal,
    };
  }

  /// Calculates category breakdown and identifies top category.
  static Map<String, dynamic> getCategoryAnalysis(List<Txn> txns) {
    final expenses = txns.where((t) => !t.isIncome).toList();
    if (expenses.isEmpty) return {'breakdown': {}, 'topCategory': null, 'topPercent': 0.0};

    final total = expenses.fold(0.0, (s, t) => s + t.amount);
    final grouped = groupBy(expenses, (Txn t) => t.category);
    
    final breakdown = grouped.map((cat, list) {
      final catTotal = list.fold(0.0, (s, t) => s + t.amount);
      return MapEntry(cat, (catTotal / total) * 100);
    });

    final topEntry = breakdown.entries.sorted((a, b) => b.value.compareTo(a.value)).first;

    return {
      'breakdown': breakdown,
      'topCategory': topEntry.key,
      'topPercent': topEntry.value,
    };
  }

  /// Calculates daily average spending.
  static double getDailyAverage(List<Txn> txns, int month, int year) {
    final expenses = txns.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final today = DateTime.now();
    
    // If it's current month, divide by days passed so far
    final divisor = (today.month == month && today.year == year) ? today.day : daysInMonth;
    
    return expenses / (divisor == 0 ? 1 : divisor);
  }

  /// Identifies top merchants/vendors.
  static List<MapEntry<String, double>> getMerchantAnalysis(List<Txn> txns, {int limit = 5}) {
    final expenses = txns.where((t) => !t.isIncome).toList();
    final grouped = groupBy(expenses, (Txn t) => t.title.trim());
    
    final totals = grouped.map((name, list) {
      return MapEntry(name, list.fold(0.0, (s, t) => s + t.amount));
    });

    return totals.entries.sorted((a, b) => b.value.compareTo(a.value)).take(limit).toList();
  }
}
