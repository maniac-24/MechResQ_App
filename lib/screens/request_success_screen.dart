// lib/screens/request_success_screen.dart
import 'package:flutter/material.dart';

class RequestSuccessScreen extends StatelessWidget {
  /// Expects args map: { 'vehicle': 'Car', 'summary': 'short text' }
  const RequestSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = (args is Map<String, dynamic>) ? args : <String, dynamic>{};

    final vehicle = (map['vehicle'] ?? 'Vehicle') as String;
    final summary = (map['summary'] ?? '') as String;

    final theme = Theme.of(context);
    final yellow = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Submitted'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 86, color: yellow),
                  const SizedBox(height: 18),

                  Text(
                    'Request Sent',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Your $vehicle service request has been submitted successfully. A nearby mechanic will contact you shortly.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),

                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(summary),
                    ),
                  ],

                  const SizedBox(height: 28),

                  /// 🔥 VIEW MY REQUESTS BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.list),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.0),
                        child: Text('View My Requests'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: yellow,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/my_requests');
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/home', (r) => false),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
