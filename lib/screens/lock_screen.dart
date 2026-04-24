import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../services/security_service.dart';
import '../widgets/glass_card.dart';

/// Lock screen — PIN entry with biometric option.
class LockScreen extends StatefulWidget {
  final Widget child;
  const LockScreen({super.key, required this.child});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _locked = true;
  bool _checking = true;
  String _pin = '';
  String _error = '';

  @override
  void initState() { super.initState(); _checkLock(); }

  Future<void> _checkLock() async {
    final enabled = await SecurityService.instance.isLockEnabled;
    if (!enabled) { setState(() { _locked = false; _checking = false; }); return; }
    setState(() => _checking = false);
    final bioEnabled = await SecurityService.instance.isBiometricEnabled;
    if (bioEnabled) {
      final ok = await SecurityService.instance.authenticateBiometric();
      if (ok && mounted) setState(() => _locked = false);
    }
  }

  void _onDigit(String d) {
    if (_pin.length >= 4) return;
    setState(() { _pin += d; _error = ''; });
    if (_pin.length == 4) _verify();
  }

  void _onDelete() { if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1)); }

  Future<void> _verify() async {
    final ok = await SecurityService.instance.verifyPin(_pin);
    if (ok) { setState(() => _locked = false); } else { setState(() { _pin = ''; _error = 'Wrong PIN'; }); }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.accentPurple)));
    if (!_locked) return widget.child;
    return Scaffold(body: Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SafeArea(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 80, height: 80, decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.lock_rounded, color: Colors.white, size: 36)),
        const SizedBox(height: 24),
        Text('Enter PIN', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w600)),
        if (_error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error, style: GoogleFonts.poppins(color: AppTheme.expenseRed, fontSize: 13))),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) => Container(
          width: 16, height: 16, margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(shape: BoxShape.circle, color: i < _pin.length ? AppTheme.accentPurple : AppTheme.glassWhite, border: Border.all(color: AppTheme.glassBorder)),
        ))),
        const SizedBox(height: 40),
        ...List.generate(3, (r) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (c) { final d = '${r * 3 + c + 1}'; return _numKey(d, () => _onDigit(d)); })))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _numKey('', null), _numKey('0', () => _onDigit('0')), _numKey('⌫', _onDelete)])),
        const SizedBox(height: 16),
        FutureBuilder<bool>(future: SecurityService.instance.isBiometricEnabled, builder: (ctx, snap) {
          if (snap.data != true) return const SizedBox.shrink();
          return GlassCard(margin: EdgeInsets.zero, padding: const EdgeInsets.all(12), radius: 16,
            onTap: () async { final ok = await SecurityService.instance.authenticateBiometric(); if (ok && mounted) setState(() => _locked = false); },
            child: const Icon(Icons.fingerprint_rounded, color: AppTheme.accentPurple, size: 32));
        }),
      ]))),
    ));
  }

  Widget _numKey(String label, VoidCallback? onTap) => GestureDetector(onTap: onTap,
    child: Container(width: 72, height: 72, margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: label.isEmpty ? Colors.transparent : AppTheme.glassWhite, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: label.isEmpty ? Colors.transparent : AppTheme.glassBorder)),
      child: Center(child: Text(label, style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: label == '⌫' ? 18 : 24, fontWeight: FontWeight.w500)))));
}
