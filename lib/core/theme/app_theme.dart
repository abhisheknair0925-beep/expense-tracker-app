import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide glassmorphism design system.
class AppTheme {
  AppTheme._();

  // ─── Colors ───────────────────────────────────────────────────────
  static const Color primaryDark = Color(0xFF0D0B2D);
  static const Color primaryMid = Color(0xFF1B1547);
  static const Color accentPurple = Color(0xFF7B61FF);
  static const Color accentBlue = Color(0xFF4FC3F7);
  static const Color incomeGreen = Color(0xFF00E676);
  static const Color expenseRed = Color(0xFFFF5252);

  // Glass surfaces
  static const Color glassWhite = Color(0x26FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textMuted = Color(0x80FFFFFF);

  // ─── Gradients ────────────────────────────────────────────────────
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF7B61FF), Color(0xFF4FC3F7)],
  );

  // ─── Theme ────────────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryDark,
      colorScheme: const ColorScheme.dark(
        primary: accentPurple,
        secondary: accentBlue,
        surface: primaryMid,
        error: expenseRed,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentPurple, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: textMuted),
        hintStyle: GoogleFonts.poppins(color: textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
