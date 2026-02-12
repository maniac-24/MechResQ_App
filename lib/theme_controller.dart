// lib/theme_controller.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// THEME CONTROLLER - PRODUCTION WITH SYSTEM THEME SUPPORT
/// ============================================================================
/// Manages theme mode (Light/Dark/System) with SharedPreferences persistence.
/// Listens to OS theme changes via WidgetsBindingObserver.
/// ============================================================================
class ThemeController extends ChangeNotifier with WidgetsBindingObserver {
  static const _themeKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  String _themeString = 'System';

  ThemeMode get themeMode => _themeMode;
  String get themeString => _themeString;

  /// Constructor - automatically loads saved theme and registers observer
  ThemeController() {
    // ✅ CRITICAL: Register observer for system brightness changes
    WidgetsBinding.instance.addObserver(this);
    _loadSavedTheme();
  }

  /// Load theme from SharedPreferences on app start
  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey) ?? 'System';
      _themeString = savedTheme;
      _themeMode = _stringToThemeMode(savedTheme);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load theme: $e');
      // Fallback to system theme
      _themeString = 'System';
      _themeMode = ThemeMode.system;
    }
  }

  /// Update theme and persist to SharedPreferences
  Future<void> setTheme(String themeString) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeString);
      
      _themeString = themeString;
      _themeMode = _stringToThemeMode(themeString);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save theme: $e');
    }
  }

  /// Convert string to ThemeMode enum
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

  /// ══════════════════════════════════════════════════════════════════════════
  /// 🔥 CRITICAL FIX: Listen to OS theme changes
  /// ══════════════════════════════════════════════════════════════════════════
  /// Called automatically when Android/iOS system theme changes.
  /// Forces app rebuild ONLY when user has selected "System" theme.
  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    
    // Only rebuild if theme is set to "System"
    if (_themeMode == ThemeMode.system) {
      debugPrint('System brightness changed, rebuilding app...');
      notifyListeners(); // ← This triggers MaterialApp rebuild
    }
  }

  /// Clean up observer when controller is disposed
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}