import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../providers/transaction_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/group_provider.dart';
import '../providers/user_provider.dart';
import '../utils/formatters.dart';
import '../widgets/chart_widgets.dart';
import '../widgets/glass_card.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'settings_screen.dart';
import 'goals_screen.dart';
import 'groups_screen.dart';

/// Home dashboard content — used inside ShellScreen.
class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final currency = userProvider.userProfile?.currency ?? 'INR';

    return Consumer<TransactionProvider>(
      builder: (context, p, _) {
        if (p.loading) return const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple));
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header(context, p)),
            SliverToBoxAdapter(child: _balanceCard(p, currency)),
            SliverToBoxAdapter(child: _summaryRow(p, currency)),
            SliverToBoxAdapter(child: _goalsCard(context, currency)),
            SliverToBoxAdapter(child: _groupsCard(context, currency)),
            SliverToBoxAdapter(child: _topCategories(p, currency)),
            // Charts
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CategoryPieChart(data: p.catExpenses, currency: currency),
            )),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MonthlyBarChart(data: p.yearlyTrend, currency: currency),
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
                    return TransactionTile(
                      txn: t, 
                      currency: currency,
                      onDelete: () => p.remove(t.id!),
                      onEdit: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AddTransactionScreen(transactionToEdit: t),
                      )),
                    );
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
  Widget _balanceCard(TransactionProvider p, String currency) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(children: [
        Text('Total Balance', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        ShaderMask(
          shaderCallback: (b) => AppTheme.accentGradient.createShader(b),
          child: Text(Fmt.money(p.balance, currency), style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 4),
        Text('${p.monthly.length} transactions this month', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
      ]),
    ),
  );

  // ─── Income / Expense cards ───────────────────────────────────────
  Widget _summaryRow(TransactionProvider p, String currency) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(children: [
      Expanded(child: _summaryCard(Icons.arrow_downward_rounded, 'Income', p.income, AppTheme.incomeGreen, currency)),
      const SizedBox(width: 12),
      Expanded(child: _summaryCard(Icons.arrow_upward_rounded, 'Expense', p.expense, AppTheme.expenseRed, currency)),
    ]),
  );

  Widget _summaryCard(IconData icon, String label, double amount, Color color, String currency) => GlassCard(
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
        Text(Fmt.money(amount, currency), style: GoogleFonts.poppins(color: color, fontSize: 16, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
    ]),
  );

  // ─── Top categories preview ───────────────────────────────────────
  Widget _topCategories(TransactionProvider p, String currency) {
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
                    Text(Fmt.money(e.value, currency), style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11)),
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

  Widget _goalsCard(BuildContext context, String currency) {
    return Consumer<GoalProvider>(
      builder: (context, goalProvider, _) {
        final activeGoals = goalProvider.goals.where((g) => !g.isCompleted).toList();
        if (activeGoals.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: GlassCard(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.accentPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.savings_rounded, color: AppTheme.accentPurple, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Savings Goals',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Set milestones and start tracking your savings target',
                          style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
                ],
              ),
            ),
          );
        }

        double totalTarget = 0;
        double totalCurrent = 0;
        for (final g in activeGoals) {
          totalTarget += g.targetAmount;
          totalCurrent += g.currentAmount;
        }
        final aggregateProgress = totalTarget > 0 ? (totalCurrent / totalTarget).clamp(0.0, 1.0) : 0.0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: GlassCard(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen())),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.accentPurple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.savings_rounded, color: AppTheme.accentPurple, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Savings Goals (${activeGoals.length})',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saved ${Fmt.money(totalCurrent, currency)} of ${Fmt.money(totalTarget, currency)}',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(aggregateProgress * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.poppins(
                        color: AppTheme.accentPurple,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: aggregateProgress,
                    backgroundColor: AppTheme.glassWhite,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentPurple),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _groupsCard(BuildContext context, String currency) {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, _) {
        final groups = groupProvider.groups;
        if (groups.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: GlassCard(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsScreen())),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.group_rounded, color: AppTheme.accentBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Group Splits',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Create groups, split bills, and track shared balances',
                          style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
                ],
              ),
            ),
          );
        }

        double totalNetBalance = 0;
        for (final group in groups) {
          final balances = groupProvider.getNetBalances(group);
          totalNetBalance += balances['You'] ?? 0.0;
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: GlassCard(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsScreen())),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.group_rounded, color: AppTheme.accentBlue, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Group Splits (${groups.length})',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: totalNetBalance == 0
                            ? AppTheme.textMuted
                            : totalNetBalance > 0
                                ? AppTheme.incomeGreen
                                : AppTheme.expenseRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        totalNetBalance == 0
                            ? 'All settled up'
                            : totalNetBalance > 0
                                ? 'Overall, you are owed ${Fmt.money(totalNetBalance, currency)}'
                                : 'Overall, you owe ${Fmt.money(totalNetBalance.abs(), currency)}',
                        style: GoogleFonts.poppins(
                          color: totalNetBalance == 0
                              ? AppTheme.textSecondary
                              : totalNetBalance > 0
                                  ? AppTheme.incomeGreen
                                  : AppTheme.expenseRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
