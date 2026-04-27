import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import '../report_generator.dart';
import '../csv_exporter.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/user_provider.dart';

class ReportProvider extends ChangeNotifier {
  bool _loading = false;
  bool get loading => _loading;

  Future<void> generatePdfReport({
    required TransactionProvider tp,
    required BudgetProvider bp,
    required UserProvider up,
    Uint8List? pieChart,
    Uint8List? barChart,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final currentMonthTxns = tp.monthly;
      final prevMonthDate = DateTime(tp.year, tp.month - 1);
      final prevMonthTxns = tp.all.where((t) => t.date.month == prevMonthDate.month && t.date.year == prevMonthDate.year).toList();

      final reportData = ReportService.prepareReportData(
        currentMonthTxns: currentMonthTxns,
        previousMonthTxns: prevMonthTxns,
        budgets: bp.budgets,
        month: tp.month,
        year: tp.year,
        profileName: up.userProfile?.name ?? 'Guest',
        profileType: up.selectedProfile?.profileType.name.toUpperCase() ?? 'PERSONAL',
      );

      await ReportGenerator.generateMonthlyPdf(
        report: reportData,
        transactions: currentMonthTxns,
        pieChart: pieChart,
        barChart: barChart,
      );
    } catch (e) {
      debugPrint('ReportProvider Error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> exportCsv({required TransactionProvider tp}) async {
    _loading = true;
    notifyListeners();
    try {
      final name = 'Transactions_${tp.month}_${tp.year}';
      await CsvExporter.exportTransactions(tp.monthly, name);
    } catch (e) {
      debugPrint('CSV Export Error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
