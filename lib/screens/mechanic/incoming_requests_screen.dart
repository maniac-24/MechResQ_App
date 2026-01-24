import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/request_firestore_service.dart';

class IncomingRequestsScreen extends StatefulWidget {
  const IncomingRequestsScreen({super.key});

  @override
  State<IncomingRequestsScreen> createState() =>
      _IncomingRequestsScreenState();
}

class _IncomingRequestsScreenState extends State<IncomingRequestsScreen> {
  final RequestFirestoreService _requestService = RequestFirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------- ACTION HANDLERS ----------------
  Future<void> _acceptRequest(String requestId) async {
    final mechanicId = _auth.currentUser?.uid;
    if (mechanicId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Mechanic not logged in")),
      );
      return;
    }

    try {
      await _requestService.acceptRequest(requestId, mechanicId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request accepted")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error accepting request: $e")),
      );
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reject Request"),
        content: const Text(
            "Are you sure you want to reject this service request?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Reject"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _requestService.rejectRequest(requestId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request rejected")),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error rejecting request: $e")),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case "accepted":
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return "Unknown";
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return "${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} min${difference.inMinutes > 1 ? 's' : ''} ago";
    } else {
      return "Just now";
    }
  }

  @override
  Widget build(BuildContext context) {
    final yellow = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Incoming Requests"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _requestService.getIncomingRequestsStream(),
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
                    "Error loading requests",
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
                "No incoming requests",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final r = requests[i];
              final status = (r["status"] ?? "pending").toString();
              final vehicleType = r["vehicleType"] ?? r["vehicle"] ?? "N/A";
              final issue = r["issue"] ?? "";
              final location = r["location"] ?? "";
              final createdAt = r["createdAt"] as DateTime?;
              final userId = r["userId"] ?? "";

              return FutureBuilder<Map<String, dynamic>?>(
                future: _requestService.getUserProfile(userId),
                builder: (context, userSnapshot) {
                  final userName = userSnapshot.data?["name"]?.toString() ?? "User";
                  final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : "U";

                  return Card(
                    color: const Color(0xFF1C1C1C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
                                          color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  // ignore: deprecated_member_use
                                  color: _statusColor(status).withOpacity(0.2),
                                  border: Border.all(
                                      color: _statusColor(status)),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _statusColor(status),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ---------------- DETAILS ----------------
                          Row(
                            children: [
                              const Icon(Icons.build,
                                  size: 16, color: Colors.white70),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  issue,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.white70),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  location,
                                  style:
                                      const TextStyle(color: Colors.white70),
                                ),
                              ),
                              if (createdAt != null)
                                Text(
                                  _formatTimeAgo(createdAt),
                                  style:
                                      const TextStyle(color: Colors.white38),
                                ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // ---------------- ACTIONS ----------------
                          if (status == "pending")
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: Colors.red),
                                    ),
                                    onPressed: () => _rejectRequest(r["requestId"]),
                                    child: const Text(
                                      "Reject",
                                      style:
                                          TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _acceptRequest(r["requestId"]),
                                    child: const Text("Accept"),
                                  ),
                                ),
                              ],
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
}
