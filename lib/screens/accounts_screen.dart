import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/account_model.dart';
import '../providers/account_provider.dart';
import '../utils/formatters.dart';
import '../widgets/glass_card.dart';

/// Accounts management screen — view, add, delete accounts.
class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, p, _) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Accounts', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
                GlassCard(
                  margin: EdgeInsets.zero, padding: const EdgeInsets.all(10), radius: 14,
                  onTap: () => _showAdd(context),
                  child: const Icon(Icons.add_rounded, color: AppTheme.accentPurple, size: 22),
                ),
              ]),
            )),
            // Net worth card
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Text('Net Worth', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  ShaderMask(
                    shaderCallback: (b) => AppTheme.accentGradient.createShader(b),
                    child: Text(Fmt.money(p.totalBalance), style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 4),
                  Text('${p.accounts.length} account${p.accounts.length == 1 ? '' : 's'}', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
                ]),
              ),
            )),
            // Account list
            if (p.accounts.isEmpty)
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(children: [
                  const Icon(Icons.account_balance_rounded, color: AppTheme.textMuted, size: 56),
                  const SizedBox(height: 12),
                  Text('No accounts', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('Tap + to add one', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12)),
                ]),
              ))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _tile(context, p.accounts[i], p),
                  childCount: p.accounts.length,
                )),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _tile(BuildContext context, Account a, AccountProvider p) {
    final icon = AppConstants.accountIcons[a.type] ?? Icons.account_balance_wallet_rounded;
    final color = a.type == 'bank' ? AppTheme.accentBlue : a.type == 'wallet' ? AppTheme.accentPurple : AppTheme.incomeGreen;
    return Dismissible(
      key: Key('acc_${a.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => p.remove(a.id!),
      background: Container(
        alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: AppTheme.expenseRed.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_rounded, color: AppTheme.expenseRed),
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.name, style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
            Text(a.type[0].toUpperCase() + a.type.substring(1), style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12)),
          ])),
          Text(Fmt.money(a.balance), style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  void _showAdd(BuildContext context) {
    final nameCtrl = TextEditingController();
    final balCtrl = TextEditingController(text: '0');
    String type = 'cash';

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: const BoxDecoration(color: AppTheme.primaryMid, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.glassBorder, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Add Account', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, style: GoogleFonts.poppins(color: AppTheme.textPrimary), decoration: const InputDecoration(labelText: 'Account Name', prefixIcon: Icon(Icons.label_rounded, color: AppTheme.textMuted))),
            const SizedBox(height: 12),
            TextField(controller: balCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: GoogleFonts.poppins(color: AppTheme.textPrimary), decoration: const InputDecoration(labelText: 'Opening Balance', prefixIcon: Icon(Icons.currency_rupee_rounded, color: AppTheme.textMuted))),
            const SizedBox(height: 14),
            // Type selector
            Row(children: AppConstants.accountTypes.map((t) {
              final active = type == t;
              return Expanded(child: GestureDetector(
                onTap: () => setState(() => type = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.accentPurple.withValues(alpha: 0.2) : AppTheme.glassWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: active ? AppTheme.accentPurple : AppTheme.glassBorder),
                  ),
                  child: Column(children: [
                    Icon(AppConstants.accountIcons[t]!, color: active ? AppTheme.accentPurple : AppTheme.textMuted, size: 22),
                    const SizedBox(height: 4),
                    Text(t[0].toUpperCase() + t.substring(1), style: GoogleFonts.poppins(color: active ? AppTheme.accentPurple : AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ));
            }).toList()),
            const SizedBox(height: 20),
            // Save
            GestureDetector(
              onTap: () {
                if (nameCtrl.text.trim().isEmpty) return;
                context.read<AccountProvider>().add(Account(name: nameCtrl.text.trim(), type: type, balance: double.tryParse(balCtrl.text) ?? 0));
                Navigator.pop(ctx);
              },
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text('Add Account', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
