import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color ink = Color(0xFF0E0E0E);
  static const Color paper = Color(0xFFF5F0E8);
  static const Color cream = Color(0xFFEDE8DC);
  static const Color warm = Color(0xFFE8DFC8);
  static const Color accent = Color(0xFFC8411A);
  static const Color accent2 = Color(0xFF1A6BC8);
  static const Color accent3 = Color(0xFF2A8A3E);
  static const Color push = Color(0xFFC8411A);
  static const Color pull = Color(0xFF1A6BC8);
  static const Color legs = Color(0xFF2A8A3E);
  static const Color hiit = Color(0xFF7C3AED);
  static const Color muted = Color(0xFF7A7060);
  static const Color border = Color(0xFFD4CDB8);
  static const Color card = Color(0xFFFAF7F2);

  static ThemeData get themeData {
    return ThemeData(
      scaffoldBackgroundColor: paper,
      primaryColor: accent,
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: accent2,
        surface: card,
        onSurface: ink,
        error: accent,
        onPrimary: paper,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
            fontSize: 48, fontWeight: FontWeight.w900, color: ink, height: 0.95, letterSpacing: -0.02),
        displayMedium: GoogleFonts.playfairDisplay(
            fontSize: 32, fontWeight: FontWeight.w900, color: ink, height: 1.0, letterSpacing: -0.02),
        titleLarge: GoogleFonts.playfairDisplay(
            fontSize: 24, fontWeight: FontWeight.w700, color: ink),
        titleMedium: GoogleFonts.playfairDisplay(
            fontSize: 18, fontWeight: FontWeight.w700, color: ink),
        bodyLarge: GoogleFonts.epilogue(
            fontSize: 16, fontWeight: FontWeight.w400, color: ink, height: 1.6),
        bodyMedium: GoogleFonts.epilogue(
            fontSize: 14, fontWeight: FontWeight.w400, color: ink, height: 1.6),
        labelSmall: GoogleFonts.dmMono(
            fontSize: 10, fontWeight: FontWeight.w500, color: muted, letterSpacing: 1.5),
        labelMedium: GoogleFonts.dmMono(
            fontSize: 11, fontWeight: FontWeight.w500, color: muted, letterSpacing: 1.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        elevation: 0,
        iconTheme: const IconThemeData(color: ink),
        titleTextStyle: GoogleFonts.playfairDisplay(
            fontSize: 24, fontWeight: FontWeight.w900, color: ink),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: border),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: ink,
        selectedItemColor: paper,
        unselectedItemColor: muted,
        selectedLabelStyle: GoogleFonts.dmMono(fontSize: 10, letterSpacing: 1),
        unselectedLabelStyle: GoogleFonts.dmMono(fontSize: 10, letterSpacing: 1),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: paper,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.epilogue(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
