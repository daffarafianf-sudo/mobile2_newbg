import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Backgrounds ───────────────────────────────────────────────────────
  static const Color bg      = Color(0xFFFFFFFF); // pure white
  static const Color surface = Color(0xFFF9F9F9); // very light grey
  static const Color card    = Color(0xFFFFFFFF); // white card
  static const Color cardAlt = Color(0xFFF4F4F4); // subtle grey card

  // ── Gold Accents ──────────────────────────────────────────────────────
  static const Color accent      = Color(0xFFD4A853);
  static const Color accentLight = Color(0xFFF0C96B);
  static const Color accentDark  = Color(0xFFB8902A);

  // ── Text ─────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0F0F0F); // near black
  static const Color textSecondary = Color(0xFF555555); // dark grey
  static const Color textMuted     = Color(0xFF9E9E9E); // medium grey

  // ── Semantic ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E9E3F);
  static const Color danger  = Color(0xFFD93025);
  static const Color warning = Color(0xFFD29922);

  // ── Border ───────────────────────────────────────────────────────────
  static const Color border = Color(0xFFE8E8E8); // light grey border

  // ── Gradients ────────────────────────────────────────────────────────
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4A853), Color(0xFFF0C96B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF9F9F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF9F9F9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      primaryColor: AppColors.accent,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        secondary: AppColors.accentLight,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: GoogleFonts.dmSans(color: AppColors.textSecondary),
        bodySmall: GoogleFonts.dmSans(color: AppColors.textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        labelStyle: GoogleFonts.dmSans(color: AppColors.textSecondary),
        hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
