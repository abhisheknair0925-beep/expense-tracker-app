import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  Future<void> _verify(String code) async {
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(code);
    if (success && mounted) {
      // If we are linking, we want to go back to settings
      // If we are logging in, AuthGate handles it
      if (Navigator.canPop(context)) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 56,
      textStyle: GoogleFonts.poppins(fontSize: 22, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                ),
                const SizedBox(height: 40),
                Text('Verification', 
                  style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 14),
                    children: [
                      const TextSpan(text: 'Enter the code sent to '),
                      TextSpan(text: widget.phoneNumber, style: const TextStyle(color: AppTheme.accentPurple, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                
                Center(
                  child: Pinput(
                    length: 6,
                    controller: _otpController,
                    onCompleted: _verify,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(color: AppTheme.accentPurple),
                        boxShadow: [
                          BoxShadow(color: AppTheme.accentPurple.withValues(alpha: 0.2), blurRadius: 10)
                        ],
                      ),
                    ),
                    errorPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(color: AppTheme.expenseRed),
                      ),
                    ),
                  ),
                ),
                
                if (auth.error != null) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Text(auth.error!, 
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: AppTheme.expenseRed, fontSize: 13)),
                  ),
                ],
                
                const Spacer(),
                
                Center(
                  child: TextButton(
                    onPressed: auth.loading ? null : () => Navigator.pop(context),
                    child: Text('Wrong number? Edit phone', 
                      style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 13, decoration: TextDecoration.underline)),
                  ),
                ),
                const SizedBox(height: 16),
                
                GestureDetector(
                  onTap: auth.loading ? null : () => _verify(_otpController.text),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: auth.loading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Verify & Continue', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
