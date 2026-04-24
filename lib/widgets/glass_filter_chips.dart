import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

/// Horizontal scrollable filter chip bar.
class GlassFilterChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const GlassFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final label = options[i];
          final active = label == selected;
          return GestureDetector(
            onTap: () => onSelected(label),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.accentPurple.withValues(alpha: 0.2) : AppTheme.glassWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: active ? AppTheme.accentPurple : AppTheme.glassBorder),
                  ),
                  child: Text(label,
                      style: GoogleFonts.poppins(
                          color: active ? AppTheme.accentPurple : AppTheme.textMuted,
                          fontSize: 13,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
