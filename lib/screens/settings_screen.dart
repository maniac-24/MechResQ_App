// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true; // already dark, UI only

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // --------- APPEARANCE ----------
          const Text(
            "Appearance",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          SwitchListTile(
            value: _darkModeEnabled,
            onChanged: (v) {
              setState(() => _darkModeEnabled = v);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Dark mode already enabled")),
              );
            },
            title: const Text("Dark Mode"),
            secondary: const Icon(Icons.dark_mode),
          ),

          const Divider(),

          // --------- NOTIFICATIONS ----------
          const Text(
            "Notifications",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          SwitchListTile(
            value: _notificationsEnabled,
            onChanged: (v) {
              setState(() => _notificationsEnabled = v);
            },
            title: const Text("Enable Notifications"),
            secondary: const Icon(Icons.notifications_active),
          ),

          const Divider(),

          // --------- LEGAL ----------
          const Text(
            "Legal",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text("Privacy Policy"),
            onTap: () => _showInfoDialog(
              context,
              "Privacy Policy",
              "We respect your privacy.\n\n"
              "User data is used only for service functionality.",
            ),
          ),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("About App"),
            onTap: () => _showInfoDialog(
              context,
              "About MechResQ",
              "MechResQ\nVersion 1.0.0\n\n"
              "A vehicle breakdown assistance app.",
            ),
          ),
        ],
      ),
    );
  }

  // ---------- INFO DIALOG ----------
  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
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
