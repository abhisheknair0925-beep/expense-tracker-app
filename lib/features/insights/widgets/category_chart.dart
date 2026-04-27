import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class CategoryChart extends StatelessWidget {
  final Map<String, double> data;

  const CategoryChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data for this month', style: TextStyle(color: AppTheme.textMuted)));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 40,
          sections: data.entries.map((e) {
            return PieChartSectionData(
              value: e.value,
              title: '', // Hide title on chart for cleaner look
              color: _getCategoryColor(e.key),
              radius: 50,
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      AppTheme.accentPurple,
      AppTheme.accentBlue,
      AppTheme.incomeGreen,
      const Color(0xFFFFC107),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
    ];
    return colors[category.hashCode % colors.length];
  }
}
