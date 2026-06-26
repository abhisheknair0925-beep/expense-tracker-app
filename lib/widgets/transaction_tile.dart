import 'dart:io';
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
  final String currency;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const TransactionTile({super.key, required this.txn, this.currency = 'INR', this.onDelete, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final color = txn.isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed;
    final icon = AppConstants.catIcons[txn.category] ?? Icons.more_horiz_rounded;
    final catColor = AppConstants.catColors[txn.category] ?? color;
    final hasReceipt = txn.receiptPath != null && txn.receiptPath!.isNotEmpty;

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
        onTap: onEdit,
        onLongPress: hasReceipt ? () => _showReceiptViewer(context, txn.receiptPath!) : null,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(txn.title,
                          style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (hasReceipt) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.receipt_long_rounded, color: AppTheme.accentPurple, size: 16),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('${txn.category} · ${Fmt.shortDate(txn.date)}',
                    style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${txn.isIncome ? '+' : '-'} ${Fmt.money(txn.amount, currency)}',
            style: GoogleFonts.poppins(color: color, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          _moreMenu(context),
        ]),
      ),
    );
  }

  Widget _moreMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted, size: 20),
      color: AppTheme.primaryMid,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) {
        if (val == 'edit') onEdit?.call();
        if (val == 'delete') {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.primaryMid,
              title: Text('Delete Transaction', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              content: Text('Are you sure you want to delete this transaction?', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textMuted))),
                TextButton(onPressed: () { Navigator.pop(ctx); onDelete?.call(); }, child: Text('Delete', style: GoogleFonts.poppins(color: AppTheme.expenseRed, fontWeight: FontWeight.w600))),
              ],
            ),
          );
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            const Icon(Icons.edit_rounded, color: AppTheme.accentPurple, size: 18),
            const SizedBox(width: 10),
            Text('Edit', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 13)),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            const Icon(Icons.delete_outline_rounded, color: AppTheme.expenseRed, size: 18),
            const SizedBox(width: 10),
            Text('Delete', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 13)),
          ]),
        ),
      ],
    );
  }

  void _showReceiptViewer(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: GlassCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: path.startsWith('http')
                      ? Image.network(
                          path,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 300,
                              color: AppTheme.glassWhite,
                              child: const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple)),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 200,
                            color: AppTheme.glassWhite,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_rounded, color: AppTheme.textMuted, size: 40),
                                  SizedBox(height: 8),
                                  Text('Failed to load cloud receipt', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Image.file(
                          File(path),
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
