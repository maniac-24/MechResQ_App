import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/request_firestore_service.dart';

class ServiceHistoryScreen extends StatelessWidget {
  const ServiceHistoryScreen({super.key});

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return "Unknown";
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return "${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}";
  }

  @override
  Widget build(BuildContext context) {
    final yellow = Theme.of(context).colorScheme.primary;
    final mechanicId = FirebaseAuth.instance.currentUser?.uid;
    final requestService = RequestFirestoreService();

    if (mechanicId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Mechanic not logged in",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Service History"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: requestService.getMechanicRequestsByStatusStream(
          mechanicId,
          'completed',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _errorState(snapshot.error.toString());
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                "No completed services yet",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final r = requests[index];
              final vehicleType = r['vehicleType'] ?? r['vehicle'] ?? "N/A";
              final issue = r['issue'] ?? "Issue not specified";
              final createdAt = r['createdAt'] as DateTime?;
              final userId = r['userId'] ?? "";

              return FutureBuilder<Map<String, dynamic>?>(
                future: requestService.getUserProfile(userId),
                builder: (context, userSnapshot) {
                  final userName =
                      userSnapshot.data?['name']?.toString() ?? "User";
                  final userInitial =
                      userName.isNotEmpty ? userName[0].toUpperCase() : "U";

                  return Card(
                    color: const Color(0xFF1C1C1C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ---------------- HEADER ----------------
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: yellow,
                                child: Text(
                                  userInitial,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      vehicleType,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _statusChip(),
                            ],
                          ),

                          const Divider(height: 24),

                          // ---------------- DETAILS ----------------
                          _infoRow(Icons.build, issue),
                          if (createdAt != null)
                            _infoRow(
                              Icons.calendar_today,
                              _formatDate(createdAt),
                            ),

                          const SizedBox(height: 12),

                          // ---------------- ACTION ----------------
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.info_outline),
                              label: const Text("View Details"),
                              onPressed: () {
                                _showDetailsBottomSheet(
                                  context,
                                  userName,
                                  vehicleType,
                                  issue,
                                  createdAt,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _statusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green),
      ),
      child: const Text(
        "COMPLETED",
        style: TextStyle(
          color: Colors.green,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            "Error loading service history",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ================= BOTTOM SHEET =================

  void _showDetailsBottomSheet(
    BuildContext context,
    String userName,
    String vehicleType,
    String issue,
    DateTime? createdAt,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Service Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _infoRow(Icons.person, userName),
              _infoRow(Icons.directions_car, vehicleType),
              _infoRow(Icons.build, issue),
              if (createdAt != null)
                _infoRow(
                  Icons.calendar_today,
                  _formatDate(createdAt),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
