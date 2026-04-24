import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/currency_service.dart';
import '../services/export_service.dart';
import '../services/security_service.dart';
import '../services/sync_service.dart';
import '../widgets/glass_card.dart';

/// Settings screen — export, currency, security, sync.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currency = 'INR';
  bool _lockEnabled = false;
  bool _bioEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final lock = await SecurityService.instance.isLockEnabled;
    final bio = await SecurityService.instance.isBiometricEnabled;
    if (mounted) setState(() { _lockEnabled = lock; _bioEnabled = bio; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(children: [
                GlassCard(margin: EdgeInsets.zero, padding: const EdgeInsets.all(8), radius: 12, onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary, size: 22)),
                const SizedBox(width: 14),
                Text('Settings', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
              ]),
            )),

            // ─── Export ─────────────────────────────────────────────
            SliverToBoxAdapter(child: _section('Export & Reports')),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                _tile(Icons.description_rounded, 'Export CSV', 'Download transactions as CSV', AppTheme.incomeGreen, () {
                  final p = context.read<TransactionProvider>();
                  ExportService.instance.exportCsv(p.monthly);
                }),
                _tile(Icons.summarize_rounded, 'Monthly Report', 'Share a text summary report', AppTheme.accentBlue, () {
                  final p = context.read<TransactionProvider>();
                  ExportService.instance.exportReport(p.monthly, month: p.month, year: p.year, income: p.income, expense: p.expense);
                }),
              ]),
            )),

            // ─── Currency ───────────────────────────────────────────
            SliverToBoxAdapter(child: _section('Currency')),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: DropdownButtonFormField<String>(
                initialValue: _currency, dropdownColor: AppTheme.primaryMid,
                style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                decoration: InputDecoration(border: InputBorder.none, labelText: 'Display Currency', labelStyle: GoogleFonts.poppins(color: AppTheme.textMuted),
                  prefixIcon: const Icon(Icons.currency_exchange_rounded, color: AppTheme.textMuted)),
                items: CurrencyService.instance.supportedCurrencies.map((c) => DropdownMenuItem(value: c,
                  child: Text('$c (${CurrencyService.symbols[c] ?? c})'))).toList(),
                onChanged: (v) { if (v != null) setState(() => _currency = v); },
              )),
            )),
            if (_currency != 'INR')
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GlassCard(padding: const EdgeInsets.all(14), child: Builder(builder: (ctx) {
                  final p = context.watch<TransactionProvider>();
                  return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _miniConvert('Balance', p.balance, _currency),
                    _miniConvert('Income', p.income, _currency),
                    _miniConvert('Expense', p.expense, _currency),
                  ]);
                })),
              )),

            // ─── Security ───────────────────────────────────────────
            SliverToBoxAdapter(child: _section('Security')),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                GlassCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: Row(children: [
                  const Icon(Icons.lock_rounded, color: AppTheme.textMuted),
                  const SizedBox(width: 12),
                  Expanded(child: Text('App Lock (PIN)', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14))),
                  Switch.adaptive(value: _lockEnabled, activeTrackColor: AppTheme.accentPurple, onChanged: (v) => v ? _setupPin() : _disableLock()),
                ])),
                if (_lockEnabled)
                  GlassCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: Row(children: [
                    const Icon(Icons.fingerprint_rounded, color: AppTheme.textMuted),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Biometric Unlock', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14))),
                    Switch.adaptive(value: _bioEnabled, activeTrackColor: AppTheme.accentPurple, onChanged: (v) async {
                      await SecurityService.instance.setBiometric(v);
                      setState(() => _bioEnabled = v);
                    }),
                  ])),
              ]),
            )),

            // ─── Account & Cloud Sync ─────────────────────────────
            SliverToBoxAdapter(child: _section('Account & Cloud Sync')),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer<AuthProvider>(builder: (ctx, auth, _) {
                if (!auth.isSignedIn) {
                  return _tile(Icons.cloud_off_rounded, 'Not Signed In', 'Sign in to sync data across devices', AppTheme.textMuted, () {
                    Navigator.pushReplacementNamed(context, '/login');
                  });
                }
                return Column(children: [
                  // User profile card
                  GlassCard(padding: const EdgeInsets.all(14), child: Row(children: [
                    CircleAvatar(radius: 20, backgroundColor: AppTheme.accentPurple,
                      backgroundImage: auth.photoUrl != null ? NetworkImage(auth.photoUrl!) : null,
                      child: auth.photoUrl == null ? Text(auth.displayName[0], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)) : null),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(auth.displayName, style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(auth.email ?? '', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
                    ])),
                  ])),
                  // Sync button
                  _tile(Icons.cloud_sync_rounded, 'Sync Now', SyncService.instance.statusText, AppTheme.accentBlue, () => auth.manualSync()),
                  // Sign out
                  _tile(Icons.logout_rounded, 'Sign Out', 'Remove account from this device', AppTheme.expenseRed, () async {
                    await auth.signOut();
                    if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                  }),
                ]);
              }),
            )),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        )),
      ),
    );
  }

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
    child: Text(label, style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
  );

  Widget _tile(IconData icon, String title, String sub, Color color, VoidCallback? onTap) => GlassCard(
    onTap: onTap, padding: const EdgeInsets.all(14),
    child: Row(children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
        child: Icon(icon, color: color, size: 20)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        Text(sub, style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
      ])),
      if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
    ]),
  );

  Widget _miniConvert(String label, double amount, String currency) => Column(children: [
    Text(label, style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 10)),
    Text(CurrencyService.instance.format(amount, currency), style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
  ]);

  void _setupPin() {
    final ctrl = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        decoration: const BoxDecoration(color: AppTheme.primaryMid, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.glassBorder, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Set PIN', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          TextField(controller: ctrl, keyboardType: TextInputType.number, obscureText: true, maxLength: 4,
            style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 12),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(counterText: '', labelText: '4-digit PIN', prefixIcon: Icon(Icons.lock_rounded, color: AppTheme.textMuted))),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              if (ctrl.text.length != 4) return;
              await SecurityService.instance.setPin(ctrl.text);
              if (!context.mounted) return;
              Navigator.pop(ctx);
              setState(() => _lockEnabled = true);
            },
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text('Set PIN', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)))),
          ),
        ]),
      ),
    );
  }

  Future<void> _disableLock() async {
    await SecurityService.instance.disableLock();
    setState(() { _lockEnabled = false; _bioEnabled = false; });
  }
}
