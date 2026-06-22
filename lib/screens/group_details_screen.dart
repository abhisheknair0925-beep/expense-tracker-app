import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/group_model.dart';
import '../models/group_expense_model.dart';
import '../providers/group_provider.dart';
import '../utils/formatters.dart';
import '../widgets/glass_card.dart';

class GroupDetailsScreen extends StatefulWidget {
  final Group group;
  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Consumer<GroupProvider>(
            builder: (context, provider, _) {
              final expenses = provider.expensesForGroup(widget.group.id ?? -1);
              final balances = provider.getNetBalances(widget.group);
              final settlements = provider.getSettlements(widget.group);

              return Column(
                children: [
                  // App Bar / Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        GlassCard(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(8),
                          radius: 12,
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary, size: 22),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.group.name,
                                style: GoogleFonts.poppins(
                                  color: AppTheme.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.group.description != null)
                                Text(
                                  widget.group.description!,
                                  style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Add Member Action
                        IconButton(
                          onPressed: () => _showAddMember(context, provider),
                          icon: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  // Horizontal Members List with Balances
                  Container(
                    height: 80,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: widget.group.members.length,
                      itemBuilder: (ctx, idx) {
                        final m = widget.group.members[idx];
                        final bal = balances[m] ?? 0.0;
                        final isMe = m == 'You';
                        return Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: GlassCard(
                            margin: EdgeInsets.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            radius: 16,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isMe ? AppTheme.accentPurple : AppTheme.glassWhite,
                                  child: Text(
                                    m[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m,
                                      style: GoogleFonts.poppins(
                                        color: AppTheme.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      bal == 0
                                          ? 'Settled'
                                          : bal > 0
                                              ? '+${Fmt.money(bal)}'
                                              : '-${Fmt.money(bal.abs())}',
                                      style: GoogleFonts.poppins(
                                        color: bal == 0
                                            ? AppTheme.textMuted
                                            : bal > 0
                                                ? AppTheme.incomeGreen
                                                : AppTheme.expenseRed,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.glassWhite,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tabCtrl,
                      indicatorColor: AppTheme.accentPurple,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                      unselectedLabelColor: AppTheme.textMuted,
                      labelColor: AppTheme.textPrimary,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Expenses'),
                        Tab(text: 'Settlements'),
                      ],
                    ),
                  ),

                  // Tab View
                  Expanded(
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        // Tab 1: Expenses List
                        expenses.isEmpty
                            ? _emptyState(Icons.receipt_long_rounded, 'No expenses added yet', 'Tap + to add group bills')
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                                itemCount: expenses.length,
                                itemBuilder: (ctx, idx) {
                                  final exp = expenses[idx];
                                  return Dismissible(
                                    key: Key('expense_${exp.id}'),
                                    direction: DismissDirection.endToStart,
                                    onDismissed: (_) => provider.removeExpense(exp.id!, widget.group.id!),
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 24),
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.expenseRed.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(Icons.delete_rounded, color: AppTheme.expenseRed),
                                    ),
                                    child: GlassCard(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  exp.title,
                                                  style: GoogleFonts.poppins(
                                                    color: AppTheme.textPrimary,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                Fmt.money(exp.amount),
                                                style: GoogleFonts.poppins(
                                                  color: AppTheme.textPrimary,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Paid by ${exp.paidBy} · ${Fmt.shortDate(exp.date)}',
                                                style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11),
                                              ),
                                              Text(
                                                exp.splitType.toUpperCase(),
                                                style: GoogleFonts.poppins(
                                                  color: AppTheme.accentPurple,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(color: AppTheme.glassBorder, height: 16),
                                          // Splits breakdown
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: exp.splits.entries.map((entry) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.glassWhite,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '${entry.key}: ${Fmt.money(entry.value)}',
                                                  style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 10),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                        // Tab 2: Settlements List
                        settlements.isEmpty
                            ? _emptyState(Icons.done_all_rounded, 'All debts simplified & settled!', 'Enjoy balance harmony')
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                                itemCount: settlements.length,
                                itemBuilder: (ctx, idx) {
                                  final set = settlements[idx];
                                  return GlassCard(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: RichText(
                                            text: TextSpan(
                                              style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 13),
                                              children: [
                                                TextSpan(
                                                  text: set.from,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentPurple),
                                                ),
                                                const TextSpan(text: ' owes '),
                                                TextSpan(
                                                  text: set.to,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentBlue),
                                                ),
                                                const TextSpan(text: ' '),
                                                TextSpan(
                                                  text: Fmt.money(set.amount),
                                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => _settleUp(context, provider, set.from, set.to, set.amount),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppTheme.incomeGreen.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              'Settle',
                                              style: GoogleFonts.poppins(
                                                color: AppTheme.incomeGreen,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpense(context),
        backgroundColor: AppTheme.accentPurple,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Text(
            sub,
            style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showAddMember(BuildContext context, GroupProvider provider) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.primaryMid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Member',
          style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: GoogleFonts.poppins(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Member Name',
            prefixIcon: Icon(Icons.person_add_rounded, color: AppTheme.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty && !widget.group.members.contains(name)) {
                final updatedMembers = List<String>.from(widget.group.members)..add(name);
                provider.updateGroup(widget.group.copyWith(members: updatedMembers));
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple),
            child: Text('Add', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _settleUp(BuildContext context, GroupProvider provider, String from, String to, double amount) {
    // Settle debt by inserting a settle up transaction
    provider.addExpense(GroupExpense(
      groupId: widget.group.id!,
      title: 'Settled debt: $from ➡️ $to',
      amount: amount,
      paidBy: from,
      date: DateTime.now(),
      splitType: 'equal',
      splits: {to: amount},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settled ${Fmt.money(amount)} from $from to $to!'),
        backgroundColor: AppTheme.incomeGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddExpense(BuildContext context) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String paidBy = 'You';
    String splitType = 'equal';
    DateTime selectedDate = DateTime.now();

    final members = widget.group.members;
    // Map tracking checked state for equal splits, or exact input double splits
    final checkedMembers = Map<String, bool>.fromEntries(members.map((m) => MapEntry(m, true)));
    final unequalInputs = Map<String, TextEditingController>.fromEntries(members.map((m) => MapEntry(m, TextEditingController())));
    final percentageInputs = Map<String, TextEditingController>.fromEntries(members.map((m) => MapEntry(m, TextEditingController())));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          // Calculate validation indicators
          double totalAmount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
          double currentSum = 0.0;
          bool isSplitValid = true;

          if (splitType == 'equal') {
            final activeCount = checkedMembers.values.where((v) => v).length;
            isSplitValid = activeCount > 0 && totalAmount > 0;
          } else if (splitType == 'unequal') {
            currentSum = unequalInputs.entries.fold(0.0, (sum, entry) => sum + (double.tryParse(entry.value.text.trim()) ?? 0.0));
            isSplitValid = totalAmount > 0 && (currentSum - totalAmount).abs() < 0.01;
          } else if (splitType == 'percentage') {
            currentSum = percentageInputs.entries.fold(0.0, (sum, entry) => sum + (double.tryParse(entry.value.text.trim()) ?? 0.0));
            isSplitValid = totalAmount > 0 && (currentSum - 100.0).abs() < 0.01;
          }

          return Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            decoration: const BoxDecoration(
              color: AppTheme.primaryMid,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: AppTheme.glassBorder, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add Shared Expense',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Expense Description',
                      prefixIcon: Icon(Icons.description_rounded, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppTheme.textMuted),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: paidBy,
                    dropdownColor: AppTheme.primaryMid,
                    style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Paid By',
                      prefixIcon: Icon(Icons.person_rounded, color: AppTheme.textMuted),
                    ),
                    items: members.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => paidBy = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: splitType,
                    dropdownColor: AppTheme.primaryMid,
                    style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Split Option',
                      prefixIcon: Icon(Icons.call_split_rounded, color: AppTheme.textMuted),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'equal', child: Text('Split Equally')),
                      DropdownMenuItem(value: 'unequal', child: Text('Split Unequally (Exact amounts)')),
                      DropdownMenuItem(value: 'percentage', child: Text('Split by Percentage')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => splitType = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Split Details',
                    style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  // Equal split detail UI
                  if (splitType == 'equal')
                    Column(
                      children: members.map((m) {
                        return CheckboxListTile(
                          title: Text(m, style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 13)),
                          value: checkedMembers[m],
                          activeColor: AppTheme.accentPurple,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => checkedMembers[m] = val);
                            }
                          },
                        );
                      }).toList(),
                    ),

                  // Unequal split detail UI
                  if (splitType == 'unequal') ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Total Sum: ${Fmt.money(currentSum)} / ${Fmt.money(totalAmount)}',
                        style: GoogleFonts.poppins(
                          color: (currentSum - totalAmount).abs() < 0.01 ? AppTheme.incomeGreen : AppTheme.expenseRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...members.map((m) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text(m, style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 13))),
                            Expanded(
                              child: TextField(
                                controller: unequalInputs[m],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 13),
                                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  // Percentage split detail UI
                  if (splitType == 'percentage') ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Total Sum: ${currentSum.toStringAsFixed(0)}% / 100%',
                        style: GoogleFonts.poppins(
                          color: (currentSum - 100.0).abs() < 0.01 ? AppTheme.incomeGreen : AppTheme.expenseRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...members.map((m) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text(m, style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 13))),
                            Expanded(
                              child: TextField(
                                controller: percentageInputs[m],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 13),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  suffixText: '%',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (c, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppTheme.accentPurple,
                              surface: AppTheme.primaryMid,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: GlassCard(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: AppTheme.textMuted, size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMMM dd, yyyy').format(selectedDate),
                                style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: isSplitValid
                        ? () {
                            final title = titleCtrl.text.trim();
                            if (title.isEmpty || totalAmount <= 0) return;

                            final splits = <String, double>{};
                            if (splitType == 'equal') {
                              final activeMembers = checkedMembers.entries.where((e) => e.value).map((e) => e.key).toList();
                              final share = totalAmount / activeMembers.length;
                              for (final m in activeMembers) {
                                splits[m] = share;
                              }
                            } else if (splitType == 'unequal') {
                              for (final m in members) {
                                splits[m] = double.tryParse(unequalInputs[m]!.text.trim()) ?? 0.0;
                              }
                            } else if (splitType == 'percentage') {
                              for (final m in members) {
                                final pct = double.tryParse(percentageInputs[m]!.text.trim()) ?? 0.0;
                                splits[m] = totalAmount * (pct / 100.0);
                              }
                            }

                            context.read<GroupProvider>().addExpense(GroupExpense(
                              groupId: widget.group.id!,
                              title: title,
                              amount: totalAmount,
                              paidBy: paidBy,
                              date: selectedDate,
                              splitType: splitType,
                              splits: splits,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            ));
                            Navigator.pop(ctx);
                          }
                        : null,
                    child: Opacity(
                      opacity: isSplitValid ? 1.0 : 0.4,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'Add Expense',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
