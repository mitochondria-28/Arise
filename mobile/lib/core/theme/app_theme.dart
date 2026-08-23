import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Arise palette tokens ───────────────────────────────────────────────────────
class AriseColors {
  // Brand / accent
  static const blue      = Color(0xFF4FC3F7);
  static const purple    = Color(0xFF9B59B6);
  static const gold      = Color(0xFFFFD700);
  static const green     = Color(0xFF34D399);
  static const amber     = Color(0xFFE67E22);  // replaces orange
  static const red       = Color(0xFFEF4444);

  // Dark surfaces
  static const darkBg      = Color(0xFF0A0A0F);
  static const darkCard    = Color(0xFF1C1C2E);
  static const darkBorder  = Color(0xFF2A2A3E);
  static const darkInput   = Color(0xFF0D0D1A);
  static const darkText    = Color(0xFFE2E8F0);
  static const darkDim     = Color(0xFF64748B);

  // Light surfaces — warm "scroll/parchment" aesthetic
  static const lightBg     = Color(0xFFF2EFE9);  // warm off-white
  static const lightCard   = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFDDD8CF);
  static const lightInput  = Color(0xFFF8F6F2);
  static const lightText   = Color(0xFF1A1625);
  static const lightDim    = Color(0xFF7C7087);

  // Semantic
  static const danger  = Color(0xFFEF4444);
  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFE67E22);
}

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AriseColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AriseColors.blue,
        secondary: AriseColors.purple,
        surface: AriseColors.darkCard,
        error: AriseColors.red,
        onPrimary: AriseColors.darkBg,
        onSecondary: Colors.white,
        onSurface: AriseColors.darkText,
        outline: AriseColors.darkBorder,
      ),
      textTheme: _textTheme(AriseColors.darkText, AriseColors.darkDim),
      cardTheme: CardThemeData(
        color: AriseColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AriseColors.darkBorder),
        ),
        elevation: 0,
      ),
      dividerColor: AriseColors.darkBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: AriseColors.darkCard,
        foregroundColor: AriseColors.darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AriseColors.darkInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AriseColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AriseColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AriseColors.blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AriseColors.red),
        ),
        hintStyle: const TextStyle(color: AriseColors.darkDim, fontSize: 13),
        labelStyle: const TextStyle(color: AriseColors.darkDim),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AriseColors.blue,
          foregroundColor: AriseColors.darkBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AriseColors.darkCard,
        side: BorderSide(color: AriseColors.darkBorder),
        labelStyle: TextStyle(color: AriseColors.darkText, fontSize: 12),
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AriseColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AriseColors.blue,
        secondary: AriseColors.purple,
        surface: AriseColors.lightCard,
        error: AriseColors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AriseColors.lightText,
        outline: AriseColors.lightBorder,
      ),
      textTheme: _textTheme(AriseColors.lightText, AriseColors.lightDim),
      cardTheme: CardThemeData(
        color: AriseColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AriseColors.lightBorder),
        ),
        elevation: 0,
      ),
      dividerColor: AriseColors.lightBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: AriseColors.lightCard,
        foregroundColor: AriseColors.lightText,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AriseColors.lightInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AriseColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AriseColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AriseColors.blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AriseColors.red),
        ),
        hintStyle: const TextStyle(color: AriseColors.lightDim, fontSize: 13),
        labelStyle: const TextStyle(color: AriseColors.lightDim),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AriseColors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AriseColors.lightCard,
        side: BorderSide(color: AriseColors.lightBorder),
        labelStyle: TextStyle(color: AriseColors.lightText, fontSize: 12),
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge:   GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w800, color: primary),
      displayMedium:  GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w700, color: primary),
      displaySmall:   GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: primary),
      headlineLarge:  GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: primary),
      headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: primary),
      headlineSmall:  GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: primary),
      titleLarge:     GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      titleMedium:    GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: primary),
      titleSmall:     GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: secondary),
      bodyLarge:      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: primary),
      bodyMedium:     GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: primary),
      bodySmall:      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
      labelLarge:     GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      labelMedium:    GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
      labelSmall:     GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.8, color: secondary),
    );
  }
}
