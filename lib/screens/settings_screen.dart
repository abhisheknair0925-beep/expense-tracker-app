import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/currency_service.dart';
import '../services/security_service.dart';
import '../services/sync_service.dart';
import '../providers/user_provider.dart';
import '../features/profile/profile_switch_screen.dart';
import '../features/auth/phone_input_screen.dart';
import '../models/profile_model.dart';
import '../widgets/glass_card.dart';
import 'bills_screen.dart';
import 'budget_screen.dart';
import 'accounts_screen.dart';
import 'goals_screen.dart';
import 'groups_screen.dart';

/// Settings screen — export, currency, security, sync.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
    final userProvider = context.watch<UserProvider>();
    final currency = userProvider.userProfile?.currency ?? 'INR';

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

            // ─── Financial Tools ────────────────────────────────────
            SliverToBoxAdapter(child: _section('Financial Tools')),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                _tile(Icons.receipt_long_rounded, 'Bill Reminders & Subs', 'Manage recurring bills and detect subscriptions', AppTheme.accentPurple, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                    body: Container(
                      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
                      child: const SafeArea(child: BillsScreen()),
                    ),
                  )));
                }),
                _tile(Icons.track_changes_rounded, 'Budgets & Limits', 'Set and monitor monthly category budgets', AppTheme.accentBlue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                    body: Container(
                      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
                      child: const SafeArea(child: BudgetScreen()),
                    ),
                  )));
                }),
                _tile(Icons.savings_rounded, 'Savings Goals', 'Define, fund, and track savings targets', AppTheme.accentPurple, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen()));
                }),
                _tile(Icons.group_rounded, 'Group Splits', 'Create groups, split bills, and simplify debts', AppTheme.accentBlue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsScreen()));
                }),
                _tile(Icons.account_balance_wallet_rounded, 'Manage Accounts', 'View and manage cash, bank, or credit wallets', AppTheme.incomeGreen, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                    body: Container(
                      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
                      child: const SafeArea(child: AccountsScreen()),
                    ),
                  )));
                }),
              ]),
            )),

            // ─── Currency ───────────────────────────────────────────
            SliverToBoxAdapter(child: _section('Currency')),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: DropdownButtonFormField<String>(
                initialValue: currency, dropdownColor: AppTheme.primaryMid,
                style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                decoration: InputDecoration(border: InputBorder.none, labelText: 'Display Currency', labelStyle: GoogleFonts.poppins(color: AppTheme.textMuted),
                  prefixIcon: const Icon(Icons.currency_exchange_rounded, color: AppTheme.textMuted)),
                items: CurrencyService.instance.supportedCurrencies.map((c) => DropdownMenuItem(value: c,
                  child: Text('$c (${CurrencyService.symbols[c] ?? c})'))).toList(),
                onChanged: (v) { if (v != null) userProvider.updateCurrency(v); },
              )),
            )),
            if (currency != 'INR')
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GlassCard(padding: const EdgeInsets.all(14), child: Builder(builder: (ctx) {
                  final p = context.watch<TransactionProvider>();
                  return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _miniConvert('Balance', p.balance, currency),
                    _miniConvert('Income', p.income, currency),
                    _miniConvert('Expense', p.expense, currency),
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

            // ─── Profile Management ──────────────────────────────
            SliverToBoxAdapter(child: _section('Profile Management')),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                Consumer<UserProvider>(builder: (context, userProvider, _) {
                  return _tile(
                    userProvider.selectedProfile?.profileType == ProfileType.personal ? Icons.person_outline : Icons.business,
                    'Switch Profile',
                    'Active: ${userProvider.selectedProfile?.profileType.name.toUpperCase()}',
                    AppTheme.accentPurple,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSwitchScreen())),
                  );
                }),
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
                      child: auth.photoUrl == null ? Text(auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : '?', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)) : null),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(auth.displayName, style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(auth.email ?? '', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
                    ])),
                  ])),
                  
                  // Account Linking
                  if (!auth.linkedProviders.contains('google.com'))
                    _tile(Icons.link_rounded, 'Link Google Account', 'Secure your account with Google', AppTheme.accentBlue, () async {
                      await auth.signInWithGoogle();
                    }),
                  if (!auth.linkedProviders.contains('phone'))
                    _tile(Icons.add_to_home_screen_rounded, 'Link Phone Number', 'Use phone for quick login', AppTheme.incomeGreen, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneInputScreen()));
                    }),

                  // Sync button
                  _tile(Icons.cloud_sync_rounded, 'Sync Now', SyncService.instance.statusText, AppTheme.accentBlue, () => auth.manualSync()),
                  // Sign out
                  _tile(Icons.logout_rounded, 'Sign Out', 'Remove account from this device', AppTheme.expenseRed, () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.primaryMid,
                        title: Text('Sign Out', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                        content: Text('Are you sure you want to sign out? Your local data will remain, but cloud sync will stop.', 
                          style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textMuted))),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Sign Out', style: GoogleFonts.poppins(color: AppTheme.expenseRed, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      await auth.signOut();
                      if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                    }
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
    Text(CurrencyService.instance.format(amount, currency, convertFromInr: true), style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
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
