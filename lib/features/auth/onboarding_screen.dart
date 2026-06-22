import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/glass_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  OnboardingPurpose _selectedPurpose = OnboardingPurpose.personal;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController.text = auth.user?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Setup Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Welcome to Expense Tracker!',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Let\'s customize your workspace. What will you be tracking?',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your name',
                      prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.textMuted),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 28),
                  
                  Text(
                    'Account Purpose',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Purpose Selection Cards
                  _buildPurposeCard(
                    purpose: OnboardingPurpose.personal,
                    icon: Icons.person_rounded,
                    title: 'Personal Expenses',
                    description: 'Track daily personal spending, grocery bills, subscriptions, and budgets.',
                  ),
                  _buildPurposeCard(
                    purpose: OnboardingPurpose.business,
                    icon: Icons.business_center_rounded,
                    title: 'Business Expenses',
                    description: 'Manage business revenue, invoices, payroll, and corporate expenses.',
                  ),
                  _buildPurposeCard(
                    purpose: OnboardingPurpose.both,
                    icon: Icons.swap_horiz_rounded,
                    title: 'Both (Personal & Business)',
                    description: 'Seamlessly switch between personal and business ledger profiles.',
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Submit Button
                  GestureDetector(
                    onTap: userProvider.loading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await userProvider.completeOnboarding(
                                  userId: authProvider.user!.uid,
                                  name: _nameController.text.trim(),
                                  purpose: _selectedPurpose,
                                  email: authProvider.user?.email,
                                  phone: authProvider.user?.phoneNumber,
                                  photoUrl: authProvider.user?.photoURL,
                                  providers: authProvider.linkedProviders,
                                );
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Error setting up profile: $e'),
                                    backgroundColor: AppTheme.expenseRed,
                                  ),
                                );
                              }
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentPurple.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Center(
                        child: userProvider.loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Finish Setup',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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

  Widget _buildPurposeCard({
    required OnboardingPurpose purpose,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedPurpose == purpose;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: GlassCard(
        onTap: () => setState(() => _selectedPurpose = purpose),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        radius: 16,
        margin: EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accentPurple.withValues(alpha: 0.15)
                    : AppTheme.glassWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.accentPurple : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.accentPurple : AppTheme.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: isSelected ? AppTheme.accentPurple : AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
