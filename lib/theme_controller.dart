// lib/theme_controller.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// THEME CONTROLLER — PRODUCTION READY
/// Supports Light / Dark / System
/// Persists theme using SharedPreferences
/// Listens to OS brightness changes
/// ============================================================================
class ThemeController extends ChangeNotifier with WidgetsBindingObserver {
  static const String _themeKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  String get themeString {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
      default:
        return 'System';
    }
  }

  // ─────────────────────────────────────────────
  // CONSTRUCTOR
  // ─────────────────────────────────────────────
  ThemeController() {
    WidgetsBinding.instance.addObserver(this);
    _loadTheme();
  }

  // ─────────────────────────────────────────────
  // LOAD SAVED THEME
  // ─────────────────────────────────────────────
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_themeKey);

      if (saved != null) {
        _themeMode = _stringToThemeMode(saved);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Theme load failed: $e');
    }
  }

  // ─────────────────────────────────────────────
  // SET THEME
  // ─────────────────────────────────────────────
  Future<void> setTheme(String value) async {
    final newMode = _stringToThemeMode(value);

    if (newMode == _themeMode) return; // Prevent unnecessary rebuild

    _themeMode = newMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, value);
    } catch (e) {
      debugPrint('Theme save failed: $e');
    }
  }

  // ─────────────────────────────────────────────
  // STRING → ENUM
  // ─────────────────────────────────────────────
  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'Light':
        return ThemeMode.light;
      case 'Dark':
        return ThemeMode.dark;
      case 'System':
      default:
        return ThemeMode.system;
    }
  }

  // ─────────────────────────────────────────────
  // SYSTEM BRIGHTNESS LISTENER
  // ─────────────────────────────────────────────
  @override
  void didChangePlatformBrightness() {
    if (_themeMode == ThemeMode.system) {
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // CLEANUP
  // ─────────────────────────────────────────────
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
