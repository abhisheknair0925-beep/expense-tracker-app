import 'package:flutter/material.dart';
import 'models/insight_model.dart';
import 'services/analytics_service.dart';
import '../../models/transaction_model.dart';
import '../../models/budget_model.dart';

class InsightsEngine {
  final List<Txn> currentMonthTxns;
  final List<Txn> previousMonthTxns;
  final List<Budget> budgets;
  final int month;
  final int year;

  InsightsEngine({
    required this.currentMonthTxns,
    required this.previousMonthTxns,
    required this.budgets,
    required this.month,
    required this.year,
  });

  List<InsightModel> generateInsights() {
    final insights = <InsightModel>[];

    // 1. Monthly Comparison Rule
    final comparison = AnalyticsService.compareMonths(currentMonthTxns, previousMonthTxns);
    if (comparison['percentage'] > 15) {
      insights.add(InsightModel(
        title: 'Spending Spike',
        description: 'You spent ${comparison['percentage'].toStringAsFixed(1)}% more than last month.',
        type: InsightType.warning,
        icon: Icons.trending_up_rounded,
        value: '+${_formatCurrency(comparison['difference'] as double)}',
      ));
    } else if (comparison['percentage'] < -10) {
      insights.add(InsightModel(
        title: 'Great Savings!',
        description: 'Your spending is down by ${comparison['percentage'].abs().toStringAsFixed(1)}% compared to last month.',
        type: InsightType.success,
        icon: Icons.savings_rounded,
        value: '-${_formatCurrency((comparison['difference'] as double).abs())}',
      ));
    }

    // 2. Category Concentration Rule
    final catAnalysis = AnalyticsService.getCategoryAnalysis(currentMonthTxns);
    if (catAnalysis['topPercent'] > 40) {
      insights.add(InsightModel(
        title: 'High Category Spend',
        description: '${catAnalysis['topCategory']} accounts for ${catAnalysis['topPercent'].toStringAsFixed(1)}% of your expenses.',
        type: InsightType.warning,
        icon: Icons.pie_chart_rounded,
      ));
    }

    // 3. Daily Average Rule
    final dailyAvg = AnalyticsService.getDailyAverage(currentMonthTxns, month, year);
    if (dailyAvg > 1500) { // Example threshold
      insights.add(InsightModel(
        title: 'High Daily Burn',
        description: 'Your daily average spending is ₹${dailyAvg.toStringAsFixed(0)}.',
        type: InsightType.info,
        icon: Icons.speed_rounded,
      ));
    }

    // 4. Budget Overrun Rule
    for (final budget in budgets) {
      final catSpend = currentMonthTxns
          .where((t) => !t.isIncome && t.category == budget.category)
          .fold(0.0, (s, t) => s + t.amount);
      
      if (catSpend > budget.limit) {
        insights.add(InsightModel(
          title: 'Budget Exceeded',
          description: 'You overspent in ${budget.category} by ₹${(catSpend - budget.limit).toStringAsFixed(0)}.',
          type: InsightType.warning,
          icon: Icons.warning_amber_rounded,
        ));
      } else if (catSpend > budget.limit * 0.8) {
        insights.add(InsightModel(
          title: 'Budget Alert',
          description: 'You have used 80% of your ${budget.category} budget.',
          type: InsightType.info,
          icon: Icons.notifications_active_rounded,
        ));
      }
    }

    // 5. Merchant Rule
    final merchants = AnalyticsService.getMerchantAnalysis(currentMonthTxns);
    if (merchants.isNotEmpty) {
      insights.add(InsightModel(
        title: 'Top Vendor',
        description: '${merchants.first.key} is your highest expense source this month.',
        type: InsightType.info,
        icon: Icons.store_rounded,
        value: _formatCurrency(merchants.first.value),
      ));
    }

    return insights;
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0)}';
  }
}
