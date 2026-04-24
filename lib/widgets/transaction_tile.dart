import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';
import 'glass_card.dart';

/// Transaction list tile with category icon and swipe-to-delete.
class TransactionTile extends StatelessWidget {
  final Txn txn;
  final VoidCallback? onDelete;

  const TransactionTile({super.key, required this.txn, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = txn.isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed;
    final icon = AppConstants.catIcons[txn.category] ?? Icons.more_horiz_rounded;
    final catColor = AppConstants.catColors[txn.category] ?? color;

    return Dismissible(
      key: Key('txn_${txn.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
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
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: catColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.title,
                    style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${txn.category} · ${Fmt.shortDate(txn.date)}',
                    style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${txn.isIncome ? '+' : '-'} ${Fmt.money(txn.amount)}',
            style: GoogleFonts.poppins(color: color, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );
  }
}
