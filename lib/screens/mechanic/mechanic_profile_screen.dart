import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'edit_mechanic_profile_screen.dart';

class MechanicProfileScreen extends StatelessWidget {
  MechanicProfileScreen({super.key});

  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.logout();
              Navigator.pushNamedAndRemoveUntil(
                // ignore: use_build_context_synchronously
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _auth.getCurrentUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Could not load profile."));
          }

          final profile = snapshot.data!;

          final String name = (profile['name'] ?? 'Mechanic').toString();
          final String email = (profile['email'] ?? '-').toString();
          final String phone = (profile['phone'] ?? '-').toString();

          // ✅ FIX: supports both shopName and garageName
          final String garage = (profile['shopName'] ??
                  profile['garageName'] ??
                  'Garage')
              .toString();

          // ✅ FIX: vehicleTypes is List in Firestore, convert to String
          final vehicleTypesRaw = profile['vehicleTypes'];
          final String vehicleTypes = (vehicleTypesRaw is List)
              ? vehicleTypesRaw.map((e) => e.toString()).join(', ')
              : (vehicleTypesRaw?.toString() ?? 'Bike, Car');

          final String rating = (profile['rating'] ?? '0').toString();
          final String initial =
              name.isNotEmpty ? name[0].toUpperCase() : 'M';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ================= HEADER =================
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: primaryColor,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(garage, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(rating),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ================= BASIC INFO =================
              _sectionTitle("Basic Information"),
              _infoRow(Icons.phone, "Phone", phone),
              _infoRow(Icons.email, "Email", email),

              const SizedBox(height: 24),

              // ================= PROFESSIONAL =================
              _sectionTitle("Professional Details"),
              _infoRow(Icons.store, "Garage", garage),
              _infoRow(Icons.directions_car, "Vehicle Types", vehicleTypes),

              const SizedBox(height: 32),

              // ================= ACTIONS =================
              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text("Edit Profile"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditMechanicProfileScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  await _auth.logout();
                  Navigator.pushNamedAndRemoveUntil(
                    // ignore: use_build_context_synchronously
                    context,
                    '/login',
                    (route) => false,
                  );
                },
              ),

              const SizedBox(height: 30),

              const Center(
                child: Text(
                  "MechResQ • Mechanic Panel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ================= HELPERS =================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
