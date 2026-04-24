import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass_card.dart';

/// Premium glassmorphism login screen.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(children: [
              const Spacer(flex: 2),
              // Logo
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: AppTheme.accentPurple.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 10))]),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 28),
              Text('Expense Tracker', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Smart personal finance\nmanagement', textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 14, height: 1.5)),
              const Spacer(flex: 2),

              // Error message
              if (auth.error != null) Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GlassCard(padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: AppTheme.expenseRed, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(auth.error!, style: GoogleFonts.poppins(color: AppTheme.expenseRed, fontSize: 12))),
                  ])),
              ),

              // Google Sign-In button
              GestureDetector(
                onTap: auth.loading ? null : () => auth.signInWithGoogle(),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (auth.loading)
                      const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppTheme.accentPurple, strokeWidth: 2.5))
                    else ...[
                      Container(
                        width: 28, height: 28, padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: const Text('G', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF4285F4), fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 14),
                      Text('Continue with Google', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ]),
                ),
              ),
              const SizedBox(height: 14),

              // Phone login placeholder
              GestureDetector(
                onTap: () => _showPhoneStub(context),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.phone_rounded, color: AppTheme.textMuted, size: 22),
                    const SizedBox(width: 14),
                    Text('Continue with Phone', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              // Skip button (use without login)
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/home'),
                child: Text('Skip for now', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 13, decoration: TextDecoration.underline, decorationColor: AppTheme.textMuted)),
              ),
              const Spacer(),

              Text('Your data is encrypted & secure', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ),
    );
  }

  void _showPhoneStub(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Phone login coming soon!', style: GoogleFonts.poppins()),
      backgroundColor: AppTheme.accentPurple.withValues(alpha: 0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}
