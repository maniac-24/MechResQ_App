import 'package:flutter/material.dart';
import '../services/request_firestore_service.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RequestFirestoreService _requestService = RequestFirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------------- HELPERS ----------------

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.blueAccent;
      case 'on the way':
        return Colors.orangeAccent;
      case 'completed':
        return Colors.greenAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.amber;
    }
  }

  bool _isActive(String status) {
    return status.toLowerCase() == 'pending' ||
        status.toLowerCase() == 'accepted' ||
        status.toLowerCase() == 'on the way';
  }

  String _formatDate(DateTime d) {
    return "${d.day}/${d.month}/${d.year}  ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
  }

  // ---------------- CARD UI ----------------

  Widget _requestCard(Map<String, dynamic> r, String requestId) {
    final status = (r["status"] ?? "pending").toString();
    final isPending = status.toLowerCase() == "pending";
    final vehicleType = r["vehicleType"] ?? r["vehicle"] ?? "N/A";
    final issue = r["issue"] ?? "";
    final createdAt = r["createdAt"] as DateTime?;

    return Card(
      color: const Color(0xFF1C1C1C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                vehicleType.isNotEmpty ? vehicleType[0].toUpperCase() : "R",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            const SizedBox(width: 12),

            // ---------------- DETAILS ----------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue.length > 50 ? '${issue.substring(0, 50)}...' : issue,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Vehicle: $vehicleType",
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ],
              ),
            ),

            // ---------------- STATUS + CANCEL ----------------
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _statusColor(status)),
                    // ignore: deprecated_member_use
                    color: _statusColor(status).withOpacity(0.15),
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

                // CANCEL BUTTON
                if (isPending) ...[
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => _confirmCancel(requestId),
                    child: const Text(
                      "Cancel",
                      style:
                          TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                ],
              ],
            )
          ],
        ),
      ),
    );
  }

  // ---------------- CANCEL ----------------

  void _confirmCancel(String requestId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Request"),
        content:
            const Text("Are you sure you want to cancel this request?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _requestService.updateRequestStatus(requestId, 'cancelled');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Request cancelled")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to cancel request: ${e.toString()}")),
                  );
                }
              }
            },
            child: const Text("Yes, Cancel"),
          )
        ],
      ),
    );
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Requests"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "ACTIVE"),
            Tab(text: "HISTORY"),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _requestService.getUserRequestsStream(),
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
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return TabBarView(
              controller: _tabController,
              children: const [
                Center(
                  child: Text(
                    "No requests found.",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                Center(
                  child: Text(
                    "No requests found.",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            );
          }

          final requests = snapshot.data!;
          final active = requests.where((r) => _isActive(r["status"])).toList();
          final history = requests.where((r) => !_isActive(r["status"])).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(active),
              _buildHistory(history),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          "No active requests",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final request = list[i];
        final requestId = request["requestId"] ?? request["id"] ?? "";
        return _requestCard(request, requestId);
      },
    );
  }

  Widget _buildHistory(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          "No request history",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = list[i];
        final requestId = r["requestId"] ?? r["id"] ?? "";
        final vehicleType = r["vehicleType"] ?? r["vehicle"] ?? "N/A";
        final issue = r["issue"] ?? "";
        final status = (r["status"] ?? "pending").toString();
        final createdAt = r["createdAt"] as DateTime?;

        return Card(
          color: const Color(0xFF1C1C1C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                vehicleType.isNotEmpty ? vehicleType[0].toUpperCase() : "R",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            title: Text(
              issue.length > 50 ? '${issue.substring(0, 50)}...' : issue,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "Vehicle: $vehicleType",
                  style: const TextStyle(fontSize: 12),
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(createdAt),
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _statusColor(status)),
                // ignore: deprecated_member_use
                color: _statusColor(status).withOpacity(0.15),
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
          ),
        );
      },
    );
  }
}
