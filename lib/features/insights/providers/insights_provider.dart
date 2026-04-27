import 'package:flutter/material.dart';
import '../models/insight_model.dart';
import '../insights_engine.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../models/transaction_model.dart';

class InsightsProvider extends ChangeNotifier {
  List<InsightModel> _insights = [];
  bool _loading = false;

  List<InsightModel> get insights => _insights;
  bool get loading => _loading;

  Future<void> refreshInsights({
    required TransactionProvider transactionProvider,
    required BudgetProvider budgetProvider,
    required String? profileId,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final currentMonth = transactionProvider.month;
      final currentYear = transactionProvider.year;
      
      final prevMonthDate = DateTime(currentYear, currentMonth - 1);
      
      final allTxns = transactionProvider.all;
      
      final currentTxns = allTxns.where((t) => 
        t.date.month == currentMonth && 
        t.date.year == currentYear
      ).toList();
      
      final prevTxns = allTxns.where((t) => 
        t.date.month == prevMonthDate.month && 
        t.date.year == prevMonthDate.year
      ).toList();

      final engine = InsightsEngine(
        currentMonthTxns: currentTxns,
        previousMonthTxns: prevTxns,
        budgets: budgetProvider.budgets,
        month: currentMonth,
        year: currentYear,
      );

      _insights = engine.generateInsights();
    } catch (e) {
      debugPrint('InsightsProvider: Error generating insights: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
