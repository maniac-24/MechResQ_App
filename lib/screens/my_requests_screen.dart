import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/request_firestore_service.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/request_status_chip.dart';
import 'track_mechanic_screen.dart';

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

  String _formatDate(DateTime d) {
    final formatter = DateFormat('dd/MM/yyyy  HH:mm');
    return formatter.format(d);
  }

  // ---------------- CARD UI ----------------

  Widget _requestCard(Map<String, dynamic> r, String requestId) {
    final scheme = Theme.of(context).colorScheme;
    
    final statusString = (r["status"] ?? "pending").toString();
    final status = parseRequestStatus(statusString);
    
    final vehicleType = r["vehicleType"] ?? r["vehicle"] ?? "N/A";
    final issue = r["issue"] ?? "";
    final createdAt = r["createdAt"] as DateTime?;

    // Build the card body
    final cardBody = Card(
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: scheme.primary,
              child: Text(
                vehicleType.isNotEmpty ? vehicleType[0].toUpperCase() : "R",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimary,
                ),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Vehicle: $vehicleType",
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ---------------- STATUS + CANCEL ----------------
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RequestStatusChip(status: status),

                // CANCEL BUTTON
                if (status.isCancellable) ...[
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => _confirmCancel(requestId),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: scheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            )
          ],
        ),
      ),
    );

    // Wrap in InkWell only when trackable
    if (!status.isTrackable) return cardBody;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrackMechanicScreen(
              requestId: requestId,
            ),
          ),
        );
      },
      child: cardBody,
    );
  }

  // ---------------- CANCEL ----------------

  void _confirmCancel(String requestId) {
    final scheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: scheme.surface,
        title: Text(
          "Cancel Request",
          style: TextStyle(color: scheme.onSurface),
        ),
        content: Text(
          "Are you sure you want to cancel this request?",
          style: TextStyle(color: scheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _requestService.cancelRequest(requestId);
                if (mounted) {
                  SnackBarHelper.showInfo(
                    context,
                    "Request cancelled",
                  );
                }
              } catch (e) {
                if (mounted) {
                  SnackBarHelper.showError(
                    context,
                    "Failed to cancel request: ${e.toString()}",
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Requests"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: scheme.primary,
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
            return Center(
              child: CircularProgressIndicator(
                color: scheme.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: scheme.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(
                      color: scheme.onSurface.withOpacity(0.7),
                    ),
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
              children: [
                Center(
                  child: Text(
                    "No requests found.",
                    style: TextStyle(
                      color: scheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    "No requests found.",
                    style: TextStyle(
                      color: scheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            );
          }

          final requests = snapshot.data!;
          
          // Parse statuses once
          final requestsWithStatus = requests.map((r) {
            final statusString = (r["status"] ?? "pending").toString();
            final status = parseRequestStatus(statusString);
            return {...r, '_parsedStatus': status};
          }).toList();

          final active = requestsWithStatus
              .where((r) => (r['_parsedStatus'] as RequestStatus).isActive)
              .toList();
          
          final history = requestsWithStatus
              .where((r) => !(r['_parsedStatus'] as RequestStatus).isActive)
              .toList();

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
    final scheme = Theme.of(context).colorScheme;
    
    if (list.isEmpty) {
      return Center(
        child: Text(
          "No active requests",
          style: TextStyle(
            color: scheme.onSurface.withOpacity(0.7),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final request = list[i];
        final requestId = request["requestId"] ?? request["id"] ?? "";
        return _requestCard(request, requestId);
      },
    );
  }

  Widget _buildHistory(List<Map<String, dynamic>> list) {
    final scheme = Theme.of(context).colorScheme;
    
    if (list.isEmpty) {
      return Center(
        child: Text(
          "No request history",
          style: TextStyle(
            color: scheme.onSurface.withOpacity(0.7),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = list[i];
        final requestId = r["requestId"] ?? r["id"] ?? "";
        final vehicleType = r["vehicleType"] ?? r["vehicle"] ?? "N/A";
        final issue = r["issue"] ?? "";
        
        final statusString = (r["status"] ?? "pending").toString();
        final status = parseRequestStatus(statusString);
        
        final createdAt = r["createdAt"] as DateTime?;

        return Card(
          color: scheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: scheme.primary,
              child: Text(
                vehicleType.isNotEmpty ? vehicleType[0].toUpperCase() : "R",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimary,
                ),
              ),
            ),
            title: Text(
              issue.length > 50 ? '${issue.substring(0, 50)}...' : issue,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "Vehicle: $vehicleType",
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ],
            ),
            trailing: RequestStatusChip(status: status),
          ),
        );
      },
    );
  }
}