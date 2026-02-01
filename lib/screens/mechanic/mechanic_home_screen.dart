import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../services/request_firestore_service.dart';
import '../../services/mechanic_status_service.dart';

import '../login_screen.dart';
import 'incoming_requests_screen.dart';
import 'active_service_screen.dart';
import 'service_history_screen.dart';
import 'earnings_screen.dart';

class MechanicHomeScreen extends StatefulWidget {
  const MechanicHomeScreen({super.key});

  @override
  State<MechanicHomeScreen> createState() => _MechanicHomeScreenState();
}

class _MechanicHomeScreenState extends State<MechanicHomeScreen> {
  final _authService = AuthService();
  final _requestService = RequestFirestoreService();
  final _statusService = MechanicStatusService();

  late final String mechanicId;

  @override
  void initState() {
    super.initState();

    mechanicId = FirebaseAuth.instance.currentUser!.uid;

    // 🔴 DEFAULT AFTER LOGIN → OFFLINE
    _statusService.setOnlineStatus(
      mechanicId: mechanicId,
      isOnline: false,
    );
  }

  Future<void> _logout() async {
    // Force OFFLINE on logout
    await _statusService.setOnlineStatus(
      mechanicId: mechanicId,
      isOnline: false,
    );

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mechanic Home'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),

      // 🔁 REALTIME ONLINE STATUS
      body: StreamBuilder<bool>(
        stream: _statusService.onlineStatusStream(mechanicId),
        builder: (context, statusSnap) {
          final isOnline = statusSnap.data ?? false;

          return FutureBuilder<Map<String, dynamic>?>(
            future: _authService.getCurrentUserProfile(),
            builder: (context, profileSnap) {
              final name = profileSnap.data?['name'] ?? 'Mechanic';

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GREETING
                    Text(
                      'Welcome, $name 👨‍🔧',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ONLINE / OFFLINE SWITCH
                    Card(
                      child: SwitchListTile(
                        title: Text(
                          isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isOnline ? Colors.green : Colors.red,
                          ),
                        ),
                        subtitle: Text(
                          isOnline
                              ? 'You can receive requests'
                              : 'You will not receive requests',
                        ),
                        value: isOnline,
                        onChanged: (value) async {
                          await _statusService.setOnlineStatus(
                            mechanicId: mechanicId,
                            isOnline: value,
                          );
                        },
                        secondary: Icon(
                          isOnline
                              ? Icons.toggle_on
                              : Icons.toggle_off,
                          size: 36,
                          color:
                              isOnline ? Colors.green : Colors.red,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ROW 1
                    Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<int>(
                            stream: _requestService
                                .getIncomingRequestsCountStream(
                              mechanicId: mechanicId,
                              isOnline: isOnline,
                            ),
                            builder: (context, snap) {
                              return _InfoCard(
                                title: 'Incoming',
                                value: '${snap.data ?? 0}',
                                icon:
                                    Icons.notifications_active,
                                color: Colors.orange,
                                onTap: isOnline
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const IncomingRequestsScreen(),
                                          ),
                                        );
                                      }
                                    : null, // 🚫 block when offline
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StreamBuilder<int>(
                            stream: _requestService
                                .getActiveRequestsCountStream(
                                    mechanicId),
                            builder: (context, snap) {
                              return _InfoCard(
                                title: 'Active',
                                value: '${snap.data ?? 0}',
                                icon: Icons.build_circle,
                                color: Colors.green,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ActiveServiceScreen(),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ROW 2
                    Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<int>(
                            stream: _requestService
                                .getCompletedRequestsCountStream(
                                    mechanicId),
                            builder: (context, snap) {
                              return _InfoCard(
                                title: 'Completed',
                                value: '${snap.data ?? 0}',
                                icon: Icons.history,
                                color: Colors.blue,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ServiceHistoryScreen(),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoCard(
                            title: 'Earnings',
                            value: '₹4,500',
                            icon: Icons.account_balance_wallet,
                            color: Colors.purple,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const EarningsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ===================================================
// INFO CARD
// ===================================================
class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
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
      ),
    );
  }
}
