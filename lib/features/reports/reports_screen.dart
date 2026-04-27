import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../../core/theme/app_theme.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/user_provider.dart';
import 'providers/report_provider.dart';
import '../../widgets/glass_card.dart';
import '../insights/widgets/category_chart.dart';
import '../insights/widgets/trend_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final GlobalKey _pieKey = GlobalKey();
  final GlobalKey _barKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TransactionProvider>();
    final up = context.watch<UserProvider>();
    final rp = context.watch<ReportProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reports', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                          Text('Generate professional statements', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),

                  // Month Selector Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(onPressed: tp.prevMonth, icon: const Icon(Icons.chevron_left, color: AppTheme.textPrimary)),
                            Column(
                              children: [
                                Text('${tp.year}', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12)),
                                Text(
                                  DateFormat('MMMM').format(DateTime(tp.year, tp.month)),
                                  style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            IconButton(onPressed: tp.nextMonth, icon: const Icon(Icons.chevron_right, color: AppTheme.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Report Options
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _reportActionTile(
                            icon: Icons.picture_as_pdf_rounded,
                            title: 'Generate PDF Statement',
                            subtitle: 'Summary, charts, and top vendors',
                            color: AppTheme.accentPurple,
                            onTap: () => _generatePdf(context),
                          ),
                          const SizedBox(height: 12),
                          _reportActionTile(
                            icon: Icons.table_view_rounded,
                            title: 'Export CSV Data',
                            subtitle: 'Full transaction list for Excel',
                            color: AppTheme.accentBlue,
                            onTap: () => rp.exportCsv(tp: tp),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Preview Area
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('DATA PREVIEW', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GlassCard(
                        child: Column(
                          children: [
                            _statRow('Total Transactions', '${tp.monthly.length}'),
                            _statRow('Total Income', 'INR ${tp.income.toStringAsFixed(0)}'),
                            _statRow('Total Expense', 'INR ${tp.expense.toStringAsFixed(0)}'),
                            _statRow('Active Profile', up.selectedProfile?.profileType.name.toUpperCase() ?? 'NONE'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),

              // Hidden Charts for capture
              Positioned(
                left: -2000,
                child: Column(
                  children: [
                    RepaintBoundary(
                      key: _pieKey,
                      child: Container(
                        width: 400, height: 400, color: Colors.white,
                        child: CategoryChart(data: tp.catExpenses),
                      ),
                    ),
                    RepaintBoundary(
                      key: _barKey,
                      child: Container(
                        width: 600, height: 400, color: Colors.white,
                        child: TrendChart(data: tp.yearlyTrend),
                      ),
                    ),
                  ],
                ),
              ),

              if (rp.loading)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportActionTile({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                Text(subtitle, style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textMuted, size: 16),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 13)),
          Text(value, style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context) async {
    final tp = context.read<TransactionProvider>();
    final bp = context.read<BudgetProvider>();
    final up = context.read<UserProvider>();
    final rp = context.read<ReportProvider>();

    // Capture images
    final pieImg = await _capture(_pieKey);
    final barImg = await _capture(_barKey);

    await rp.generatePdfReport(
      tp: tp,
      bp: bp,
      up: up,
      pieChart: pieImg,
      barChart: barImg,
    );
  }

  Future<Uint8List?> _capture(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }
}
