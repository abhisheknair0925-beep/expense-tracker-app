import 'package:intl/intl.dart';

/// Currency and date formatters.
class Fmt {
  Fmt._();
  static final _cur = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
  static final _date = DateFormat('dd MMM yyyy');
  static final _short = DateFormat('dd MMM');
  static final _monthYr = DateFormat('MMM yyyy');

  static String money(double v) => _cur.format(v);
  static String date(DateTime d) => _date.format(d);
  static String shortDate(DateTime d) => _short.format(d);
  static String monthYear(DateTime d) => _monthYr.format(d);
  static String compact(double v) => NumberFormat.compact().format(v);
}
