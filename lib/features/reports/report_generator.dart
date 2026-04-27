import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'models/report_model.dart';
import '../../../models/transaction_model.dart';

class ReportGenerator {
  static Future<void> generateMonthlyPdf({
    required ReportModel report,
    required List<Txn> transactions,
    Uint8List? pieChart,
    Uint8List? barChart,
  }) async {
    final pdf = pw.Document();
    final monthName = DateFormat('MMMM yyyy').format(DateTime(report.year, report.month));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('FINANCIAL REPORT', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    pw.Text(monthName, style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(report.profileName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Profile: ${report.profileType}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 2, color: PdfColors.blue900),
            pw.SizedBox(height: 20),

            // Summary Grid
            pw.Row(
              children: [
                _buildSummaryBox('TOTAL INCOME', 'INR ${report.totalIncome.toStringAsFixed(2)}', PdfColors.green900),
                pw.SizedBox(width: 10),
                _buildSummaryBox('TOTAL EXPENSE', 'INR ${report.totalExpense.toStringAsFixed(2)}', PdfColors.red900),
                pw.SizedBox(width: 10),
                _buildSummaryBox('NET BALANCE', 'INR ${report.balance.toStringAsFixed(2)}', PdfColors.blue900),
              ],
            ),
            pw.SizedBox(height: 30),

            // Charts Section
            if (pieChart != null || barChart != null) ...[
              pw.Text('VISUAL ANALYSIS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  if (pieChart != null) pw.Expanded(child: pw.Column(children: [pw.Image(pw.MemoryImage(pieChart), height: 150), pw.Text('Category Split', style: const pw.TextStyle(fontSize: 8))])),
                  if (barChart != null) pw.Expanded(child: pw.Column(children: [pw.Image(pw.MemoryImage(barChart), height: 150), pw.Text('Monthly Trend', style: const pw.TextStyle(fontSize: 8))])),
                ],
              ),
              pw.SizedBox(height: 30),
            ],

            // Category Breakdown Table
            pw.Text('CATEGORY BREAKDOWN', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Category', 'Amount', 'Percentage'],
              data: report.categoryBreakdown.entries.map((e) => [
                e.key,
                'INR ${e.value.toStringAsFixed(2)}',
                '${((e.value / report.totalExpense) * 100).toStringAsFixed(1)}%'
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 30),

            // Top Merchants
            pw.Text('TOP MERCHANTS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Bullet(text: report.topMerchants.take(3).map((e) => '${e.key}: INR ${e.value.toStringAsFixed(0)}').join(', ')),
            pw.SizedBox(height: 30),

            // Insights
            if (report.insightsList.isNotEmpty) ...[
              pw.Text('SMART INSIGHTS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...report.insightsList.take(3).map((i) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text('• ${i.title}: ${i.description}', style: const pw.TextStyle(fontSize: 10)),
              )),
              pw.SizedBox(height: 30),
            ],

            // Detailed Transactions (Shortened for PDF)
            pw.Text('RECENT TRANSACTIONS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Title', 'Category', 'Amount'],
              data: transactions.take(20).map((t) => [
                DateFormat('dd MMM').format(t.date),
                t.title,
                t.category,
                '${t.isIncome ? '+' : '-'} ${t.amount.toStringAsFixed(0)}'
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Report_${monthName.replaceAll(' ', '_')}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    await Share.shareXFiles([XFile(file.path)], subject: 'Monthly Financial Report');
  }

  static pw.Widget _buildSummaryBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 8, color: color, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
