import 'package:flutter/material.dart';

/// App constants — categories, icons, colors, DB config.
class AppConstants {
  AppConstants._();

  static const String appName = 'Expense Tracker';
  static const String currency = '₹';
  static const String dbName = 'expense_tracker.db';
  static const int dbVersion = 6;
  static const String tableTxn = 'transactions';
  static const String tableAccounts = 'accounts';
  static const String tableBills = 'bills';
  static const String tableBudgets = 'budgets';

  // ─── Bill Categories ─────────────────────────────────────────────
  static const List<String> billCategories = [
    'Bills', 'Shopping', 'Transport', 'Food', 'Entertainment',
    'Health', 'Education', 'Other',
  ];

  // ─── Filters ──────────────────────────────────────────────────────
  static const List<String> filterOptions = ['All', 'Income', 'Expense'];

  // ─── Account Types ────────────────────────────────────────────────
  static const List<String> accountTypes = ['bank', 'cash', 'wallet'];
  static const Map<String, IconData> accountIcons = {
    'bank': Icons.account_balance_rounded,
    'cash': Icons.money_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
  };

  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';

  static const List<String> incomeCategories = [
    'Salary', 'Freelance', 'Investment', 'Business', 'Gift', 'Other',
  ];

  static const List<String> expenseCategories = [
    'Food', 'Transport', 'Shopping', 'Entertainment',
    'Bills', 'Health', 'Education', 'Travel', 'Other',
  ];

  static const Map<String, IconData> catIcons = {
    'Salary': Icons.account_balance_wallet_rounded,
    'Freelance': Icons.laptop_mac_rounded,
    'Investment': Icons.trending_up_rounded,
    'Business': Icons.business_rounded,
    'Gift': Icons.card_giftcard_rounded,
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_car_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Entertainment': Icons.movie_rounded,
    'Bills': Icons.receipt_long_rounded,
    'Health': Icons.favorite_rounded,
    'Education': Icons.school_rounded,
    'Travel': Icons.flight_rounded,
    'Other': Icons.more_horiz_rounded,
  };

  static const Map<String, Color> catColors = {
    'Salary': Color(0xFF4FC3F7),
    'Freelance': Color(0xFF7B61FF),
    'Investment': Color(0xFF00E676),
    'Business': Color(0xFFFFAB40),
    'Gift': Color(0xFFE040FB),
    'Food': Color(0xFFFF5252),
    'Transport': Color(0xFF40C4FF),
    'Shopping': Color(0xFFFF6E40),
    'Entertainment': Color(0xFFE040FB),
    'Bills': Color(0xFFFFD740),
    'Health': Color(0xFFFF5252),
    'Education': Color(0xFF69F0AE),
    'Travel': Color(0xFF4FC3F7),
    'Other': Color(0xFFB0BEC5),
  };
}
