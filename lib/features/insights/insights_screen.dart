import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/user_provider.dart';
import 'providers/insights_provider.dart';
import 'widgets/insight_card.dart';
import 'widgets/trend_chart.dart';
import 'widgets/category_chart.dart';
import '../../widgets/glass_card.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  void _refresh() {
    final tp = context.read<TransactionProvider>();
    final bp = context.read<BudgetProvider>();
    final up = context.read<UserProvider>();
    
    context.read<InsightsProvider>().refreshInsights(
      transactionProvider: tp,
      budgetProvider: bp,
      profileId: up.selectedProfile?.profileId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Consumer4<InsightsProvider, TransactionProvider, BudgetProvider, UserProvider>(
            builder: (context, insightsProv, txProv, budgetProv, userProv, _) {
              if (insightsProv.loading && insightsProv.insights.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple));
              }

              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                color: AppTheme.accentPurple,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Advanced Insights',
                              style: GoogleFonts.poppins(
                                color: AppTheme.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh_rounded, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Summary Stats
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _summaryStat(
                                'Monthly Spend',
                                '₹${txProv.expense.toStringAsFixed(0)}',
                                AppTheme.expenseRed,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryStat(
                                'Daily Avg',
                                '₹${(txProv.expense / 30).toStringAsFixed(0)}', // Simplified
                                AppTheme.accentBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Charts Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          'Spending Patterns',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '6-Month Trend',
                                style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              TrendChart(data: txProv.yearlyTrend),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Category Breakdown',
                                style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              Row(
                                children: [
                                  Expanded(child: CategoryChart(data: txProv.catExpenses)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: txProv.catExpenses.entries.take(4).map((e) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            Container(width: 8, height: 8, decoration: BoxDecoration(color: _getCategoryColor(e.key), shape: BoxShape.circle)),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(e.key, style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 11), overflow: TextOverflow.ellipsis)),
                                            Text('${((e.value / txProv.expense) * 100).toStringAsFixed(0)}%', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
                                          ],
                                        ),
                                      )).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Smart Insights List
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          'Smart Insights',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                    if (insightsProv.insights.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('No insights yet. Add more transactions!', style: TextStyle(color: AppTheme.textMuted))),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => InsightCard(insight: insightsProv.insights[index]),
                            childCount: insightsProv.insights.length,
                          ),
                        ),
                      ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _summaryStat(String label, String value, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      AppTheme.accentPurple,
      AppTheme.accentBlue,
      AppTheme.incomeGreen,
      const Color(0xFFFFC107),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
    ];
    return colors[category.hashCode % colors.length];
  }
}
