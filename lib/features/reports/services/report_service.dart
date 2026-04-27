import '../../../models/transaction_model.dart';
import '../models/report_model.dart';
import '../../insights/insights_engine.dart';
import '../../insights/services/analytics_service.dart';
import '../../../models/budget_model.dart';
import 'package:collection/collection.dart';

class ReportService {
  static ReportModel prepareReportData({
    required List<Txn> currentMonthTxns,
    required List<Txn> previousMonthTxns,
    required List<Budget> budgets,
    required int month,
    required int year,
    required String profileName,
    required String profileType,
  }) {
    final income = currentMonthTxns.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final expense = currentMonthTxns.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
    
    // Category Breakdown
    final catMap = <String, double>{};
    for (var t in currentMonthTxns.where((t) => !t.isIncome)) {
      catMap[t.category] = (catMap[t.category] ?? 0) + t.amount;
    }

    // Top Merchants
    final merchantAnalysis = AnalyticsService.getMerchantAnalysis(currentMonthTxns);

    // Insights
    final engine = InsightsEngine(
      currentMonthTxns: currentMonthTxns,
      previousMonthTxns: previousMonthTxns,
      budgets: budgets,
      month: month,
      year: year,
    );
    final insights = engine.generateInsights();

    return ReportModel(
      totalIncome: income,
      totalExpense: expense,
      balance: income - expense,
      categoryBreakdown: catMap,
      topMerchants: merchantAnalysis,
      insightsList: insights,
      month: month,
      year: year,
      profileName: profileName,
      profileType: profileType,
    );
  }
}
