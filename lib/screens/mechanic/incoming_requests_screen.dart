import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/request_firestore_service.dart';
import '../../services/mechanic_firestore_service.dart';
import 'request_route_preview_screen.dart';

/// ============================================================================
/// INCOMING REQUESTS SCREEN - PRODUCTION READY
/// ============================================================================
/// Real-time incoming service requests with 100% theme-driven colors,
/// Timestamp safety, and performance optimizations.
/// ============================================================================
class IncomingRequestsScreen extends StatefulWidget {
  const IncomingRequestsScreen({super.key, this.onSwitchToActiveTab});

  /// Called when mechanic accepts a request from the route preview screen (switch to Active tab).
  final VoidCallback? onSwitchToActiveTab;

  @override
  State<IncomingRequestsScreen> createState() =>
      _IncomingRequestsScreenState();
}

class _IncomingRequestsScreenState extends State<IncomingRequestsScreen> {
  final RequestFirestoreService _requestService = RequestFirestoreService();
  final MechanicFirestoreService _mechanicService = MechanicFirestoreService();

  final String mechanicId = FirebaseAuth.instance.currentUser!.uid;

  bool isOnline = true;

  // ✅ Performance: Cache user profiles to avoid repeated fetches
  final Map<String, Map<String, dynamic>> _userProfileCache = {};

  // ═══════════════════════════════════════════════════════════════════════════
  // FETCH USER PROFILE (WITH CACHING)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    if (_userProfileCache.containsKey(userId)) {
      return _userProfileCache[userId];
    }

    final profile = await _requestService.getUserProfile(userId);
    if (profile != null) {
      _userProfileCache[userId] = profile;
    }
    return profile;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OPEN REQUEST PREVIEW (MAP + ROUTE + ETA)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _openRequestPreview(Map<String, dynamic> r) async {
    final requestId = r['requestId']?.toString();
    final userLat = (r['userLat'] as num?)?.toDouble();
    final userLng = (r['userLng'] as num?)?.toDouble();
    final locationAddress =
        r['locationAddress']?.toString() ?? r['location']?.toString() ?? '';

    if (requestId == null || requestId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid request data'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (userLat == null || userLng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Request location not available'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final shop = await _mechanicService.getCurrentMechanicShopLocation();
    if (shop == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Set your workshop location in Profile first'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final args = RequestRoutePreviewArgs(
      requestId: requestId,
      userLat: userLat,
      userLng: userLng,
      locationAddress: locationAddress,
      shopLat: shop.lat,
      shopLng: shop.lng,
    );

    if (!mounted) return;
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => RequestRoutePreviewScreen(
          args: args,
          onAccepted: widget.onSwitchToActiveTab,
        ),
      ),
    );

    if (result == 'accepted' && mounted) {
      widget.onSwitchToActiveTab?.call();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REJECT REQUEST
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _rejectRequest(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          "Reject Request",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          "Are you sure you want to reject this service request?",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
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
          SnackBar(
            content: const Text("Request rejected"),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error rejecting request: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUS COLOR (100% THEME-DRIVEN)
  // ═══════════════════════════════════════════════════════════════════════════
  Color _statusColor(String status, BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    switch (status) {
      case "accepted":
        return scheme.secondary; // Success-like (green in Material 3)
      case "pending":
        return scheme.tertiary ?? Colors.orange.shade600; // Warning-like
      default:
        return scheme.primary;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAFE DATETIME EXTRACTION (HANDLES TIMESTAMP + DATETIME)
  // ═══════════════════════════════════════════════════════════════════════════
  DateTime? _extractDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is DateTime) {
      return value;
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIME AGO FORMATTER
  // ═══════════════════════════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Incoming Requests"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _requestService.getIncomingRequestsStream(
          mechanicId: mechanicId,
          isOnline: true,
        ),
        builder: (context, snapshot) {
          // ── Loading ───────────────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          }

          // ── Error ─────────────────────────────────────────────────────────
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Error loading requests",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final requests = snapshot.data ?? [];

          // ── Empty State ───────────────────────────────────────────────────
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No incoming requests",
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "New requests will appear here",
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          // ── Request List ──────────────────────────────────────────────────
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final r = requests[i];
              final status = (r["status"] ?? "pending").toString();
              final vehicleType = r["vehicleType"] ?? r["vehicle"] ?? "N/A";
              final issue = r["issue"] ?? "";
              final location = r["location"] ?? "";
              final createdAt = _extractDateTime(r["createdAt"]); // ✅ Safe extraction
              final userId = r["userId"] ?? "";

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getUserProfile(userId), // ✅ Uses cache
                builder: (context, userSnapshot) {
                  final userName =
                      userSnapshot.data?["name"]?.toString() ?? "User";
                  final userInitial = userName.isNotEmpty
                      ? userName[0].toUpperCase()
                      : "U";

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: status == "pending"
                          ? () => _openRequestPreview(r)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Header ────────────────────────────────────
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      userInitial,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
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
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.directions_car,
                                            size: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            vehicleType,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: _statusColor(status, context)
                                        .withOpacity(0.1),
                                    border: Border.all(
                                      color: _statusColor(status, context),
                                    ),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _statusColor(status, context),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // ── Details ───────────────────────────────────
                            Row(
                              children: [
                                Icon(
                                  Icons.build_outlined,
                                  size: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    issue.isEmpty
                                        ? "No issue specified"
                                        : issue,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    location.isEmpty
                                        ? "Location not specified"
                                        : location,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (createdAt != null)
                                  Text(
                                    _formatTimeAgo(createdAt),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.4),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),

                            // ── Actions ───────────────────────────────────
                            if (status == "pending") ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .error,
                                      ),
                                      onPressed: () =>
                                          _rejectRequest(r["requestId"]),
                                      icon:
                                          const Icon(Icons.close, size: 18),
                                      label: const Text("Reject"),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        foregroundColor: Colors.black,
                                      ),
                                      onPressed: () =>
                                          _openRequestPreview(r),
                                      icon: const Icon(Icons.map, size: 18),
                                      label: const Text("Preview"),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
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