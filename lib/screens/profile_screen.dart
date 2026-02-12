import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/snackbar_helper.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final AuthService _auth = AuthService();

  /// Extracted logout confirmation dialog
  void _confirmLogout(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: scheme.surface,
        title: Text(
          "Logout",
          style: TextStyle(color: scheme.onSurface),
        ),
        content: Text(
          "Are you sure you want to logout?",
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
              await _auth.logout();
              
              if (!context.mounted) return;
              
              SnackBarHelper.showInfo(context, 'Logged out successfully');
              
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (r) => false,
              );
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _auth.getMyProfileStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: scheme.primary,
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                "Could not load profile.",
                style: TextStyle(color: scheme.onSurface),
              ),
            );
          }

          final profile = snapshot.data!;

          // Safe read from Firestore map
          final name = (profile["name"] ?? "User").toString();
          final email = (profile["email"] ?? "").toString();
          final phone = (profile["phone"] ?? "").toString();

          final initial = name.isNotEmpty ? name[0].toUpperCase() : "U";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------- PROFILE HEADER ----------------
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: scheme.primary,
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ---------------- CONTACT INFORMATION ----------------
                Text(
                  "Contact Information",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  color: scheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              color: scheme.onSurface.withOpacity(0.7),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                phone,
                                style: TextStyle(
                                  color: scheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Divider(
                          height: 24,
                          color: scheme.outlineVariant,
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.email,
                              color: scheme.onSurface.withOpacity(0.7),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                email,
                                style: TextStyle(
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ---------------- ACTION BUTTONS ----------------
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Profile"),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.logout, color: scheme.error),
                    label: Text(
                      "Logout",
                      style: TextStyle(color: scheme.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: scheme.error),
                    ),
                    onPressed: () => _confirmLogout(context),
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: Text(
                    "MechResQ • v1.0.0",
                    style: TextStyle(
                      color: scheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}