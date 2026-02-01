import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/request_firestore_service.dart';

class ActiveServiceScreen extends StatefulWidget {
  const ActiveServiceScreen({super.key});

  @override
  State<ActiveServiceScreen> createState() => _ActiveServiceScreenState();
}

class _ActiveServiceScreenState extends State<ActiveServiceScreen> {
  final _auth = FirebaseAuth.instance;
  final _service = RequestFirestoreService();

  bool _loading = false;

  // =====================================================
  // FIRESTORE STATUS UPDATE (STRICT)
  // =====================================================
  Future<void> _updateStatus({
    required String requestId,
    required String newStatus,
    required String timestampField,
  }) async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(requestId)
          .update({
        'status': newStatus,
        timestampField: FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated → $newStatus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // =====================================================
  // COMPLETE (WITH CONFIRMATION)
  // =====================================================
  Future<void> _markCompleted(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Complete Service'),
        content: const Text(
          'Are you sure you want to mark this service as completed?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _updateStatus(
      requestId: requestId,
      newStatus: 'completed',
      timestampField: 'completedAt',
    );

    // 🔔 Earnings placeholder (future)
    // TODO: Trigger earnings calculation / payment settlement
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final mechanicId = _auth.currentUser?.uid;

    if (mechanicId == null) {
      return const Scaffold(
        body: Center(child: Text('Mechanic not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Active Service')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.getMechanicRequestsByStatusStream(
          mechanicId,
          'accepted',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                'No active services',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final r = requests.first; // STRICT: one active job
          final requestId = r['requestId'];
          final status = r['status'] ?? 'accepted';

          // ---------------- BUTTON STATES ----------------
          final canStart = status == 'accepted';
          final canOngoing = status == 'in_progress_started';
          final canComplete = status == 'in_progress_ongoing';

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // STATUS CARD
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.build_circle,
                      color: status == 'completed'
                          ? Colors.grey
                          : Colors.green,
                    ),
                    title: const Text('Service Status'),
                    subtitle: Text(status.toUpperCase()),
                    trailing: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 20),

                // START SERVICE
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (!_loading && canStart)
                        ? () => _updateStatus(
                              requestId: requestId,
                              newStatus: 'in_progress_started',
                              timestampField: 'startedAt',
                            )
                        : null,
                    child: const Text('Start Service'),
                  ),
                ),

                const SizedBox(height: 12),

                // ONGOING
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (!_loading && canOngoing)
                        ? () => _updateStatus(
                              requestId: requestId,
                              newStatus: 'in_progress_ongoing',
                              timestampField: 'ongoingAt',
                            )
                        : null,
                    child: const Text('Mark Ongoing'),
                  ),
                ),

                const SizedBox(height: 12),

                // COMPLETE
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: (!_loading && canComplete)
                        ? () => _markCompleted(requestId)
                        : null,
                    child: const Text('Mark Complete'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
