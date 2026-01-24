import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/request_firestore_service.dart';

class ActiveServiceScreen extends StatefulWidget {
  const ActiveServiceScreen({super.key});

  @override
  State<ActiveServiceScreen> createState() => _ActiveServiceScreenState();
}

class _ActiveServiceScreenState extends State<ActiveServiceScreen> {
  final RequestFirestoreService _requestService = RequestFirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _loading = false;

  // ---------------- MARK COMPLETED ----------------
  Future<void> _completeRequest(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Complete Service"),
        content: const Text(
            "Are you sure you want to mark this service as completed?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Complete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _loading = true);
      try {
        await _requestService.completeRequest(requestId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Service marked as completed")),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error completing service: $e")),
        );
      } finally {
        if (mounted) {
          setState(() => _loading = false);
        }
      }
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return "Unknown";
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final yellow = Theme.of(context).colorScheme.primary;
    final mechanicId = _auth.currentUser?.uid;

    if (mechanicId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Active Service"),
          centerTitle: true,
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
        title: const Text("Active Service"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _requestService.getMechanicRequestsByStatusStream(
          mechanicId,
          'accepted',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    "Error loading active services",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                "No active services",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          // Show first active request (or list if multiple)
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (_, index) {
              final r = requests[index];
              final vehicleType = r["vehicleType"] ?? r["vehicle"] ?? "N/A";
              final issue = r["issue"] ?? "";
              final location = r["location"] ?? "";
              final createdAt = r["createdAt"] as DateTime?;
              final userId = r["userId"] ?? "";
              final requestId = r["requestId"] ?? "";

              return FutureBuilder<Map<String, dynamic>?>(
                future: _requestService.getUserProfile(userId),
                builder: (context, userSnapshot) {
                  final userName =
                      userSnapshot.data?["name"]?.toString() ?? "User";
                  final userInitial =
                      userName.isNotEmpty ? userName[0].toUpperCase() : "U";

                  return Column(
                    children: [
                      // ---------------- STATUS CARD ----------------
                      Card(
                        color: const Color(0xFF1C1C1C),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.circle, color: Colors.green, size: 14),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  "Active Service",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              if (_loading)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ---------------- USER DETAILS ----------------
                      Card(
                        color: const Color(0xFF1C1C1C),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: yellow,
                                    child: Text(
                                      userInitial,
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userName,
                                          style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          vehicleType,
                                          style: const TextStyle(
                                              color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              _infoRow(Icons.build, issue),
                              _infoRow(Icons.location_on, location),
                              if (createdAt != null)
                                _infoRow(Icons.access_time,
                                    "Started at ${_formatDateTime(createdAt)}"),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ---------------- ACTION BUTTON ----------------
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading
                              ? null
                              : () => _completeRequest(requestId),
                          child: const Text("Mark Completed"),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ---------------- INFO ROW ----------------
  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
}
