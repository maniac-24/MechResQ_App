// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme_controller.dart';
import '../utils/snackbar_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ---------------------------------------------------------------
  // STATE
  // ---------------------------------------------------------------
  String _appLanguage = "English"; // UI language
  bool _notificationsEnabled = true; // global toggle

  // Simulated cache size (replace with real calculation)
  String _cacheSize = "12.4 MB";

  // Simulated data usage (replace with real tracking)
  final Map<String, String> _dataUsage = {
    "Profile Photos": "3.2 MB",
    "Vehicle Images": "18.6 MB",
    "Cached Maps": "8.1 MB",
    "Service History": "1.4 MB",
  };

  static const String _appVersion = "1.0.0";
  static const String _buildNumber = "42";

  final List<String> _themeOptions = ["Light", "Dark", "System"];
  final List<String> _languageOptions = [
    "English",
    "Hindi",
    "Kannada",
    "Tamil",
    "Telugu"
  ];

  // ---------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final themeController = context.watch<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ===== APPEARANCE =====
          _sectionHeader(context, "Appearance", Icons.palette_outlined),

          // Theme selector
          Card(
            color: scheme.surfaceContainerHighest,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                themeController.themeString == "Dark"
                    ? Icons.dark_mode
                    : themeController.themeString == "Light"
                        ? Icons.light_mode
                        : Icons.settings_brightness,
                color: scheme.onSurface,
              ),
              title: const Text("Theme"),
              subtitle: Text(
                themeController.themeString,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withOpacity(0.7),
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: scheme.onSurface.withOpacity(0.5),
              ),
              onTap: () => _showThemePicker(),
            ),
          ),

          // App language selector
          Card(
            color: scheme.surfaceContainerHighest,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(Icons.translate, color: scheme.onSurface),
              title: const Text("App Language"),
              subtitle: Text(
                _appLanguage,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withOpacity(0.7),
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: scheme.onSurface.withOpacity(0.5),
              ),
              onTap: () => _showLanguagePicker(),
            ),
          ),

          const SizedBox(height: 16),

          // ===== NOTIFICATIONS =====
          _sectionHeader(context, "Notifications", Icons.notifications_outlined),

          // Global toggle
          Card(
            color: scheme.surfaceContainerHighest,
            margin: const EdgeInsets.only(bottom: 8),
            child: SwitchListTile(
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
              title: const Text("Enable Notifications"),
              subtitle: Text(
                _notificationsEnabled
                    ? "You will receive app updates"
                    : "All notifications are off",
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withOpacity(0.7),
                ),
              ),
              secondary: Icon(
                _notificationsEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: scheme.onSurface,
              ),
              activeColor: scheme.primary,
            ),
          ),

          // Shortcut → system notification settings
          Card(
            color: scheme.surfaceContainerHighest,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(Icons.settings_outlined, color: scheme.onSurface),
              title: const Text("System Notification Settings"),
              subtitle: Text(
                "Manage on device level",
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withOpacity(0.7),
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: scheme.onSurface.withOpacity(0.5),
              ),
              onTap: () => SnackBarHelper.showInfo(
                context,
                "Opening system notification settings...",
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ===== STORAGE =====
          _sectionHeader(context, "Storage", Icons.storage_outlined),

          // Cache size + clear button
          Card(
            color: scheme.surfaceContainerHighest,
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.cleaning_services_outlined,
                    color: scheme.onSurface,
                  ),
                  title: const Text("Cache"),
                  subtitle: Text(
                    "Currently using $_cacheSize",
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () => _clearCache(),
                    child: Text(
                      "Clear",
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Data usage breakdown
          Card(
            color: scheme.surfaceContainerHighest,
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.bar_chart_outlined,
                    color: scheme.onSurface,
                  ),
                  title: const Text("Data Usage"),
                  subtitle: Text(
                    "Storage breakdown",
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: scheme.onSurface.withOpacity(0.5),
                  ),
                  onTap: () => _showDataUsageDialog(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ===== LEGAL =====
          _sectionHeader(context, "Legal", Icons.gavel_outlined),

          Card(
            color: scheme.surfaceContainerHighest,
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.privacy_tip_outlined,
                    color: scheme.onSurface,
                  ),
                  title: const Text("Privacy Policy"),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: scheme.onSurface.withOpacity(0.5),
                  ),
                  onTap: () => _showInfoDialog(
                    "Privacy Policy",
                    "Last updated: January 2026\n\n"
                        "We respect your privacy. Here is how we handle your data:\n\n"
                        "• Your personal data is stored securely and encrypted at rest.\n"
                        "• We never sell or share your data with third parties without consent.\n"
                        "• Location data is used only to find nearby mechanics.\n"
                        "• You can request a full data export or deletion at any time.\n"
                        "• Cookies and local storage are used only for app functionality.\n\n"
                        "For questions, contact support@mechresq.com",
                  ),
                ),
                Divider(height: 1, color: scheme.outlineVariant),
                ListTile(
                  leading: Icon(
                    Icons.description_outlined,
                    color: scheme.onSurface,
                  ),
                  title: const Text("Terms & Conditions"),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: scheme.onSurface.withOpacity(0.5),
                  ),
                  onTap: () => _showInfoDialog(
                    "Terms & Conditions",
                    "Last updated: January 2026\n\n"
                        "By using MechResQ, you agree to the following:\n\n"
                        "• You must be 18 years or older to use this service.\n"
                        "• MechResQ is not liable for disputes between users and mechanics.\n"
                        "• All payments processed through the app are final unless disputed within 24 hours.\n"
                        "• Misuse of the platform may result in account suspension.\n"
                        "• MechResQ reserves the right to modify these terms at any time.\n\n"
                        "For questions, contact support@mechresq.com",
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ===== ABOUT =====
          _sectionHeader(context, "About", Icons.info_outlined),

          Card(
            color: scheme.surfaceContainerHighest,
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline, color: scheme.onSurface),
                  title: const Text("About MechResQ"),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: scheme.onSurface.withOpacity(0.5),
                  ),
                  onTap: () => _showInfoDialog(
                    "About MechResQ",
                    "MechResQ\n"
                        "Version $_appVersion (Build $_buildNumber)\n\n"
                        "A fast and reliable vehicle breakdown assistance app.\n\n"
                        "Find nearby mechanics, request service, track your requests — "
                        "all in one place.\n\n"
                        "© 2026 MechResQ. All rights reserved.",
                  ),
                ),
                Divider(height: 1, color: scheme.outlineVariant),
                // Version + build as read-only row
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Version",
                        style: TextStyle(
                          color: scheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        "$_appVersion (Build $_buildNumber)",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ===== DANGER ZONE =====
          _sectionHeader(context, "Danger Zone", Icons.warning_amber_outlined),

          Card(
            color: scheme.surfaceContainerHighest,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(Icons.refresh_outlined, color: scheme.error),
              title: Text(
                "Reset App Preferences",
                style: TextStyle(color: scheme.error),
              ),
              subtitle: Text(
                "Restore all settings to defaults",
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withOpacity(0.7),
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: scheme.onSurface.withOpacity(0.5),
              ),
              onTap: () => _confirmResetPreferences(),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // SECTION HEADER
  // ---------------------------------------------------------------
  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // THEME PICKER (bottom sheet)
  // ---------------------------------------------------------------
  void _showThemePicker() {
    final scheme = Theme.of(context).colorScheme;
    final themeController = context.read<ThemeController>();

    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Choose Theme",
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ..._themeOptions.map((option) {
                final isSelected = option == themeController.themeString;
                final icon = option == "Dark"
                    ? Icons.dark_mode
                    : option == "Light"
                        ? Icons.light_mode
                        : Icons.settings_brightness;

                return ListTile(
                  leading: Icon(icon, color: scheme.primary),
                  title: Text(
                    option,
                    style: TextStyle(color: scheme.onSurface),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check, color: scheme.primary)
                      : null,
                  onTap: () async {
                    await themeController.setTheme(option);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    SnackBarHelper.showInfo(
                      context,
                      "Theme set to $option",
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // LANGUAGE PICKER (bottom sheet)
  // ---------------------------------------------------------------
  void _showLanguagePicker() {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "App Language",
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ..._languageOptions.map((lang) {
                final isSelected = lang == _appLanguage;
                return ListTile(
                  leading: Icon(Icons.translate, color: scheme.primary),
                  title: Text(
                    lang,
                    style: TextStyle(color: scheme.onSurface),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check, color: scheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _appLanguage = lang);
                    Navigator.pop(ctx);
                    SnackBarHelper.showInfo(
                      context,
                      "Language changed to $lang",
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // CLEAR CACHE
  // ---------------------------------------------------------------
  void _clearCache() {
    final scheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: scheme.surface,
        title: Text(
          "Clear Cache",
          style: TextStyle(color: scheme.onSurface),
        ),
        content: Text(
          "This will remove $_cacheSize of temporary data. The app may load slightly slower on next use.",
          style: TextStyle(color: scheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _cacheSize = "0.0 MB");
              SnackBarHelper.showSuccess(context, "Cache cleared successfully");
            },
            child: const Text("Clear"),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // DATA USAGE DIALOG
  // ---------------------------------------------------------------
  void _showDataUsageDialog() {
    final scheme = Theme.of(context).colorScheme;
    final total = _dataUsage.values.toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: scheme.surface,
        title: Text(
          "Data Usage",
          style: TextStyle(color: scheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._dataUsage.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(color: scheme.onSurface),
                    ),
                    Text(
                      entry.value,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: scheme.outlineVariant),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  total.join(" + "),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // RESET PREFERENCES
  // ---------------------------------------------------------------
  void _confirmResetPreferences() {
    final scheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: scheme.surface,
        title: Text(
          "Reset Preferences",
          style: TextStyle(color: scheme.onSurface),
        ),
        content: Text(
          "This will reset theme, language, and notification settings to their defaults. "
          "Your account and personal data will not be affected.",
          style: TextStyle(color: scheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(context);

              // Reset theme via Provider
              await context.read<ThemeController>().setTheme("System");

              setState(() {
                _appLanguage = "English";
                _notificationsEnabled = true;
              });

              if (!mounted) return;
              SnackBarHelper.showSuccess(
                context,
                "All preferences reset to defaults",
              );
            },
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // INFO DIALOG (Privacy Policy / T&C / About)
  // ---------------------------------------------------------------
  void _showInfoDialog(String title, String content) {
    final scheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: scheme.surface,
        title: Text(
          title,
          style: TextStyle(color: scheme.onSurface),
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: TextStyle(color: scheme.onSurface.withOpacity(0.8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}