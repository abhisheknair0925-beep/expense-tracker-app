import 'package:flutter/material.dart';

/// Lightweight multi-currency converter with static rates.
/// No API calls — rates are embedded for offline use.
class CurrencyService {
  CurrencyService._();
  static final CurrencyService instance = CurrencyService._();

  /// Base currency is INR. Rates = 1 INR in target currency.
  static const Map<String, double> _rates = {
    'INR': 1.0,
    'USD': 0.012,
    'EUR': 0.011,
    'GBP': 0.0095,
    'JPY': 1.85,
    'AED': 0.044,
    'SGD': 0.016,
    'AUD': 0.018,
    'CAD': 0.016,
    'CNY': 0.087,
  };

  static const Map<String, String> symbols = {
    'INR': '₹', 'USD': '\$', 'EUR': '€', 'GBP': '£', 'JPY': '¥',
    'AED': 'د.إ', 'SGD': 'S\$', 'AUD': 'A\$', 'CAD': 'C\$', 'CNY': '¥',
  };

  List<String> get supportedCurrencies => _rates.keys.toList();

  /// Convert amount from INR to target currency.
  double convert(double amountInr, String to) {
    final rate = _rates[to] ?? 1.0;
    return amountInr * rate;
  }

  /// Format amount in target currency.
  String format(double amount, String currency, {bool convertFromInr = false}) {
    final value = convertFromInr ? convert(amount, currency) : amount;
    final sym = symbols[currency] ?? currency;
    return '$sym${value.toStringAsFixed(2)}';
  }

  /// Get the symbol for a currency code.
  String symbol(String code) => symbols[code] ?? code;

  /// Get appropriate icon for a currency.
  IconData icon(String code) {
    switch (code) {
      case 'INR': return Icons.currency_rupee_rounded;
      case 'USD': return Icons.attach_money_rounded;
      case 'EUR': return Icons.euro_rounded;
      case 'GBP': return Icons.currency_pound_rounded;
      case 'JPY': return Icons.currency_yen_rounded;
      case 'CNY': return Icons.currency_yuan_rounded;
      default: return Icons.payments_rounded;
    }
  }
}
