import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Arise Design Tokens ────────────────────────────────────

class AriseColors {
  // Brand
  static const indigo500 = Color(0xFF6366F1);
  static const indigo600 = Color(0xFF4F46E5);
  static const indigo400 = Color(0xFF818CF8);
  static const violet600 = Color(0xFF7C3AED);
  static const violet700 = Color(0xFF6D28D9);

  // XP / success
  static const xpDark  = Color(0xFF34D399);
  static const xpLight = Color(0xFF059669);

  // Dark surfaces (cool-toned)
  static const darkBg       = Color(0xFF080B12);
  static const darkSurface1 = Color(0xFF0F1320);
  static const darkSurface2 = Color(0xFF161B2E);
  static const darkSurface3 = Color(0xFF1E243D);
  static const darkBorder   = Color(0xFF1E2640);
  static const darkText1    = Color(0xFFEEF0FF);
  static const darkText2    = Color(0xFF7B82A8);
  static const darkText3    = Color(0xFF454B6A);

  // Light surfaces (warm-toned)
  static const lightBg       = Color(0xFFFAF8F5);
  static const lightSurface1 = Color(0xFFFFFFFF);
  static const lightSurface2 = Color(0xFFF5F0EA);
  static const lightSurface3 = Color(0xFFEDE8E0);
  static const lightBorder   = Color(0xFFE5DDD4);
  static const lightText1    = Color(0xFF1C1410);
  static const lightText2    = Color(0xFF6B5E54);
  static const lightText3    = Color(0xFFB8A898);

  // Semantic
  static const danger  = Color(0xFFF87171);
  static const warning = Color(0xFFFBBF24);
  static const success = Color(0xFF34D399);
}

class AppTheme {
  static ThemeData dark() {
    const accent = AriseColors.indigo500;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AriseColors.darkBg,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: AriseColors.indigo400,
        surface: AriseColors.darkSurface1,
        error: AriseColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AriseColors.darkText1,
      ),
      textTheme: _textTheme(AriseColors.darkText1, AriseColors.darkText2),
      cardTheme: CardThemeData(
        color: AriseColors.darkSurface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AriseColors.darkBorder, width: 1),
        ),
        elevation: 0,
      ),
      dividerColor: AriseColors.darkBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: AriseColors.darkBg,
        foregroundColor: AriseColors.darkText1,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AriseColors.darkSurface1,
        indicatorColor: AriseColors.indigo500.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AriseColors.indigo400);
          }
          return const IconThemeData(color: AriseColors.darkText3);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500);
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(color: AriseColors.indigo400);
          }
          return base.copyWith(color: AriseColors.darkText3);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AriseColors.darkSurface2,
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
          borderSide: const BorderSide(color: AriseColors.indigo500, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AriseColors.darkText3),
        labelStyle: const TextStyle(color: AriseColors.darkText2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
          elevation: 0,
        ),
      ),
    );
  }

  static ThemeData light() {
    const accent = AriseColors.violet600;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AriseColors.lightBg,
      colorScheme: ColorScheme.light(
        primary: accent,
        secondary: AriseColors.violet700,
        surface: AriseColors.lightSurface1,
        error: const Color(0xFFDC2626),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AriseColors.lightText1,
      ),
      textTheme: _textTheme(AriseColors.lightText1, AriseColors.lightText2),
      cardTheme: CardThemeData(
        color: AriseColors.lightSurface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AriseColors.lightBorder, width: 1),
        ),
        elevation: 0,
      ),
      dividerColor: AriseColors.lightBorder,
      appBarTheme: const AppBarTheme(
        backgroundColor: AriseColors.lightBg,
        foregroundColor: AriseColors.lightText1,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AriseColors.lightSurface1,
        indicatorColor: AriseColors.violet600.withValues(alpha: 0.08),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AriseColors.violet600);
          }
          return const IconThemeData(color: AriseColors.lightText3);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500);
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(color: AriseColors.violet600);
          }
          return base.copyWith(color: AriseColors.lightText3);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AriseColors.lightSurface2,
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
          borderSide: const BorderSide(color: AriseColors.violet600, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AriseColors.lightText3),
        labelStyle: const TextStyle(color: AriseColors.lightText2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
          elevation: 0,
        ),
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge:  GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w800, color: primary),
      displayMedium: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w700, color: primary),
      displaySmall:  GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: primary),
      headlineLarge: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: primary),
      headlineMedium:GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: primary),
      headlineSmall: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: primary),
      titleLarge:    GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      titleMedium:   GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: primary),
      titleSmall:    GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: secondary),
      bodyLarge:     GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: primary),
      bodyMedium:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: primary),
      bodySmall:     GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
      labelLarge:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      labelMedium:   GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
      labelSmall:    GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.8, color: secondary),
    );
  }
}
