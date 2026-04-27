import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/transaction_model.dart';

class CsvExporter {
  static Future<void> exportTransactions(List<Txn> transactions, String fileName) async {
    final headers = ['Date', 'Title', 'Amount', 'Type', 'Category', 'Account ID', 'Receipt'];
    
    final rows = transactions.map((t) => [
      DateFormat('yyyy-MM-dd').format(t.date),
      t.title,
      t.amount.toStringAsFixed(2),
      t.type,
      t.category,
      t.accountId ?? '',
      t.receiptPath ?? '',
    ]).toList();

    final csvData = Csv().encode([headers, ...rows]);
    
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName.csv');
    await file.writeAsString(csvData);
    
    await Share.shareXFiles([XFile(file.path)], subject: 'Transaction Export');
  }
}
