import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/account_provider.dart';
import '../providers/bill_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';
import 'accounts_screen.dart';
import 'add_transaction_screen.dart';
import 'bills_screen.dart';
import 'budget_screen.dart';
import 'home_screen.dart';
import 'insights_screen.dart';
import 'transactions_screen.dart';

/// Root shell with bottom navigation bar and FAB.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().load();
      context.read<AccountProvider>().load();
      context.read<BillProvider>().load();
      context.read<BudgetProvider>().load();
    });
  }

  void _openAdd() {
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (c, a, s) => const AddTransactionScreen(),
      transitionsBuilder: (c, anim, s, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: IndexedStack(index: _tab, children: const [
            HomeContent(),
            TransactionsScreen(),
            AccountsScreen(),
            BillsScreen(),
            InsightsScreen(),
            BudgetScreen(),
          ]),
        ),
      ),
      bottomNavigationBar: _nav(),
      floatingActionButton: _fab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _nav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 72,
          decoration: const BoxDecoration(
            color: AppTheme.glassWhite,
            border: Border(top: BorderSide(color: AppTheme.glassBorder, width: 0.5)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _navItem(Icons.home_rounded, 'Home', 0),
            _navItem(Icons.swap_horiz_rounded, 'History', 1),
            const SizedBox(width: 48), // FAB gap
            _navItem(Icons.pie_chart_rounded, 'Budget', 5),
            _navItem(Icons.auto_awesome_rounded, 'Insights', 4),
          ]),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = _tab == index;
    final color = active ? AppTheme.accentPurple : AppTheme.textMuted;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: active ? AppTheme.accentPurple.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.poppins(color: color, fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
        ]),
      ),
    );
  }

  Widget _fab() => Container(
    width: 56, height: 56,
    decoration: BoxDecoration(
      shape: BoxShape.circle, gradient: AppTheme.accentGradient,
      boxShadow: [BoxShadow(color: AppTheme.accentPurple.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 6))],
    ),
    child: FloatingActionButton(onPressed: _openAdd, backgroundColor: Colors.transparent, elevation: 0, child: const Icon(Icons.add_rounded, size: 28)),
  );
}
