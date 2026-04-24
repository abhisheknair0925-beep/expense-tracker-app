import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../providers/transaction_provider.dart';
import '../utils/formatters.dart';
import '../widgets/chart_widgets.dart';
import '../widgets/glass_card.dart';
import '../widgets/transaction_tile.dart';
import 'settings_screen.dart';

/// Home dashboard content — used inside ShellScreen.
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, p, _) {
        if (p.loading) return const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple));
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header(context, p)),
            SliverToBoxAdapter(child: _balanceCard(p)),
            SliverToBoxAdapter(child: _summaryRow(p)),
            SliverToBoxAdapter(child: _topCategories(p)),
            // Charts
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CategoryPieChart(data: p.catExpenses),
            )),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MonthlyBarChart(data: p.yearlyTrend),
            )),
            // Recent transactions
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Recent Transactions', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
            )),
            if (p.recent.isEmpty)
              SliverToBoxAdapter(child: _emptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final t = p.recent[i];
                    return TransactionTile(txn: t, onDelete: () => p.remove(t.id!));
                  },
                  childCount: p.recent.length,
                )),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  // ─── Header with month navigator ──────────────────────────────────
  Widget _header(BuildContext context, TransactionProvider p) {
    final dt = DateTime(p.year, p.month);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppConstants.appName, style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('Manage your finances', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12)),
        ])),
        const SizedBox(width: 8),
        GlassCard(
          margin: EdgeInsets.zero, padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4), radius: 14,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _iconBtn(Icons.chevron_left_rounded, p.prevMonth),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(Fmt.monthYear(dt), style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
            ),
            _iconBtn(Icons.chevron_right_rounded, p.nextMonth),
          ]),
        ),
        const SizedBox(width: 8),
        GlassCard(margin: EdgeInsets.zero, padding: const EdgeInsets.all(10), radius: 14,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          child: const Icon(Icons.settings_rounded, color: AppTheme.textMuted, size: 20)),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, color: AppTheme.textSecondary, size: 20)),
  );

  // ─── Balance card ─────────────────────────────────────────────────
  Widget _balanceCard(TransactionProvider p) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(children: [
        Text('Total Balance', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        ShaderMask(
          shaderCallback: (b) => AppTheme.accentGradient.createShader(b),
          child: Text(Fmt.money(p.balance), style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 4),
        Text('${p.monthly.length} transactions this month', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
      ]),
    ),
  );

  // ─── Income / Expense cards ───────────────────────────────────────
  Widget _summaryRow(TransactionProvider p) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(children: [
      Expanded(child: _summaryCard(Icons.arrow_downward_rounded, 'Income', p.income, AppTheme.incomeGreen)),
      const SizedBox(width: 12),
      Expanded(child: _summaryCard(Icons.arrow_upward_rounded, 'Expense', p.expense, AppTheme.expenseRed)),
    ]),
  );

  Widget _summaryCard(IconData icon, String label, double amount, Color color) => GlassCard(
    padding: const EdgeInsets.all(14),
    child: Row(children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
        Text(Fmt.money(amount), style: GoogleFonts.poppins(color: color, fontSize: 16, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
    ]),
  );

  // ─── Top categories preview ───────────────────────────────────────
  Widget _topCategories(TransactionProvider p) {
    if (p.catExpenses.isEmpty) return const SizedBox.shrink();
    final top = p.catExpenses.entries.take(3);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Top Spending', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...top.map((e) {
            final pct = p.expense > 0 ? e.value / p.expense : 0.0;
            final cc = AppConstants.catColors[e.key] ?? AppTheme.textSecondary;
            final ci = AppConstants.catIcons[e.key] ?? Icons.more_horiz_rounded;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(width: 32, height: 32, decoration: BoxDecoration(color: cc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)), child: Icon(ci, color: cc, size: 16)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(e.key, style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                    Text(Fmt.money(e.value), style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: pct, backgroundColor: AppTheme.glassWhite, valueColor: AlwaysStoppedAnimation(cc), minHeight: 4)),
                ])),
              ]),
            );
          }),
        ]),
      ),
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────
  Widget _emptyState() => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: AppTheme.accentPurple.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(Icons.receipt_long_rounded, color: AppTheme.accentPurple.withValues(alpha: 0.4), size: 40),
      ),
      const SizedBox(height: 16),
      Text('No transactions yet', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      Text('Tap + to add your first one', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12)),
    ]),
  );
}
