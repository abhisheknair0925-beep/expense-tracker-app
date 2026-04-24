import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../providers/transaction_provider.dart';
import '../widgets/glass_filter_chips.dart';
import '../widgets/glass_search_bar.dart';
import '../widgets/transaction_tile.dart';

/// Transactions list with search bar and filter chips.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, p, _) {
        final list = p.filtered;
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Title
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text('Transactions', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
            )),
            // Search bar
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: GlassSearchBar(controller: _searchCtrl, onChanged: (q) => p.setSearch(q)),
            )),
            // Filter chips
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: GlassFilterChips(
                options: AppConstants.filterOptions,
                selected: p.filter,
                onSelected: (f) => p.setFilter(f),
              ),
            )),
            // Count
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text('${list.length} result${list.length == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
            )),
            // List or empty
            if (list.isEmpty)
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(children: [
                  Icon(p.search.isNotEmpty ? Icons.search_off_rounded : Icons.receipt_long_rounded,
                      color: AppTheme.textMuted, size: 56),
                  const SizedBox(height: 12),
                  Text(p.search.isNotEmpty ? 'No results' : 'No transactions',
                      style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(p.search.isNotEmpty ? 'Try a different term' : 'Add one with the + button',
                      style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12)),
                ]),
              ))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final t = list[i];
                    return TransactionTile(txn: t, onDelete: () {
                      p.remove(t.id!);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Deleted', style: GoogleFonts.poppins()),
                        backgroundColor: AppTheme.primaryMid,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ));
                    });
                  },
                  childCount: list.length,
                )),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }
}
