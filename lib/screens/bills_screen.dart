import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/bill_model.dart';
import '../providers/bill_provider.dart';
import '../utils/formatters.dart';
import '../widgets/glass_card.dart';

/// Bill reminders screen — manage recurring bills.
class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, p, _) => CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Bill Reminders', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
              GlassCard(margin: EdgeInsets.zero, padding: const EdgeInsets.all(10), radius: 14,
                onTap: () => _showAdd(context),
                child: const Icon(Icons.add_rounded, color: AppTheme.accentPurple, size: 22)),
            ]),
          )),
          // Summary cards
          if (p.overdue.isNotEmpty || p.dueSoon.isNotEmpty)
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                if (p.overdue.isNotEmpty) Expanded(child: _statusCard('Overdue', '${p.overdue.length}', Icons.warning_rounded, AppTheme.expenseRed)),
                if (p.overdue.isNotEmpty && p.dueSoon.isNotEmpty) const SizedBox(width: 10),
                if (p.dueSoon.isNotEmpty) Expanded(child: _statusCard('Due Soon', Fmt.money(p.totalUpcoming), Icons.schedule_rounded, AppTheme.accentBlue)),
              ]),
            )),
          // Bill list
          if (p.bills.isEmpty)
            SliverToBoxAdapter(child: _empty())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (ctx, i) => _billTile(context, p.bills[i], p),
                childCount: p.bills.length,
              )),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _statusCard(String label, String value, IconData icon, Color color) => GlassCard(
    padding: const EdgeInsets.all(14),
    child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
        Text(value, style: GoogleFonts.poppins(color: color, fontSize: 16, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
    ]),
  );

  Widget _billTile(BuildContext context, Bill b, BillProvider p) {
    final icon = AppConstants.catIcons[b.category] ?? Icons.receipt_long_rounded;
    final color = AppConstants.catColors[b.category] ?? AppTheme.accentBlue;
    final status = b.isPaid ? '✓ Paid' : b.isOverdue ? '${b.daysUntilDue.abs()}d overdue' : b.daysUntilDue == 0 ? 'Due today' : 'In ${b.daysUntilDue}d';
    final statusColor = b.isPaid ? AppTheme.incomeGreen : b.isOverdue ? AppTheme.expenseRed : b.isDueSoon ? AppTheme.accentBlue : AppTheme.textMuted;

    return Dismissible(
      key: Key('bill_${b.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => p.remove(b.id!),
      background: Container(
        alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: AppTheme.expenseRed.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_rounded, color: AppTheme.expenseRed),
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.title, style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(status, style: GoogleFonts.poppins(color: statusColor, fontSize: 11, fontWeight: FontWeight.w500)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(Fmt.money(b.amount), style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => p.togglePaid(b.id!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: b.isPaid ? AppTheme.incomeGreen.withValues(alpha: 0.15) : AppTheme.glassWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: b.isPaid ? AppTheme.incomeGreen : AppTheme.glassBorder),
                ),
                child: Text(b.isPaid ? 'Paid' : 'Mark Paid', style: GoogleFonts.poppins(color: b.isPaid ? AppTheme.incomeGreen : AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _empty() => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(children: [
      const Icon(Icons.notifications_none_rounded, color: AppTheme.textMuted, size: 56),
      const SizedBox(height: 12),
      Text('No bill reminders', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text('Tap + to add a recurring bill', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12)),
    ]),
  );

  void _showAdd(BuildContext context) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = AppConstants.expenseCategories.first;
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: const BoxDecoration(color: AppTheme.primaryMid, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.glassBorder, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Add Bill Reminder', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(controller: titleCtrl, style: GoogleFonts.poppins(color: AppTheme.textPrimary), decoration: const InputDecoration(labelText: 'Bill Name', prefixIcon: Icon(Icons.receipt_rounded, color: AppTheme.textMuted))),
            const SizedBox(height: 12),
            TextField(controller: amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: GoogleFonts.poppins(color: AppTheme.textPrimary), decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppTheme.textMuted))),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: category, dropdownColor: AppTheme.primaryMid,
              style: GoogleFonts.poppins(color: AppTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_rounded, color: AppTheme.textMuted)),
              items: AppConstants.billCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) { if (v != null) setState(() => category = v); },
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(context: ctx, initialDate: dueDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (c, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.accentPurple, surface: AppTheme.primaryMid)), child: child!));
                if (picked != null) setState(() => dueDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Due Date', prefixIcon: Icon(Icons.calendar_today_rounded, color: AppTheme.textMuted)),
                child: Text(Fmt.date(dueDate), style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                if (titleCtrl.text.trim().isEmpty || amountCtrl.text.trim().isEmpty) return;
                context.read<BillProvider>().add(Bill(title: titleCtrl.text.trim(), amount: double.tryParse(amountCtrl.text) ?? 0, category: category, dueDate: dueDate));
                Navigator.pop(ctx);
              },
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text('Add Reminder', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
