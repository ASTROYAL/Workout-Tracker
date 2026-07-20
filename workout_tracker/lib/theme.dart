import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color forest = Color(0xFF0A1611);
  static const Color forestDeep = Color(0xFF05100C);
  static const Color canopy = Color(0xFF16221D);
  static const Color canopyHigh = Color(0xFF202D27);
  static const Color sage = Color(0xFFB1CDBE);
  static const Color snow = Color(0xFFD8E6DD);
  static const Color blush = Color(0xFFE1BFB5);
  static const Color outline = Color(0xFF594139);
  static const Color glassBorder = Color(0x263D5B4D);
  static const Color orange = Color(0xFFFF6B35);
  static const Color orangeSoft = Color(0xFFFFB59D);
  static const Color pine = Color(0xFF6FAE85);
  static const Color water = Color(0xFF4EA5C8);
  static const Color violet = Color(0xFF9A7CF4);

  static const Color ink = forest;
  static const Color paper = snow;
  static const Color cream = canopy;
  static const Color warm = canopyHigh;
  static const Color accent = orange;
  static const Color accent2 = water;
  static const Color accent3 = pine;
  static const Color push = orange;
  static const Color pull = water;
  static const Color legs = pine;
  static const Color hiit = violet;
  static const Color muted = blush;
  static const Color border = outline;
  static const Color card = canopy;

  // Large bold display – Playfair Display (serif, editorial weight)
  static TextStyle get _serif => GoogleFonts.playfairDisplay(color: snow);
  // Body – Epilogue (clean sans)
  static TextStyle get _sans => GoogleFonts.epilogue(color: snow);
  // Labels / mono – DM Mono
  static TextStyle get _mono => GoogleFonts.dmMono(color: blush);
  // Small text – Caveat (clean cursive handwriting)
  static TextStyle get _cursive => GoogleFonts.caveat(color: blush);

  static ThemeData get themeData {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: forest,
      primaryColor: orange,
      colorScheme: const ColorScheme.dark(
        primary: orange,
        secondary: sage,
        surface: canopy,
        onSurface: snow,
        onPrimary: forest,
      ),
      textTheme: TextTheme(
        // ── Large display texts – bold serif ──────────────────────
        displayLarge: _serif.copyWith(
          fontSize: 52,
          fontWeight: FontWeight.w900,
          height: 1.05,
          letterSpacing: -1.0,
        ),
        displayMedium: _serif.copyWith(
          fontSize: 38,
          fontWeight: FontWeight.w900,
          height: 1.05,
          letterSpacing: -0.5,
        ),
        headlineMedium: _serif.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          height: 1.15,
          letterSpacing: -0.3,
        ),
        titleLarge: _serif.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          height: 1.2,
        ),
        titleMedium: _serif.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          height: 1.25,
        ),
        // ── Body text – clean sans ─────────────────────────────────
        bodyLarge: _sans.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.55,
        ),
        bodyMedium: _sans.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        // ── Small / detail text – cursive ─────────────────────────
        bodySmall: _cursive.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.3,
          color: blush,
        ),
        // ── Labels ────────────────────────────────────────────────
        labelLarge: _sans.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
        labelMedium: _mono.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.8,
        ),
        labelSmall: _mono.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.8,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: canopy.withValues(alpha: 0.95),
        foregroundColor: snow,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: orangeSoft),
        titleTextStyle: _serif.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: orangeSoft,
        ),
      ),
      cardTheme: CardThemeData(
        color: canopy.withValues(alpha: 0.72),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: glassBorder),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: forestDeep,
        labelStyle: _sans.copyWith(color: blush),
        hintStyle: _sans.copyWith(color: blush.withValues(alpha: 0.65)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: orange, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: canopy.withValues(alpha: 0.98),
        selectedItemColor: orange,
        unselectedItemColor: blush,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: _mono.copyWith(fontSize: 10, letterSpacing: 1.4),
        unselectedLabelStyle: _mono.copyWith(fontSize: 10, letterSpacing: 1.4),
        elevation: 24,
      ),
      dividerTheme: const DividerThemeData(color: glassBorder, thickness: 1),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: orange,
        foregroundColor: forest,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: forest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: _sans.copyWith(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: orangeSoft,
          textStyle: _mono.copyWith(fontSize: 11, letterSpacing: 1.5),
        ),
      ),
    );
  }
}
