import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';
import 'otp_screen.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _sendCode() {
    if (_formKey.currentState!.validate()) {
      final auth = context.read<AuthProvider>();
      final number = "+91${_phoneController.text.trim()}"; // India default as per request
      
      auth.sendOtp(number, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpScreen(phoneNumber: number)),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  ),
                  const SizedBox(height: 40),
                  Text('Phone Login', 
                    style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('We will send you a 6-digit verification code.', 
                    style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 14)),
                  const SizedBox(height: 40),
                  
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_rounded, color: AppTheme.accentPurple, size: 20),
                              const SizedBox(width: 8),
                              Text('+91', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        hintText: '10-digit number',
                        hintStyle: GoogleFonts.poppins(color: AppTheme.textMuted),
                        border: InputBorder.none,
                      ),
                      validator: (value) => (value?.length != 10) ? "Enter valid 10 digits" : null,
                    ),
                  ),
                  
                  if (auth.error != null) ...[
                    const SizedBox(height: 16),
                    Text(auth.error!, style: GoogleFonts.poppins(color: AppTheme.expenseRed, fontSize: 12)),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  GestureDetector(
                    onTap: auth.loading ? null : _sendCode,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentPurple.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Center(
                        child: auth.loading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Send OTP', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
