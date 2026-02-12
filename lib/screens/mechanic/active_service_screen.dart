import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/request_firestore_service.dart';

/// ============================================================================
/// ACTIVE SERVICE SCREEN - PRODUCTION READY
/// ============================================================================
/// Real-time mechanic service tracking with Firestore streams.
/// Theme-compatible, handles edge cases, proper error handling.
/// ============================================================================
class ActiveServiceScreen extends StatefulWidget {
  const ActiveServiceScreen({super.key});

  @override
  State<ActiveServiceScreen> createState() => _ActiveServiceScreenState();
}

class _ActiveServiceScreenState extends State<ActiveServiceScreen> {
  final _auth = FirebaseAuth.instance;
  final _service = RequestFirestoreService();

  bool _loading = false;
  bool _hadActiveService = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // FIRESTORE STATUS UPDATE (PRODUCTION-SAFE)
  // ═══════════════════════════════════════════════════════════════════════════
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
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Update timed out'),
      );

      if (!mounted) return;
      _showSnackBar('Status updated → $newStatus');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'Update failed: ${e.toString()}\nPlease try again',
        isError: true,
        showRetry: true,
        onRetry: () => _updateStatus(
          requestId: requestId,
          newStatus: newStatus,
          timestampField: timestampField,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPLETE SERVICE (WITH CONFIRMATION)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _markCompleted(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Complete Service',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Are you sure you want to mark this service as completed?\n\n'
          'This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
            ),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME-AWARE SNACKBAR HELPER
  // ═══════════════════════════════════════════════════════════════════════════
  void _showSnackBar(
    String message, {
    bool isError = false,
    bool showRetry = false,
    VoidCallback? onRetry,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
        action: showRetry && onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final mechanicId = _auth.currentUser?.uid;

    if (mechanicId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Service')),
        body: const Center(
          child: Text(
            'Mechanic not logged in',
            style: TextStyle(color: Colors.white70),
          ),
        ),
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
          // ── Loading ───────────────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── Error ─────────────────────────────────────────────────────────
          if (snapshot.hasError) {
            return Center(
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
                    'Error loading service',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final requests = snapshot.data ?? [];

          // ── No Active Services ────────────────────────────────────────────
          if (requests.isEmpty) {
            if (_hadActiveService) {
              // Service was deleted while screen was open
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Service request was removed',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active services',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          // ── Multiple Active Services (Edge Case) ──────────────────────────
          if (requests.length > 1) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Multiple Active Services Detected',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Found ${requests.length} active services. Only one service should be active at a time.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {/* TODO: Navigate to support */},
                      icon: const Icon(Icons.support_agent),
                      label: const Text('Contact Support'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Single Active Service (Normal Case) ───────────────────────────
          _hadActiveService = true;

          final r = requests.first;
          final requestId = r['requestId'] as String? ?? '';
          final status = r['status'] as String? ?? 'accepted';

          if (requestId.isEmpty) {
            return Center(
              child: Text(
                'Invalid request ID',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            );
          }

          // ── Button States ─────────────────────────────────────────────────
          final canStart = status == 'accepted';
          final canOngoing = status == 'in_progress_started';
          final canComplete = status == 'in_progress_ongoing';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ══════════════════════════════════════════════════════════════
                // STATUS CARD
                // ══════════════════════════════════════════════════════════════
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.build_circle,
                              color: status == 'completed'
                                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.3)
                                  : Theme.of(context).colorScheme.primary,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Service Status',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    status.toUpperCase().replaceAll('_', ' '),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_loading)
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ══════════════════════════════════════════════════════════════
                // ACTION BUTTONS
                // ══════════════════════════════════════════════════════════════
                
                // START SERVICE
                ElevatedButton.icon(
                  onPressed: (!_loading && canStart)
                      ? () => _updateStatus(
                            requestId: requestId,
                            newStatus: 'in_progress_started',
                            timestampField: 'startedAt',
                          )
                      : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Service'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.black,
                  ),
                ),

                const SizedBox(height: 12),

                // MARK ONGOING
                ElevatedButton.icon(
                  onPressed: (!_loading && canOngoing)
                      ? () => _updateStatus(
                            requestId: requestId,
                            newStatus: 'in_progress_ongoing',
                            timestampField: 'ongoingAt',
                          )
                      : null,
                  icon: const Icon(Icons.update),
                  label: const Text('Mark Ongoing'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),

                const SizedBox(height: 12),

                // MARK COMPLETE
                ElevatedButton.icon(
                  onPressed: (!_loading && canComplete)
                      ? () => _markCompleted(requestId)
                      : null,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark Complete'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                // ══════════════════════════════════════════════════════════════
                // INFO SECTION
                // ══════════════════════════════════════════════════════════════
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Flow',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),
                        _buildFlowStep('1', 'Start Service', canStart, context),
                        const SizedBox(height: 8),
                        _buildFlowStep('2', 'Mark Ongoing', canOngoing, context),
                        const SizedBox(height: 8),
                        _buildFlowStep('3', 'Mark Complete', canComplete, context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER: FLOW STEP INDICATOR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFlowStep(String number, String label, bool isActive, BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: isActive ? Colors.black : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}