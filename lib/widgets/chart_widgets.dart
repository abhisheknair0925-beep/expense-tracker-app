import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../utils/formatters.dart';
import 'glass_card.dart';

// ═════════════════════════════════════════════════════════════════════
// PIE CHART — Category-wise spending
// ═════════════════════════════════════════════════════════════════════

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> data;
  const CategoryPieChart({super.key, required this.data});

  static const _colors = [
    Color(0xFF7B61FF), Color(0xFF4FC3F7), Color(0xFFFF5252),
    Color(0xFF00E676), Color(0xFFFFAB40), Color(0xFFE040FB),
    Color(0xFF40C4FF), Color(0xFFFF6E40), Color(0xFF69F0AE),
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _empty('Expense by Category', Icons.pie_chart_outline_rounded);

    final total = data.values.fold(0.0, (s, v) => s + v);
    final entries = data.entries.toList();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Text('Expense by Category',
            style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: PieChart(PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 36,
            sections: entries.asMap().entries.map((e) {
              final pct = (e.value.value / total * 100);
              return PieChartSectionData(
                value: e.value.value,
                title: '${pct.toStringAsFixed(0)}%',
                color: _colors[e.key % _colors.length],
                radius: 44,
                titleStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              );
            }).toList(),
          )),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14, runSpacing: 6,
          children: entries.asMap().entries.map((e) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: _colors[e.key % _colors.length], borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 5),
              Text('${e.value.key} (${Fmt.money(e.value.value)})',
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 10)),
            ],
          )).toList(),
        ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// BAR CHART — Monthly income vs expense trends
// ═════════════════════════════════════════════════════════════════════

class MonthlyBarChart extends StatelessWidget {
  final List<({int month, double income, double expense})> data;
  const MonthlyBarChart({super.key, required this.data});

  static const _months = ['', 'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  @override
  Widget build(BuildContext context) {
    final hasData = data.any((d) => d.income > 0 || d.expense > 0);
    if (!hasData) return _empty('Monthly Trends', Icons.bar_chart_rounded);

    double maxY = 0;
    for (final d in data) {
      if (d.income > maxY) maxY = d.income;
      if (d.expense > maxY) maxY = d.expense;
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Text('Monthly Trends',
            style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _dot(AppTheme.incomeGreen, 'Income'),
          const SizedBox(width: 16),
          _dot(AppTheme.expenseRed, 'Expense'),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                  '${_months[group.x]}\n${ri == 0 ? 'Inc' : 'Exp'}: ${Fmt.money(rod.toY)}',
                  GoogleFonts.poppins(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 40,
                getTitlesWidget: (v, m) => Text(Fmt.compact(v), style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 9)),
              )),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, m) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_months[v.toInt()], style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 9)),
                ),
              )),
            ),
            gridData: FlGridData(
              show: true, drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? maxY / 4 : 1,
              getDrawingHorizontalLine: (v) => FlLine(color: AppTheme.glassBorder, strokeWidth: 0.5),
            ),
            borderData: FlBorderData(show: false),
            barGroups: data.map((d) => BarChartGroupData(x: d.month, barRods: [
              BarChartRodData(toY: d.income, color: AppTheme.incomeGreen, width: 7, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
              BarChartRodData(toY: d.expense, color: AppTheme.expenseRed, width: 7, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
            ])).toList(),
          )),
        ),
      ]),
    );
  }

  Widget _dot(Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 4),
    Text(label, style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11)),
  ]);
}

// ─── Empty chart placeholder ─────────────────────────────────────────
Widget _empty(String title, IconData icon) => GlassCard(
  padding: const EdgeInsets.all(24),
  child: Column(children: [
    Text(title, style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
    const SizedBox(height: 16),
    Icon(icon, color: AppTheme.textMuted, size: 56),
    const SizedBox(height: 10),
    Text('No data yet', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 13)),
  ]),
);
