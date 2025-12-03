import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Atlassian Design System Palette
  // Primary
  static const _primary = Color(0xFF0052CC); // B400
  static const _primaryLight = Color(0xFF4C9AFF); // B200

  // Neutrals (Light)
  static const _n800 = Color(0xFF172B4D); // Primary Text
  static const _n500 = Color(0xFF42526E); // Secondary Text
  static const _n200 = Color(0xFF6B778C); // Disabled / Icons
  static const _n40 = Color(0xFFDFE1E6); // Borders
  static const _n30 = Color(0xFFEBECF0); // Backgrounds / Dividers
  static const _n10 = Color(0xFFFAFBFC); // Page Background
  static const _n0 = Color(0xFFFFFFFF); // Surface

  // Neutrals (Dark) - Approximated for Dark Mode
  static const _dn900 = Color(0xFF1D2125); // Page Background
  static const _dn800 = Color(0xFF22272B); // Surface
  static const _dn600 = Color(0xFF454F59); // Borders
  static const _dn100 = Color(0xFFB6C2CF); // Primary Text
  static const _dn400 = Color(0xFF9FADBC); // Secondary Text

  // Functional
  static const _error = Color(0xFFDE350B); // R400

  static ThemeData get light {
    final base = ThemeData.light();
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        primary: _primary,
        onPrimary: _n0,
        secondary: _primaryLight,
        onSecondary: _n800,
        surface: _n0,
        onSurface: _n800,
        error: _error,
        onError: _n0,
        outline: _n40,
        brightness: Brightness.light,
      ).copyWith(surfaceTint: Colors.transparent),
      cupertinoOverrideTheme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: _primary,
        barBackgroundColor: _n10,
        scaffoldBackgroundColor: _n10,
        textTheme: CupertinoTextThemeData(
          primaryColor: _n800,
          textStyle: TextStyle(color: _n800),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      scaffoldBackgroundColor: _n10,
      textTheme: textTheme
          .apply(bodyColor: _n800, displayColor: _n800)
          .copyWith(
            displayLarge: textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: _n800,
            ),
            displayMedium: textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: _n800,
            ),
            displaySmall: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: _n800,
            ),
            headlineLarge: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: _n800,
            ),
            headlineMedium: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: _n800,
            ),
            headlineSmall: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: _n800,
            ),
            titleLarge: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: _n800,
            ),
            titleMedium: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: _n800,
            ),
            titleSmall: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: _n500,
            ),
            bodyLarge: textTheme.bodyLarge?.copyWith(color: _n800),
            bodyMedium: textTheme.bodyMedium?.copyWith(color: _n800),
            bodySmall: textTheme.bodySmall?.copyWith(color: _n500),
          ),
      cardTheme: CardThemeData(
        elevation: 1, // Minimal elevation
        color: _n0,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3), // ADS uses small radius
          side: const BorderSide(color: _n40, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _n10,
        hoverColor: _n30,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: _n40, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: _n40, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: _error, width: 2),
        ),
        labelStyle: const TextStyle(color: _n500),
        hintStyle: const TextStyle(color: _n200),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: _n0,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _n0,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.inter(
          color: _n800,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: _n800),
        shape: const Border(bottom: BorderSide(color: _n40, width: 1)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: _n0,
        elevation: 3,
      ),
      dividerTheme: const DividerThemeData(color: _n30, thickness: 1, space: 1),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark();
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        primary: _primary,
        onPrimary: _n0,
        secondary: _primaryLight,
        onSecondary: _dn900,
        surface: _dn800,
        onSurface: _dn100,
        error: _error,
        onError: _n0,
        outline: _dn600,
        brightness: Brightness.dark,
      ).copyWith(surfaceTint: Colors.transparent),
      cupertinoOverrideTheme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: _primary,
        barBackgroundColor: _dn900,
        scaffoldBackgroundColor: _dn900,
        textTheme: CupertinoTextThemeData(
          primaryColor: _dn100,
          textStyle: TextStyle(color: _dn100),
        ),
      ),
      scaffoldBackgroundColor: _dn900,
      textTheme: textTheme
          .apply(bodyColor: _dn100, displayColor: _dn100)
          .copyWith(
            displayLarge: textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: _dn100,
            ),
            displayMedium: textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: _dn100,
            ),
            displaySmall: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: _dn100,
            ),
            headlineLarge: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: _dn100,
            ),
            headlineMedium: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: _dn100,
            ),
            headlineSmall: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: _dn100,
            ),
            titleLarge: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: _dn100,
            ),
            titleMedium: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: _dn100,
            ),
            titleSmall: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: _dn400,
            ),
            bodyLarge: textTheme.bodyLarge?.copyWith(color: _dn100),
            bodyMedium: textTheme.bodyMedium?.copyWith(color: _dn100),
            bodySmall: textTheme.bodySmall?.copyWith(color: _dn400),
          ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _dn800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: const BorderSide(color: _dn600, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _dn900,
        hoverColor: _dn800,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: _dn600, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: _dn600, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: _error, width: 2),
        ),
        labelStyle: const TextStyle(color: _dn400),
        hintStyle: const TextStyle(color: _dn600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: _n0,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _dn800,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.inter(
          color: _dn100,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: _dn100),
        shape: const Border(bottom: BorderSide(color: _dn600, width: 1)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: _n0,
        elevation: 3,
      ),
      dividerTheme: const DividerThemeData(
        color: _dn600,
        thickness: 1,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
