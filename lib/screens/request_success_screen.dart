// lib/screens/request_success_screen.dart

import 'package:flutter/material.dart';

class RequestSuccessScreen extends StatefulWidget {
  /// Expects args map: { 'vehicle': 'Car', 'summary': 'short text' }
  const RequestSuccessScreen({super.key});

  @override
  State<RequestSuccessScreen> createState() => _RequestSuccessScreenState();
}

class _RequestSuccessScreenState extends State<RequestSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    // Start animation
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = (args is Map<String, dynamic>) ? args : <String, dynamic>{};

    final vehicle = (map['vehicle'] ?? 'Vehicle') as String;
    final summary = (map['summary'] ?? '') as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Submitted'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SuccessCard(
              scaleAnimation: _scaleAnimation,
              scheme: scheme,
              vehicle: vehicle,
              summary: summary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable success card widget with Material 3 design
class SuccessCard extends StatelessWidget {
  final Animation<double> scaleAnimation;
  final ColorScheme scheme;
  final String vehicle;
  final String summary;

  const SuccessCard({
    super.key,
    required this.scaleAnimation,
    required this.scheme,
    required this.vehicle,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated success icon
            ScaleTransition(
              scale: scaleAnimation,
              child: Icon(
                Icons.check_circle_outline,
                size: 86,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              'Request Sent',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              'Your $vehicle service request has been submitted successfully. A nearby mechanic will contact you shortly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface.withOpacity(0.7),
              ),
            ),

            // Summary section (if provided)
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLowest,
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  summary,
                  style: TextStyle(
                    color: scheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // View My Requests button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.list),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.0),
                  child: Text('View My Requests'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/my_requests');
                },
              ),
            ),

            const SizedBox(height: 12),

            // Back to Home link
            TextButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (r) => false,
              ),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}