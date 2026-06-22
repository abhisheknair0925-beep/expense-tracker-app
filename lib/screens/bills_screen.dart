import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/bill_model.dart';
import '../providers/bill_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/subscription_service.dart';
import '../utils/formatters.dart';
import '../widgets/glass_card.dart';

/// Bill reminders screen — manage recurring bills and detect subscriptions.
class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  int _tabIndex = 0; // 0 = Active Reminders, 1 = Auto-Detected Subs

  @override
  Widget build(BuildContext context) {
    final billP = context.watch<BillProvider>();
    final txnP = context.watch<TransactionProvider>();

    // Run subscription detection
    final detectedSubs = SubscriptionService.instance.detect(txnP.all);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (Navigator.canPop(context)) ...[
                      GlassCard(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(8),
                        radius: 12,
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary, size: 22),
                      ),
                    ],
                    Text('Bill Reminders', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                  ],
                ),
                GlassCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(10),
                  radius: 14,
                  onTap: () => _showAdd(context),
                  child: const Icon(Icons.add_rounded, color: AppTheme.accentPurple, size: 22),
                ),
              ],
            ),
          ),
        ),

        // Tabs Toggle (Reminders vs Detected)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GlassCard(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _tabToggle('Active Reminders', 0),
                  const SizedBox(width: 4),
                  _tabToggle('Auto-Detected', 1),
                ],
              ),
            ),
          ),
        ),

        // Content conditional on Tab
        if (_tabIndex == 0) ...[
          // Active Reminders tab
          if (billP.overdue.isNotEmpty || billP.dueSoon.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (billP.overdue.isNotEmpty)
                      Expanded(child: _statusCard('Overdue', '${billP.overdue.length}', Icons.warning_rounded, AppTheme.expenseRed)),
                    if (billP.overdue.isNotEmpty && billP.dueSoon.isNotEmpty) const SizedBox(width: 10),
                    if (billP.dueSoon.isNotEmpty)
                      Expanded(child: _statusCard('Due Soon', Fmt.money(billP.totalUpcoming), Icons.schedule_rounded, AppTheme.accentBlue)),
                  ],
                ),
              ),
            ),

          if (billP.bills.isEmpty)
            SliverToBoxAdapter(child: _emptyReminders())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _billTile(context, billP.bills[i], billP),
                  childCount: billP.bills.length,
                ),
              ),
            ),
        ] else ...[
          // Auto-Detected tab
          if (detectedSubs.isEmpty)
            SliverToBoxAdapter(child: _emptyDetected())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _detectedTile(context, detectedSubs[i]),
                  childCount: detectedSubs.length,
                ),
              ),
            ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _tabToggle(String label, int index) {
    final active = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppTheme.accentPurple.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? AppTheme.accentPurple : Colors.transparent, width: 1),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: active ? AppTheme.accentPurple : AppTheme.textMuted,
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusCard(String label, String value, IconData icon, Color color) => GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
                  Text(value, style: GoogleFonts.poppins(color: color, fontSize: 16, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
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
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: AppTheme.expenseRed.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_rounded, color: AppTheme.expenseRed),
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.title, style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(status, style: GoogleFonts.poppins(color: statusColor, fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                    child: Text(
                      b.isPaid ? 'Paid' : 'Mark Paid',
                      style: GoogleFonts.poppins(color: b.isPaid ? AppTheme.incomeGreen : AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detectedTile(BuildContext context, DetectedSubscription s) {
    final icon = AppConstants.catIcons[s.category] ?? Icons.sync_rounded;
    final color = AppConstants.catColors[s.category] ?? AppTheme.accentPurple;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title[0].toUpperCase() + s.title.substring(1), style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('Detected ${s.frequency} (last: ${Fmt.date(s.lastCharged)})', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Fmt.money(s.amount), style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _showAdd(context, title: s.title, amount: s.amount, category: s.category),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.accentPurple),
                  ),
                  child: Text(
                    '+ Add Reminder',
                    style: GoogleFonts.poppins(color: AppTheme.accentPurple, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyReminders() => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.notifications_none_rounded, color: AppTheme.textMuted, size: 56),
            const SizedBox(height: 12),
            Text('No active reminders', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('Tap + to add a recurring bill', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
      );

  Widget _emptyDetected() => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.psychology_outlined, color: AppTheme.textMuted, size: 56),
            const SizedBox(height: 12),
            Text('No recurring subscriptions detected', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('Keep adding transactions. The system automatically scans for recurring payments.', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      );

  void _showAdd(BuildContext context, {String? title, double? amount, String? category}) {
    final titleCtrl = TextEditingController(text: title);
    final amountCtrl = TextEditingController(text: amount != null ? amount.toStringAsFixed(0) : '');
    String selectedCategory = category ?? AppConstants.expenseCategories.first;
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: const BoxDecoration(color: AppTheme.primaryMid, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.glassBorder, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Add Bill Reminder', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(controller: titleCtrl, style: GoogleFonts.poppins(color: AppTheme.textPrimary), decoration: const InputDecoration(labelText: 'Bill Name', prefixIcon: Icon(Icons.receipt_rounded, color: AppTheme.textMuted))),
              const SizedBox(height: 12),
              TextField(controller: amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: GoogleFonts.poppins(color: AppTheme.textPrimary), decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppTheme.textMuted))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                dropdownColor: AppTheme.primaryMid,
                style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_rounded, color: AppTheme.textMuted)),
                items: AppConstants.billCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => selectedCategory = v);
                },
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (c, child) => Theme(
                      data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.accentPurple, surface: AppTheme.primaryMid)),
                      child: child!,
                    ),
                  );
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
                  context.read<BillProvider>().add(Bill(
                        title: titleCtrl.text.trim(),
                        amount: double.tryParse(amountCtrl.text) ?? 0,
                        category: selectedCategory,
                        dueDate: dueDate,
                      ));
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(16)),
                  child: Center(child: Text('Add Reminder', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
