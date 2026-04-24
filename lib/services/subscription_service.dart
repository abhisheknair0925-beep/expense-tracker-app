import '../models/transaction_model.dart';

/// Detects recurring payments from transaction history.
/// Pure rule-based — no AI, no APIs.
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  /// Detect recurring transactions that appear in 2+ months with similar amounts.
  List<DetectedSubscription> detect(List<Txn> all) {
    final expenses = all.where((t) => !t.isIncome).toList();
    final byTitle = <String, List<Txn>>{};

    // Group by normalized title
    for (final t in expenses) {
      final key = t.title.toLowerCase().trim();
      byTitle.putIfAbsent(key, () => []).add(t);
    }

    final subs = <DetectedSubscription>[];
    for (final entry in byTitle.entries) {
      if (entry.value.length < 2) continue;

      // Check if amounts are similar (within 10%)
      final amounts = entry.value.map((t) => t.amount).toList();
      final avg = amounts.reduce((a, b) => a + b) / amounts.length;
      final similar = amounts.every((a) => (a - avg).abs() / avg < 0.1);
      if (!similar) continue;

      // Check if they span 2+ distinct months
      final months = entry.value.map((t) => '${t.date.year}-${t.date.month}').toSet();
      if (months.length < 2) continue;

      final sorted = entry.value..sort((a, b) => b.date.compareTo(a.date));
      subs.add(DetectedSubscription(
        title: sorted.first.title,
        amount: avg,
        category: sorted.first.category,
        frequency: _guessFrequency(sorted),
        lastCharged: sorted.first.date,
        count: entry.value.length,
      ));
    }

    subs.sort((a, b) => b.amount.compareTo(a.amount));
    return subs;
  }

  String _guessFrequency(List<Txn> sorted) {
    if (sorted.length < 2) return 'unknown';
    final gaps = <int>[];
    for (int i = 0; i < sorted.length - 1; i++) {
      gaps.add(sorted[i].date.difference(sorted[i + 1].date).inDays);
    }
    final avgGap = gaps.reduce((a, b) => a + b) / gaps.length;
    if (avgGap < 10) return 'weekly';
    if (avgGap < 45) return 'monthly';
    if (avgGap < 100) return 'quarterly';
    return 'yearly';
  }
}

/// A detected subscription from spending patterns.
class DetectedSubscription {
  final String title;
  final double amount;
  final String category;
  final String frequency;
  final DateTime lastCharged;
  final int count;

  const DetectedSubscription({
    required this.title, required this.amount, required this.category,
    required this.frequency, required this.lastCharged, required this.count,
  });

  double get annualCost {
    switch (frequency) {
      case 'weekly': return amount * 52;
      case 'monthly': return amount * 12;
      case 'quarterly': return amount * 4;
      case 'yearly': return amount;
      default: return amount * 12;
    }
  }
}
