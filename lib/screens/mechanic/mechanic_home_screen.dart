import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/request_firestore_service.dart';
// CHANGE THIS IMPORT TO YOUR ACTUAL LOGIN SCREEN FILE
import '/screens/login_screen.dart';

class MechanicHomeScreen extends StatelessWidget {
  const MechanicHomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mechanicId = FirebaseAuth.instance.currentUser?.uid;
    final requestService = RequestFirestoreService();

    if (mechanicId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mechanic Home'),
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: Text(
            "Error: Mechanic not logged in",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mechanic Home'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GREETING
            const Text(
              'Welcome, Mechanic 👨‍🔧',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Check incoming requests, manage active services, and track your earnings.',
              style: TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 24),

            // QUICK ACTION CARDS
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<int>(
                    stream: requestService.getIncomingRequestsCountStream(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return _InfoCard(
                        title: 'Incoming',
                        value: count.toString(),
                        icon: Icons.notifications_active,
                        color: Colors.orange,
                        isLoading: snapshot.connectionState ==
                            ConnectionState.waiting,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StreamBuilder<int>(
                    stream: requestService.getActiveRequestsCountStream(mechanicId),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return _InfoCard(
                        title: 'Active',
                        value: count.toString(),
                        icon: Icons.build_circle,
                        color: Colors.green,
                        isLoading: snapshot.connectionState ==
                            ConnectionState.waiting,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: StreamBuilder<int>(
                    stream: requestService.getCompletedRequestsCountStream(mechanicId),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return _InfoCard(
                        title: 'Completed',
                        value: count.toString(),
                        icon: Icons.history,
                        color: Colors.blue,
                        isLoading: snapshot.connectionState ==
                            ConnectionState.waiting,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _InfoCard(
                    title: 'Earnings',
                    value: '₹4,500',
                    icon: Icons.account_balance_wallet,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================
// INFO CARD WIDGET
// ===================================================
class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isLoading;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      ),
    );
  }
}
