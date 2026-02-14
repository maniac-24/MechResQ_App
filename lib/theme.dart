// lib/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ─────────────────────────────────────────────
  // BRAND COLORS (Hazard Identity)
  // ─────────────────────────────────────────────
  static const Color hazardYellow = Color(0xFFFFD400);
  static const Color dangerBlack = Color(0xFF0B0B0B);
  static const Color darkBackground = Color(0xFF0E0E0E);
  static const Color surfaceBase = Color(0xFF1A1A1A);
  static const Color accentOrange = Color(0xFFFF8A00);

  // ─────────────────────────────────────────────
  // HAZARD DARK THEME (Primary App Theme)
  // ─────────────────────────────────────────────
  static ThemeData hazardTheme() {
    final base = ThemeData.dark(useMaterial3: true);

    final colorScheme = base.colorScheme.copyWith(
      primary: hazardYellow,
      secondary: accentOrange,
      tertiary: accentOrange,

      surface: surfaceBase,
      surfaceContainerLowest: const Color(0xFF141414),
      surfaceContainerLow: const Color(0xFF181818),
      surfaceContainer: const Color(0xFF1C1C1C),
      surfaceContainerHigh: const Color(0xFF202020),
      surfaceContainerHighest: const Color(0xFF242424),

      onPrimary: dangerBlack,
      onSurface: Colors.white,
      onSecondary: dangerBlack,

      error: Colors.redAccent,
      onError: Colors.white,
      outline: Colors.white24,
      outlineVariant: Colors.white12,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,

      // ───────────────── APP BAR ─────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: hazardYellow,
        ),
        iconTheme: const IconThemeData(color: hazardYellow),
      ),

      // ─────────────── ELEVATED BUTTON ───────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: hazardYellow,
          foregroundColor: dangerBlack,
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // ─────────────── OUTLINED BUTTON ───────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: hazardYellow,
          side: BorderSide(
            color: hazardYellow.withOpacity(0.85),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ─────────────── INPUT FIELDS ───────────────
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF151515),
        hintStyle: TextStyle(color: Colors.white70),
        labelStyle: TextStyle(color: Colors.white70),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
      ),

      // ─────────────── CARD THEME (Safe) ───────────────
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHigh,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),

      dividerColor: Colors.white12,

      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LIGHT THEME (Optional Fallback)
  // ─────────────────────────────────────────────
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: hazardYellow,
        brightness: Brightness.light,
      ),
    );
  }
}
