import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern FinTech Palette
  // Light Mode
  static const _lightPrimary = Color(0xFF0F172A); // Deep Navy (Slate 900)
  static const _lightSecondary = Color(0xFF3B82F6); // Vibrant Blue (Blue 500)
  static const _lightBackground = Color(0xFFF8FAFC); // Soft White (Slate 50)
  static const _lightSurface = Colors.white;
  static const _lightError = Color(0xFFEF4444); // Red 500
  static const _lightOutline = Color(0xFFE2E8F0); // Slate 200

  // Dark Mode
  static const _darkPrimary = Color(0xFFFFFFFF); // White
  static const _darkSecondary = Color(0xFF60A5FA); // Electric Blue (Blue 400)
  static const _darkBackground = Color(0xFF020617); // Deep Slate (Slate 950)
  static const _darkSurface = Color(0xFF1E293B); // Slate 800
  static const _darkError = Color(0xFFF87171); // Red 400
  static const _darkOutline = Color(0xFF334155); // Slate 700

  static ThemeData get light {
    final base = ThemeData.light();
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _lightSecondary,
        primary: _lightPrimary,
        secondary: _lightSecondary,
        surface: _lightSurface,
        error: _lightError,
        outline: _lightOutline,
        brightness: Brightness.light,
      ).copyWith(surfaceTint: Colors.transparent),
      scaffoldBackgroundColor: _lightBackground,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFF334155), // Slate 700
        displayColor: _lightPrimary,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _lightOutline),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightSecondary, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B)), // Slate 500
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: _lightPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: _lightPrimary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _lightSecondary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark();
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _darkSecondary,
        primary: _darkPrimary,
        secondary: _darkSecondary,
        surface: _darkSurface,
        error: _darkError,
        outline: _darkOutline,
        brightness: Brightness.dark,
      ).copyWith(surfaceTint: Colors.transparent),
      scaffoldBackgroundColor: _darkBackground,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFFCBD5E1), // Slate 300
        displayColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _darkOutline),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkSecondary, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)), // Slate 400
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkSecondary,
          foregroundColor: _darkBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _darkSecondary,
        foregroundColor: _darkBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
