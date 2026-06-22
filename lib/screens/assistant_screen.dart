import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/app_theme.dart';
import '../providers/transaction_provider.dart';
import '../widgets/glass_card.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  ChatMessage({required this.text, required this.isUser, DateTime? time}) : time = time ?? DateTime.now();
}

/// Chatbot assistant screen utilizing Gemini to analyze user finances.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final List<ChatMessage> _messages = [];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _thinking = false;
  ChatSession? _chatSession;
  String? _initError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChat();
    });
  }

  Future<void> _initChat() async {
    setState(() {
      _thinking = true;
      _initError = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        throw Exception("You must be signed in to access the AI assistant.");
      }

      final txnP = context.read<TransactionProvider>();
      final txns = txnP.all;

      // Compile a clean history context of the transactions
      final txnSummary = txns.isEmpty
          ? "No transaction history recorded yet."
          : txns.map((t) {
              final type = t.isIncome ? "Income" : "Expense";
              final dateStr = t.date.toIso8601String().substring(0, 10);
              return "- $dateStr | $type | Category: ${t.category} | ${t.title} | Amount: ₹${t.amount.toStringAsFixed(2)}";
            }).join('\n');

      final systemContext = """
You are a helpful, professional, and friendly AI personal finance assistant. You help the user manage their money, analyze spending patterns, and provide practical savings recommendations.
Here is the user's transaction history from their database:
$txnSummary

Respond to user queries based on the data above. If asked about their budget, totals, top categories, or recent spending, parse the transactions to formulate a precise response. 
If they ask for general financial advice, provide practical, actionable tips. Be concise and friendly. Format your answers in clean, readable text.
""";

      final googleAI = FirebaseAI.googleAI(auth: auth);
      final model = googleAI.generativeModel(
        model: 'gemini-flash-latest',
        systemInstruction: Content.system(systemContext),
      );

      _chatSession = model.startChat();

      // Add default welcome message
      setState(() {
        _messages.add(ChatMessage(
          text: "Hello! I am your AI Finance Assistant. I have loaded your transaction history. Ask me anything about your budgets, trends, or how you can save more!",
          isUser: false,
        ));
      });
    } catch (e) {
      setState(() {
        _initError = e.toString();
      });
      debugPrint("AssistantScreen: Initialization error: $e");
    } finally {
      setState(() => _thinking = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _chatSession == null || _thinking) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _thinking = true;
    });
    _scrollToBottom();

    try {
      final response = await _chatSession!.sendMessage(Content.text(text));
      final botText = response.text ?? "I'm sorry, I couldn't formulate a response. Please try again.";
      setState(() {
        _messages.add(ChatMessage(text: botText, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Error communicating with AI: ${e.toString().contains('PERMISSION_DENIED') ? 'AI service not enabled in console' : e.toString()}",
          isUser: false,
        ));
      });
    } finally {
      setState(() => _thinking = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    GlassCard(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.all(8),
                      radius: 12,
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Finance Assistant', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                          Row(
                            children: [
                              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.incomeGreen, shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text('AI Advisor Online', style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Chat Messages Area
              Expanded(
                child: _initError != null
                    ? _errorWidget()
                    : _messages.isEmpty && _thinking
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.accentPurple))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _messages.length + (_thinking ? 1 : 0),
                            itemBuilder: (ctx, i) {
                              if (i == _messages.length) {
                                return _typingBubble();
                              }
                              return _chatBubble(_messages[i]);
                            },
                          ),
              ),

              // Input Bar
              if (_initError == null) _inputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorWidget() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.expenseRed, size: 48),
              const SizedBox(height: 16),
              Text('Connection Error', style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                _initError!.contains('PERMISSION_DENIED')
                    ? 'AI Logic API not enabled in Firebase project. Run "npx firebase-tools init ailogic" to set it up.'
                    : _initError!,
                style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _initChat,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(gradient: AppTheme.accentGradient, borderRadius: BorderRadius.circular(12)),
                  child: Text('Retry Connection', style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _chatBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: message.isUser
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(color: AppTheme.accentPurple.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Text(message.text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, height: 1.4)),
              )
            : GlassCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                radius: 20,
                child: Text(message.text, style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 13, height: 1.4)),
              ),
      ),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        width: 100,
        child: GlassCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(12),
          radius: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (i) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (i * 150)),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -3 * (1.0 - (value - 0.5).abs() * 2)),
                    child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.accentPurple, shape: BoxShape.circle)),
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Ask about expenses, budget...',
                  hintStyle: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 13),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(gradient: AppTheme.accentGradient, shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
