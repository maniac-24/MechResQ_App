// lib/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Hazard palette
  static const Color hazardYellow = Color(0xFFFFD400); // primary
  static const Color dangerBlack = Color(0xFF0B0B0B); // background / text
  static const Color surface = Color(0xFF1A1A1A);
  static const Color accent = Color(0xFFFF8A00); // orange accent

  static ThemeData hazardTheme() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0E0E0E),
      primaryColor: hazardYellow,
      colorScheme: base.colorScheme.copyWith(
        primary: hazardYellow,
        secondary: accent,
        surface: surface,
        onPrimary: dangerBlack,
        onSurface: Colors.white,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: hazardYellow,
        ),
        iconTheme: IconThemeData(color: hazardYellow),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: hazardYellow,
          foregroundColor: dangerBlack,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: hazardYellow,
          // ignore: deprecated_member_use
          side: BorderSide(color: hazardYellow.withOpacity(0.85)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        ),
      ),
      // removed cardTheme to avoid SDK / web-compiler type mismatch
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF151515),
        hintStyle: TextStyle(color: Colors.white70),
        labelStyle: TextStyle(color: Colors.white70),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
      ),
      dividerColor: Colors.white12,
    );
  }
}
