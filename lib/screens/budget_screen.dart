import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/budget_model.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../services/currency_service.dart';
import '../utils/formatters.dart';
import '../widgets/glass_card.dart';

/// Budget planning screen — set and track category budgets.
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txnP = context.watch<TransactionProvider>();
    final budP = context.watch<BudgetProvider>();
    final userProvider = context.watch<UserProvider>();
    final currency = userProvider.userProfile?.currency ?? 'INR';
    final currencyIcon = CurrencyService.instance.icon(currency);
    final cats = AppConstants.expenseCategories;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              if (Navigator.canPop(context)) ...[
                GlassCard(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(8),
                  radius: 12,
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary, size: 22),
                ),
              ],
              Text('Budgets', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
            ]),
            GlassCard(margin: EdgeInsets.zero, padding: const EdgeInsets.all(10), radius: 14,
              onTap: () => _showAdd(context, txnP, budP, currencyIcon),
              child: const Icon(Icons.add_rounded, color: AppTheme.accentPurple, size: 22)),
          ]),
        )),
        // Overview
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GlassCard(padding: const EdgeInsets.all(18), child: Row(children: [
            _miniStat('Total Budget', Fmt.money(budP.budgets.where((b) => b.month == txnP.month && b.year == txnP.year).fold(0.0, (s, b) => s + b.limit), currency), AppTheme.accentBlue),
            Container(width: 1, height: 40, color: AppTheme.glassBorder),
            _miniStat('Total Spent', Fmt.money(txnP.expense, currency), AppTheme.expenseRed),
          ])),
        )),
        // Category budget cards
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
            final cat = cats[i];
            final budget = budP.forCategory(cat);
            final spent = txnP.catExpenses[cat] ?? 0;
            return _catCard(context, cat, budget, spent, txnP, budP, currency);
          }, childCount: cats.length)),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) => Expanded(
    child: Column(children: [
      Text(label, style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.poppins(color: color, fontSize: 18, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );

  Widget _catCard(BuildContext context, String cat, Budget? budget, double spent, TransactionProvider txnP, BudgetProvider budP, String currency) {
    final icon = AppConstants.catIcons[cat] ?? Icons.more_horiz_rounded;
    final color = AppConstants.catColors[cat] ?? AppTheme.textMuted;
    final hasB = budget != null;
    final pct = hasB ? (spent / budget.limit).clamp(0.0, 1.5) : 0.0;
    final isOver = hasB && spent > budget.limit;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cat, style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            Text(hasB ? '${Fmt.money(spent, currency)} / ${Fmt.money(budget.limit, currency)}' : 'No budget set',
                style: GoogleFonts.poppins(color: isOver ? AppTheme.expenseRed : AppTheme.textMuted, fontSize: 11)),
          ])),
          if (isOver) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppTheme.expenseRed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('OVER', style: GoogleFonts.poppins(color: AppTheme.expenseRed, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          if (!hasB) GestureDetector(
            onTap: () => _quickSet(context, cat, txnP, budP),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppTheme.glassWhite, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.glassBorder)),
              child: Text('Set', style: GoogleFonts.poppins(color: AppTheme.accentPurple, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
        if (hasB) ...[
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: AppTheme.glassWhite,
              valueColor: AlwaysStoppedAnimation(isOver ? AppTheme.expenseRed : pct > 0.8 ? Colors.orange : color),
              minHeight: 6,
            )),
        ],
      ]),
    );
  }

  void _quickSet(BuildContext context, String cat, TransactionProvider txnP, BudgetProvider budP) {
    final userProvider = context.read<UserProvider>();
    final currency = userProvider.userProfile?.currency ?? 'INR';
    final currencyIcon = CurrencyService.instance.icon(currency);
    final ctrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        decoration: const BoxDecoration(color: AppTheme.primaryMid, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.glassBorder, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Set $cat Budget', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
            decoration: InputDecoration(labelText: 'Monthly Limit', prefixIcon: Icon(currencyIcon, color: AppTheme.textMuted))),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              final val = double.tryParse(ctrl.text);
              if (val == null || val <= 0) return;
              budP.add(Budget(category: cat, limit: val, month: txnP.month, year: txnP.year));
              Navigator.pop(ctx);
            },
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text('Save Budget', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)))),
          ),
        ]),
      ),
    );
  }

  void _showAdd(BuildContext context, TransactionProvider txnP, BudgetProvider budP, IconData currencyIcon) {
    final ctrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        decoration: const BoxDecoration(color: AppTheme.primaryMid, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.glassBorder, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Set Budget', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
            decoration: InputDecoration(labelText: 'Monthly Limit', prefixIcon: Icon(currencyIcon, color: AppTheme.textMuted))),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              final val = double.tryParse(ctrl.text);
              if (val == null || val <= 0) return;
              budP.add(Budget(category: AppConstants.expenseCategories.first, limit: val, month: txnP.month, year: txnP.year));
              Navigator.pop(ctx);
            },
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text('Save Budget', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)))),
          ),
        ]),
      ),
    );
  }
}
