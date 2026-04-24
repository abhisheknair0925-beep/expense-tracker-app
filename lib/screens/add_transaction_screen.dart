import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/transaction_model.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/receipt_service.dart';
import '../services/smart_category_service.dart';
import '../utils/formatters.dart';
import '../widgets/glass_card.dart';

/// Add transaction form with glassmorphism styling.
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});
  @override
  State<AddTransactionScreen> createState() => _AddState();
}

class _AddState extends State<AddTransactionScreen> with SingleTickerProviderStateMixin {
  final _key = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  String _type = AppConstants.typeExpense;
  String? _cat;
  int? _accountId;
  String? _receiptPath;
  bool _autoSuggested = false;
  DateTime _date = DateTime.now();
  bool _saving = false;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _title.addListener(_onTitleChanged);
  }

  @override
  void dispose() { _title.removeListener(_onTitleChanged); _title.dispose(); _amount.dispose(); _anim.dispose(); super.dispose(); }

  /// Auto-suggest category when user types title.
  void _onTitleChanged() {
    if (_title.text.length < 3) return;
    final suggestion = SmartCategoryService.instance.suggest(_title.text);
    if (suggestion != null && _cats.contains(suggestion) && !_autoSuggested) {
      setState(() { _cat = suggestion; _autoSuggested = true; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✨ Auto: $suggestion', style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.accentPurple.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _pickReceipt({bool fromCamera = false}) async {
    final file = await ReceiptService.instance.pickReceipt(fromCamera: fromCamera);
    if (file != null) setState(() => _receiptPath = file.path);
  }

  List<String> get _cats =>
      _type == AppConstants.typeIncome ? AppConstants.incomeCategories : AppConstants.expenseCategories;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now(),
      builder: (c, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.accentPurple, surface: AppTheme.primaryMid)), child: child!),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    if (_cat == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please select a category', style: GoogleFonts.poppins()),
        backgroundColor: AppTheme.expenseRed, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _saving = true);
    await context.read<TransactionProvider>().add(Txn(
      title: _title.text.trim(),
      amount: double.parse(_amount.text.trim()),
      type: _type, category: _cat!, accountId: _accountId, receiptPath: _receiptPath, date: _date,
    ));
    // Adjust account balance if linked
    if (_accountId != null && mounted) {
      await context.read<AccountProvider>().adjustBalance(
        _accountId!, double.parse(_amount.text.trim()), _type);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _anim, curve: Curves.easeOutBack),
            child: Column(children: [
              // Header
              Padding(padding: const EdgeInsets.all(16), child: Row(children: [
                GlassCard(margin: EdgeInsets.zero, padding: const EdgeInsets.all(8), radius: 12, onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary, size: 22)),
                const SizedBox(width: 14),
                Text('Add Transaction', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
              ])),
              // Form
              Expanded(child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Form(key: _key, child: Column(children: [
                  // Type toggle
                  GlassCard(padding: const EdgeInsets.all(4), child: Row(children: [
                    _toggle('Expense', AppConstants.typeExpense, AppTheme.expenseRed),
                    const SizedBox(width: 4),
                    _toggle('Income', AppConstants.typeIncome, AppTheme.incomeGreen),
                  ])),
                  const SizedBox(height: 12),
                  // Title
                  _field(_title, 'Title', Icons.title_rounded, (v) => v != null && v.trim().isNotEmpty ? null : 'Required'),
                  const SizedBox(height: 10),
                  // Amount
                  _field(_amount, 'Amount', Icons.currency_rupee_rounded, (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final n = double.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Invalid';
                    return null;
                  }, keyboard: const TextInputType.numberWithOptions(decimal: true), big: true),
                  const SizedBox(height: 10),
                  // Category
                  GlassCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: DropdownButtonFormField<String>(
                    initialValue: _cat, dropdownColor: AppTheme.primaryMid,
                    style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                    decoration: _dec('Category', Icons.category_rounded),
                    items: _cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _cat = v),
                  )),
                  const SizedBox(height: 10),
                  // Account (optional)
                  Builder(builder: (ctx) {
                    final accounts = context.watch<AccountProvider>().accounts;
                    if (accounts.isEmpty) return const SizedBox.shrink();
                    return Column(children: [
                      GlassCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: DropdownButtonFormField<int?>(
                        initialValue: _accountId, dropdownColor: AppTheme.primaryMid,
                        style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                        decoration: _dec('Account (optional)', Icons.account_balance_wallet_rounded),
                        items: [
                          DropdownMenuItem<int?>(value: null, child: Text('None', style: GoogleFonts.poppins(color: AppTheme.textMuted))),
                          ...accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
                        ],
                        onChanged: (v) => setState(() => _accountId = v),
                      )),
                      const SizedBox(height: 10),
                    ]);
                  }),
                  // Date
                  GlassCard(onTap: _pickDate, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, color: AppTheme.textMuted, size: 22),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Date', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
                      Text(Fmt.date(_date), style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                    ]),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                  ])),
                  const SizedBox(height: 22),
                  // Receipt attach
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.receipt_long_rounded, color: AppTheme.textMuted, size: 20),
                        const SizedBox(width: 10),
                        Text('Receipt', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _pickReceipt(fromCamera: true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: AppTheme.glassWhite, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.glassBorder)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.camera_alt_rounded, color: AppTheme.textMuted, size: 16),
                              const SizedBox(width: 4),
                              Text('Camera', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _pickReceipt(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: AppTheme.glassWhite, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.glassBorder)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.photo_library_rounded, color: AppTheme.textMuted, size: 16),
                              const SizedBox(width: 4),
                              Text('Gallery', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
                            ]),
                          ),
                        ),
                      ]),
                      if (_receiptPath != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(children: [
                            Image.file(File(_receiptPath!), height: 120, width: double.infinity, fit: BoxFit.cover),
                            Positioned(top: 4, right: 4, child: GestureDetector(
                              onTap: () => setState(() => _receiptPath = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: AppTheme.primaryDark, shape: BoxShape.circle),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                              ),
                            )),
                          ]),
                        ),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 16),
                  // Save
                  GestureDetector(
                    onTap: _saving ? null : _save,
                    child: Container(
                      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: AppTheme.accentPurple.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]),
                      child: Center(child: _saving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text('Save Transaction', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
                    ),
                  ),
                  const SizedBox(height: 32),
                ])),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _toggle(String label, String type, Color color) {
    final on = _type == type;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() { _type = type; _cat = null; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300), padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: on ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: on ? color : Colors.transparent, width: 1.5),
        ),
        child: Center(child: Text(label, style: GoogleFonts.poppins(color: on ? color : AppTheme.textMuted, fontSize: 14, fontWeight: on ? FontWeight.w600 : FontWeight.w400))),
      ),
    ));
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, String? Function(String?) validator, {TextInputType? keyboard, bool big = false}) {
    return GlassCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: TextFormField(
      controller: ctrl, validator: validator, keyboardType: keyboard,
      style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: big ? 18 : 14, fontWeight: big ? FontWeight.w600 : FontWeight.w400),
      decoration: _dec(label, icon),
    ));
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
    labelText: label, labelStyle: GoogleFonts.poppins(color: AppTheme.textMuted),
    prefixIcon: Icon(icon, color: AppTheme.textMuted), filled: false,
  );
}
