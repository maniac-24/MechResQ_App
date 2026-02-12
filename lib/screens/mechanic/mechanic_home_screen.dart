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

/// ============================================================================
/// MECHANIC HOME SCREEN - PRODUCTION READY
/// ============================================================================
/// Real-time status management, theme-driven colors, live streams.
/// No forced offline on init, no hard-coded colors, no fake data.
/// ============================================================================
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
    // ✅ FIXED: No forced offline on init
    // Status is controlled ONLY by:
    // 1. User toggle
    // 2. Logout
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGOUT (FORCES OFFLINE)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _logout() async {
    // ✅ Force OFFLINE on logout
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

  // ═══════════════════════════════════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ══════════════════════════════════════════════════════════
                    // GREETING
                    // ══════════════════════════════════════════════════════════
                    Text(
                      'Welcome, $name 👨‍🔧',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 16),

                    // ══════════════════════════════════════════════════════════
                    // ONLINE / OFFLINE SWITCH (THEME-AWARE)
                    // ══════════════════════════════════════════════════════════
                    Card(
                      elevation: 2,
                      child: SwitchListTile(
                        title: Text(
                          isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isOnline ? scheme.secondary : scheme.error,
                          ),
                        ),
                        subtitle: Text(
                          isOnline
                              ? 'You can receive requests'
                              : 'You will not receive requests',
                          style: TextStyle(
                            color: scheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        value: isOnline,
                        onChanged: (value) async {
                          await _statusService.setOnlineStatus(
                            mechanicId: mechanicId,
                            isOnline: value,
                          );
                        },
                        secondary: Icon(
                          isOnline ? Icons.toggle_on : Icons.toggle_off,
                          size: 36,
                          color: isOnline ? scheme.secondary : scheme.error,
                        ),
                        activeColor: scheme.secondary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ══════════════════════════════════════════════════════════
                    // ROW 1: INCOMING + ACTIVE
                    // ══════════════════════════════════════════════════════════
                    Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<int>(
                            stream:
                                _requestService.getIncomingRequestsCountStream(
                              mechanicId: mechanicId,
                              isOnline: isOnline,
                            ),
                            builder: (context, snap) {
                              return _InfoCard(
                                title: 'Incoming',
                                value: '${snap.data ?? 0}',
                                icon: Icons.notifications_active,
                                type: _InfoCardType.incoming,
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
                                .getActiveRequestsCountStream(mechanicId),
                            builder: (context, snap) {
                              return _InfoCard(
                                title: 'Active',
                                value: '${snap.data ?? 0}',
                                icon: Icons.build_circle,
                                type: _InfoCardType.active,
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

                    // ══════════════════════════════════════════════════════════
                    // ROW 2: COMPLETED + EARNINGS
                    // ══════════════════════════════════════════════════════════
                    Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<int>(
                            stream: _requestService
                                .getCompletedRequestsCountStream(mechanicId),
                            builder: (context, snap) {
                              return _InfoCard(
                                title: 'Completed',
                                value: '${snap.data ?? 0}',
                                icon: Icons.history,
                                type: _InfoCardType.completed,
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
                          child: StreamBuilder<double>(
                            stream: _requestService
                                .getTotalEarningsStream(mechanicId),
                            builder: (context, snap) {
                              final earnings = snap.data ?? 0;
                              return _InfoCard(
                                title: 'Earnings',
                                value: snap.connectionState ==
                                        ConnectionState.waiting
                                    ? '—'
                                    : '₹${earnings.toStringAsFixed(0)}',
                                icon: Icons.account_balance_wallet,
                                type: _InfoCardType.earnings,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const EarningsScreen(),
                                    ),
                                  );
                                },
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

// ═══════════════════════════════════════════════════════════════════════════
// INFO CARD TYPE (SEMANTIC DESIGN)
// ═══════════════════════════════════════════════════════════════════════════
enum _InfoCardType { incoming, active, completed, earnings }

// ═══════════════════════════════════════════════════════════════════════════
// INFO CARD (100% THEME-DRIVEN)
// ═══════════════════════════════════════════════════════════════════════════
class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final _InfoCardType type;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.type,
    this.onTap,
  });

  // ✅ SEMANTIC COLOR RESOLUTION (THEME-DRIVEN)
  Color _resolveColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (type) {
      case _InfoCardType.incoming:
        return scheme.tertiary ?? Colors.orange.shade600;
      case _InfoCardType.active:
        return scheme.primary;
      case _InfoCardType.completed:
        return scheme.secondary;
      case _InfoCardType.earnings:
        return scheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor(context);

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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}