import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/transaction_provider.dart';
import '../utils/formatters.dart';
import '../widgets/glass_card.dart';

/// Rule-based financial insights screen.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, p, _) {
        final insights = _build(p);
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text('Smart Insights', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
            )),
            // AI header
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GlassCard(
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Finance Assistant', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                    Text('Personalized tips based on your spending', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
                  ])),
                ]),
              ),
            )),
            if (insights.isEmpty)
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.textMuted, size: 56),
                  const SizedBox(height: 12),
                  Text('No insights yet', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('Add more transactions for tips', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12)),
                ]),
              ))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (ctx, i) => insights[i],
                  childCount: insights.length,
                )),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  /// Generate rule-based insights from transaction data.
  List<Widget> _build(TransactionProvider p) {
    final list = <Widget>[];
    if (p.monthly.isEmpty) return list;

    // 1. Top spending category
    if (p.catExpenses.isNotEmpty) {
      final top = p.catExpenses.entries.first;
      final pct = p.expense > 0 ? (top.value / p.expense * 100).toStringAsFixed(0) : '0';
      list.add(_card(
        '🔥', 'Top Spending Category', AppTheme.expenseRed,
        '${top.key} takes $pct% of your expenses at ${Fmt.money(top.value)}. Consider setting a budget for this category.',
      ));
    }

    // 2. Monthly comparison (current vs previous)
    final prevM = p.month == 1 ? 12 : p.month - 1;
    final prevY = p.month == 1 ? p.year - 1 : p.year;
    final prevExp = p.all
        .where((t) => !t.isIncome && t.date.month == prevM && t.date.year == prevY)
        .fold(0.0, (s, t) => s + t.amount);
    if (prevExp > 0 && p.expense > 0) {
      final change = ((p.expense - prevExp) / prevExp * 100);
      final up = change > 0;
      list.add(_card(
        up ? '📈' : '📉',
        up ? 'Spending Increased' : 'Spending Decreased',
        up ? AppTheme.expenseRed : AppTheme.incomeGreen,
        'You spent ${change.abs().toStringAsFixed(1)}% ${up ? 'more' : 'less'} than last month (${Fmt.money(prevExp)} → ${Fmt.money(p.expense)}). ${up ? 'Review your expenses.' : 'Great discipline!'}',
      ));
    }

    // 3. Large expense alert
    final avgAmount = p.expense / (p.monthly.where((t) => !t.isIncome).length.clamp(1, 999));
    final bigTxns = p.monthly.where((t) => !t.isIncome && t.amount > avgAmount * 2).toList();
    if (bigTxns.isNotEmpty) {
      list.add(_card(
        '⚡', 'Large Expense${bigTxns.length > 1 ? 's' : ''} Detected', AppTheme.accentBlue,
        '${bigTxns.length} transaction${bigTxns.length > 1 ? 's' : ''} above your average. Largest: "${bigTxns.first.title}" at ${Fmt.money(bigTxns.first.amount)}.',
      ));
    }

    // 4. Savings rate
    if (p.income > 0) {
      final rate = ((p.income - p.expense) / p.income * 100);
      final good = rate >= 20;
      list.add(_card(
        good ? '🎯' : '💡',
        'Savings Rate: ${rate.toStringAsFixed(1)}%',
        good ? AppTheme.incomeGreen : AppTheme.expenseRed,
        good ? 'Excellent! You\'re saving over 20% of your income. Keep it up!' : 'Try to save at least 20% of your income for financial health.',
      ));
    }

    // 5. Frequent spending pattern
    final catCounts = <String, int>{};
    for (final t in p.monthly.where((t) => !t.isIncome)) {
      catCounts[t.category] = (catCounts[t.category] ?? 0) + 1;
    }
    final frequent = catCounts.entries.where((e) => e.value >= 3);
    if (frequent.isNotEmpty) {
      final top = frequent.reduce((a, b) => a.value >= b.value ? a : b);
      list.add(_card(
        '🔄', 'Frequent Pattern: ${top.key}', AppTheme.accentPurple,
        '${top.value} transactions in ${top.key} this month. Consider if all were necessary.',
      ));
    }

    // 6. Daily average
    final daysInMonth = DateTime(p.year, p.month + 1, 0).day;
    final daily = p.expense / daysInMonth;
    if (p.expense > 0) {
      list.add(_card(
        '📊', 'Daily Spending Average', AppTheme.accentBlue,
        'You spend about ${Fmt.money(daily)} per day. Monthly projection: ${Fmt.money(daily * 30)}.',
      ));
    }

    // 7. Weekday vs Weekend spending pattern
    final weekdayTxns = p.monthly.where((t) => !t.isIncome && t.date.weekday <= 5);
    final weekendTxns = p.monthly.where((t) => !t.isIncome && t.date.weekday > 5);
    if (weekdayTxns.isNotEmpty && weekendTxns.isNotEmpty) {
      final weekdayAvg = weekdayTxns.fold(0.0, (s, t) => s + t.amount) / weekdayTxns.length;
      final weekendAvg = weekendTxns.fold(0.0, (s, t) => s + t.amount) / weekendTxns.length;
      final higherWeekend = weekendAvg > weekdayAvg * 1.3;
      if (higherWeekend) {
        list.add(_card(
          '🗓️', 'Weekend Spending Spike', AppTheme.accentPurple,
          'You spend ${(weekendAvg / weekdayAvg * 100 - 100).toStringAsFixed(0)}% more on weekends (avg ${Fmt.money(weekendAvg)}) vs weekdays (${Fmt.money(weekdayAvg)}). Plan weekend budgets!',
        ));
      }
    }

    // 8. Category shift detection (vs prev month)
    final prevCatExp = <String, double>{};
    for (final t in p.all.where((t) => !t.isIncome && t.date.month == prevM && t.date.year == prevY)) {
      prevCatExp[t.category] = (prevCatExp[t.category] ?? 0) + t.amount;
    }
    if (prevCatExp.isNotEmpty && p.catExpenses.isNotEmpty) {
      for (final cat in p.catExpenses.keys.take(3)) {
        final curr = p.catExpenses[cat] ?? 0;
        final prev = prevCatExp[cat] ?? 0;
        if (prev > 0 && curr > prev * 1.5) {
          list.add(_card(
            '🚨', '$cat Spending Surge', AppTheme.expenseRed,
            '$cat increased by ${((curr - prev) / prev * 100).toStringAsFixed(0)}% from last month (${Fmt.money(prev)} → ${Fmt.money(curr)}). Worth reviewing.',
          ));
          break; // Only show the most significant surge
        }
      }
    }

    // 9. Actionable savings tips
    if (p.catExpenses.isNotEmpty && p.expense > 0) {
      final topCat = p.catExpenses.entries.first;
      final savingsPotential = topCat.value * 0.2;
      final tips = _tipFor(topCat.key);
      if (tips != null) {
        list.add(_card(
          '💰', 'Savings Tip: ${topCat.key}', AppTheme.incomeGreen,
          '$tips Reducing ${topCat.key} by 20% could save ${Fmt.money(savingsPotential)}/month (${Fmt.money(savingsPotential * 12)}/year).',
        ));
      }
    }

    return list;
  }

  /// Category-specific savings tips.
  static String? _tipFor(String category) {
    const tips = {
      'Food': 'Cook at home 3+ days a week and try meal prepping.',
      'Transport': 'Carpool, use public transit, or batch your errands.',
      'Shopping': 'Use the 24-hour rule — wait a day before non-essential purchases.',
      'Entertainment': 'Audit your subscriptions and cancel unused ones.',
      'Bills': 'Switch to annual plans for recurring subscriptions.',
      'Health': 'Use generic medicines and preventive health checkups.',
      'Travel': 'Book in advance and use price alerts for flights.',
      'Education': 'Look for free courses before paying for premium ones.',
    };
    return tips[category];
  }

  Widget _card(String emoji, String title, Color color, String body) => GlassCard(
    padding: const EdgeInsets.all(16),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(body, style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12, height: 1.5)),
      ])),
    ]),
  );
}
