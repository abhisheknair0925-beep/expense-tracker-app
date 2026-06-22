import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/goal_model.dart';
import '../providers/goal_provider.dart';
import '../utils/formatters.dart';
import '../widgets/glass_card.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Consumer<GoalProvider>(
            builder: (context, provider, _) {
              final activeGoals = provider.goals.where((g) => !g.isCompleted).toList();
              final completedGoals = provider.goals.where((g) => g.isCompleted).toList();

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
                              Text(
                                'Savings Goals',
                                style: GoogleFonts.poppins(
                                  color: AppTheme.textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          GlassCard(
                            margin: EdgeInsets.zero,
                            padding: const EdgeInsets.all(10),
                            radius: 14,
                            onTap: () => _showAddGoal(context),
                            child: const Icon(Icons.add_rounded, color: AppTheme.accentPurple, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Empty State if no goals
                  if (provider.goals.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Icon(Icons.track_changes_rounded, color: AppTheme.textMuted, size: 56),
                            const SizedBox(height: 12),
                            Text(
                              'No savings goals yet',
                              style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap + to create a new milestone',
                              style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Active Goals Section Header
                  if (activeGoals.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Text(
                          'Active Targets',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // Active Goals List
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _goalCard(context, activeGoals[i], provider),
                        childCount: activeGoals.length,
                      ),
                    ),
                  ),

                  // Completed Goals Section Header
                  if (completedGoals.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: Text(
                          'Milestones Completed 🎉',
                          style: GoogleFonts.poppins(
                            color: AppTheme.incomeGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // Completed Goals List
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _goalCard(context, completedGoals[i], provider),
                        childCount: completedGoals.length,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _goalCard(BuildContext context, Goal g, GoalProvider provider) {
    final pct = g.targetAmount > 0 ? (g.currentAmount / g.targetAmount).clamp(0.0, 1.0) : 0.0;
    final color = g.isCompleted ? AppTheme.incomeGreen : AppTheme.accentPurple;
    final daysLeft = g.targetDate.difference(DateTime.now()).inDays;
    final remaining = (g.targetAmount - g.currentAmount).clamp(0.0, double.infinity);
    final icon = AppConstants.catIcons[g.category] ?? Icons.flag_rounded;

    return Dismissible(
      key: Key('goal_${g.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => provider.remove(g.id!),
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.name,
                        style: GoogleFonts.poppins(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        g.category,
                        style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (!g.isCompleted)
                  GestureDetector(
                    onTap: () => _showAddFunds(context, g, provider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+ Fund',
                        style: GoogleFonts.poppins(
                          color: AppTheme.accentPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${Fmt.money(g.currentAmount)} of ${Fmt.money(g.targetAmount)}',
                  style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppTheme.glassWhite,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  g.isCompleted
                      ? 'Completed!'
                      : daysLeft <= 0
                          ? "Due today"
                          : "$daysLeft days left",
                  style: GoogleFonts.poppins(
                    color: g.isCompleted
                        ? AppTheme.incomeGreen
                        : daysLeft <= 7
                            ? AppTheme.expenseRed
                            : AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
                if (!g.isCompleted)
                  Text(
                    '${Fmt.money(remaining)} remaining',
                    style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFunds(BuildContext context, Goal g, GoalProvider provider) {
    final amtCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.primaryMid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Fund "${g.name}"',
          style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: amtCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.poppins(color: AppTheme.textPrimary),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Funding Amount',
            prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppTheme.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amtCtrl.text.trim());
              if (amt != null && amt > 0) {
                provider.fundGoal(g.id!, amt);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Funded ${Fmt.money(amt)} successfully!'),
                    backgroundColor: AppTheme.incomeGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple),
            child: Text('Fund', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddGoal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String category = 'Other';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: AppTheme.primaryMid,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
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
                'Add Goal Target',
                style: GoogleFonts.poppins(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Goal Title',
                  prefixIcon: Icon(Icons.flag_rounded, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amtCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Target Amount',
                  prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                dropdownColor: AppTheme.primaryMid,
                style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_rounded, color: AppTheme.textMuted),
                ),
                items: AppConstants.expenseCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => category = v);
                },
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
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
                          Text('Target Date', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
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
                onTap: () {
                  final name = nameCtrl.text.trim();
                  final target = double.tryParse(amtCtrl.text.trim());
                  if (name.isNotEmpty && target != null && target > 0) {
                    context.read<GoalProvider>().add(Goal(
                      name: name,
                      targetAmount: target,
                      targetDate: selectedDate,
                      category: category,
                      updatedAt: DateTime.now(),
                    ));
                    Navigator.pop(ctx);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'Create Goal',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
