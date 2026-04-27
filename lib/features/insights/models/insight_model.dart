import 'package:flutter/material.dart';

enum InsightType { warning, info, success }

class InsightModel {
  final String title;
  final String description;
  final InsightType type;
  final String? value;
  final IconData? icon;

  const InsightModel({
    required this.title,
    required this.description,
    required this.type,
    this.value,
    this.icon,
  });

  Color get color {
    switch (type) {
      case InsightType.warning:
        return const Color(0xFFFF5252); // expenseRed or similar
      case InsightType.success:
        return const Color(0xFF4CAF50); // incomeGreen or similar
      case InsightType.info:
        return const Color(0xFF2196F3); // accentBlue or similar
    }
  }
}
