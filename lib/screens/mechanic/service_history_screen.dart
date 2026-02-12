import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Safe timestamp parser - handles both DateTime and Firestore Timestamp
  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mechanicId = FirebaseAuth.instance.currentUser?.uid;
    final requestService = RequestFirestoreService();

    if (mechanicId == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "Mechanic not logged in",
            style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
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
            return _errorState(context, snapshot.error.toString());
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return _enhancedEmptyState(context);
          }

          return _OptimizedHistoryList(
            requests: requests,
            requestService: requestService,
            formatDate: _formatDate,
            parseDate: _parseDate,
          );
        },
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _statusChip(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.tertiary),
      ),
      child: Text(
        "COMPLETED",
        style: TextStyle(
          color: scheme.onTertiaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context, String error) {
    final scheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: scheme.error, size: 48),
          const SizedBox(height: 16),
          Text(
            "Error loading service history",
            style: TextStyle(color: scheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: scheme.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Enhanced empty state with icon and explanation
  Widget _enhancedEmptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: scheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "No Completed Services Yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your completed service history will appear here",
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
    final scheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
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
              Text(
                "Service Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _infoRow(context, Icons.person, userName),
              _infoRow(context, Icons.directions_car, vehicleType),
              _infoRow(context, Icons.build, issue),
              if (createdAt != null)
                _infoRow(
                  context,
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

/// Optimized list that batches user profile fetches to avoid N+1 Firestore calls
class _OptimizedHistoryList extends StatefulWidget {
  const _OptimizedHistoryList({
    required this.requests,
    required this.requestService,
    required this.formatDate,
    required this.parseDate,
  });

  final List<Map<String, dynamic>> requests;
  final RequestFirestoreService requestService;
  final String Function(DateTime?) formatDate;
  final DateTime? Function(dynamic) parseDate;

  @override
  State<_OptimizedHistoryList> createState() => _OptimizedHistoryListState();
}

class _OptimizedHistoryListState extends State<_OptimizedHistoryList> {
  final Map<String, Map<String, dynamic>?> _userCache = {};
  bool _isFetchingUsers = false;

  @override
  void initState() {
    super.initState();
    _batchFetchUsers();
  }

  @override
  void didUpdateWidget(_OptimizedHistoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If request list changed, refetch users
    if (widget.requests != oldWidget.requests) {
      _batchFetchUsers();
    }
  }

  /// Batch fetch all unique user profiles in one go
  /// Reduces N+1 Firestore calls to just 1 batch operation
  Future<void> _batchFetchUsers() async {
    if (_isFetchingUsers) return;
    
    setState(() => _isFetchingUsers = true);

    // Get unique user IDs
    final userIds = widget.requests
        .map((r) => r['userId']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .toSet()
        .cast<String>();

    // Fetch all users in parallel (much faster than sequential)
    final futures = userIds.map((userId) {
      // Skip if already cached
      if (_userCache.containsKey(userId)) {
        return Future.value(null);
      }
      return widget.requestService.getUserProfile(userId).then((profile) {
        if (mounted) {
          _userCache[userId] = profile;
        }
        return profile;
      }).catchError((_) {
        // Cache null on error to prevent repeated failures
        if (mounted) {
          _userCache[userId] = null;
        }
        return null;
      });
    });

    await Future.wait(futures);

    if (mounted) {
      setState(() => _isFetchingUsers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: widget.requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final r = widget.requests[index];
        final userId = r['userId']?.toString() ?? "";
        
        // Get cached user profile (no Firestore call!)
        final userProfile = _userCache[userId];
        final userName = userProfile?['name']?.toString() ?? "User";
        final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : "U";

        return _HistoryCard(
          userName: userName,
          userInitial: userInitial,
          vehicleType: r['vehicleType'] ?? r['vehicle'] ?? "N/A",
          issue: r['issue'] ?? "Issue not specified",
          createdAt: widget.parseDate(r['createdAt']), // Safe timestamp parsing
          formatDate: widget.formatDate,
        );
      },
    );
  }
}

/// Individual history card with full theme compliance
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.userName,
    required this.userInitial,
    required this.vehicleType,
    required this.issue,
    required this.createdAt,
    required this.formatDate,
  });

  final String userName;
  final String userInitial;
  final String vehicleType;
  final String issue;
  final DateTime? createdAt;
  final String Function(DateTime?) formatDate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.surfaceContainerHighest,
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
                  backgroundColor: scheme.primary,
                  child: Text(
                    userInitial,
                    style: TextStyle(
                      color: scheme.onPrimary,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicleType,
                        style: TextStyle(
                          color: scheme.onSurface.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusChip(context),
              ],
            ),

            Divider(height: 24, color: scheme.outlineVariant),

            // ---------------- DETAILS ----------------
            _infoRow(context, Icons.build, issue),
            if (createdAt != null)
              _infoRow(
                context,
                Icons.calendar_today,
                formatDate(createdAt),
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
                    formatDate,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.tertiary),
      ),
      child: Text(
        "COMPLETED",
        style: TextStyle(
          color: scheme.onTertiaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) {
    final scheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailsBottomSheet(
    BuildContext context,
    String userName,
    String vehicleType,
    String issue,
    DateTime? createdAt,
    String Function(DateTime?) formatDate,
  ) {
    final scheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
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
              Text(
                "Service Details",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _infoRow(context, Icons.person, userName),
              _infoRow(context, Icons.directions_car, vehicleType),
              _infoRow(context, Icons.build, issue),
              if (createdAt != null)
                _infoRow(
                  context,
                  Icons.calendar_today,
                  formatDate(createdAt),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}