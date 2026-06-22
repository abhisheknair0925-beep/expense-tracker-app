import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/group_model.dart';
import '../providers/group_provider.dart';
import '../utils/formatters.dart';
import '../widgets/glass_card.dart';
import 'group_details_screen.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Consumer<GroupProvider>(
            builder: (context, provider, _) {
              // Calculate aggregate net balance for "You"
              double totalNetBalance = 0;
              for (final group in provider.groups) {
                final balances = provider.getNetBalances(group);
                totalNetBalance += balances['You'] ?? 0.0;
              }

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
                                'Group Splits',
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
                            onTap: () => _showAddGroup(context, provider),
                            child: const Icon(Icons.group_add_rounded, color: AppTheme.accentPurple, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Overall balance card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: (totalNetBalance >= 0 ? AppTheme.incomeGreen : AppTheme.expenseRed).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                totalNetBalance >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                color: totalNetBalance >= 0 ? AppTheme.incomeGreen : AppTheme.expenseRed,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Aggregate Balance',
                                    style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    totalNetBalance == 0
                                        ? 'You are all settled up!'
                                        : totalNetBalance > 0
                                            ? 'Overall, you are owed ${Fmt.money(totalNetBalance)}'
                                            : 'Overall, you owe ${Fmt.money(totalNetBalance.abs())}',
                                    style: GoogleFonts.poppins(
                                      color: totalNetBalance == 0
                                          ? AppTheme.textPrimary
                                          : totalNetBalance > 0
                                              ? AppTheme.incomeGreen
                                              : AppTheme.expenseRed,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Empty State if no groups
                  if (provider.groups.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Icon(Icons.group_work_rounded, color: AppTheme.textMuted, size: 56),
                            const SizedBox(height: 12),
                            Text(
                              'No split groups yet',
                              style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap + to create a new shared group',
                              style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Groups List
                  if (provider.groups.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final g = provider.groups[i];
                            final balances = provider.getNetBalances(g);
                            final myBal = balances['You'] ?? 0.0;
                            final expenseCount = provider.expensesForGroup(g.id ?? -1).length;

                            return Dismissible(
                              key: Key('group_${g.id}'),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => provider.removeGroup(g.id!),
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
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => GroupDetailsScreen(group: g)),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentPurple.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.group_rounded, color: AppTheme.accentPurple, size: 20),
                                    ),
                                    const SizedBox(width: 14),
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
                                            '${g.members.length} members · $expenseCount expenses',
                                            style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          myBal == 0
                                              ? 'Settled'
                                              : myBal > 0
                                                  ? '+${Fmt.money(myBal)}'
                                                  : '-${Fmt.money(myBal.abs())}',
                                          style: GoogleFonts.poppins(
                                            color: myBal == 0
                                                ? AppTheme.textMuted
                                                : myBal > 0
                                                    ? AppTheme.incomeGreen
                                                    : AppTheme.expenseRed,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          myBal == 0
                                              ? 'No debt'
                                              : myBal > 0
                                                  ? 'owed to you'
                                                  : 'you owe',
                                          style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 9),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 18),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: provider.groups.length,
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

  void _showAddGroup(BuildContext context, GroupProvider provider) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final memberCtrl = TextEditingController();
    final members = <String>['You'];

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
                'Create Splitting Group',
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
                  labelText: 'Group Name',
                  prefixIcon: Icon(Icons.group_work_rounded, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.description_rounded, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Members',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              // Member chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: members.map((m) {
                  final isMe = m == 'You';
                  return Chip(
                    label: Text(m, style: GoogleFonts.poppins(color: isMe ? Colors.white : AppTheme.textPrimary, fontSize: 12)),
                    backgroundColor: isMe ? AppTheme.accentPurple : AppTheme.glassWhite,
                    side: const BorderSide(color: AppTheme.glassBorder),
                    deleteIcon: isMe ? null : const Icon(Icons.close_rounded, size: 14, color: AppTheme.textMuted),
                    onDeleted: isMe ? null : () => setState(() => members.remove(m)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: memberCtrl,
                      style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Add Member Name',
                        prefixIcon: Icon(Icons.person_add_rounded, color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      final name = memberCtrl.text.trim();
                      if (name.isNotEmpty && !members.contains(name)) {
                        setState(() {
                          members.add(name);
                          memberCtrl.clear();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.add_rounded, color: AppTheme.accentPurple, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  final name = nameCtrl.text.trim();
                  if (name.isNotEmpty && members.length > 1) {
                    provider.addGroup(Group(
                      name: name,
                      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      members: members,
                      createdAt: DateTime.now(),
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
                      'Create Group',
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
