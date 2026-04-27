import '../../insights/models/insight_model.dart';

class ReportModel {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final Map<String, double> categoryBreakdown;
  final List<MapEntry<String, double>> topMerchants;
  final List<InsightModel> insightsList;
  final int month;
  final int year;
  final String profileName;
  final String profileType;

  ReportModel({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.categoryBreakdown,
    required this.topMerchants,
    required this.insightsList,
    required this.month,
    required this.year,
    required this.profileName,
    required this.profileType,
  });
}
