import 'package:flutter/material.dart';

import '../utils/snackbar_helper.dart';

class MechanicDetailScreen extends StatelessWidget {
  final Map<String, String> mechanic;

  const MechanicDetailScreen({super.key, required this.mechanic});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    final name = (mechanic['name'] ?? 'Mechanic').trim();
    final shop = (mechanic['shopName'] ?? 'Garage / Workshop').trim();

    final services = (mechanic['serviceTypes']?.trim().isNotEmpty ?? false)
        ? mechanic['serviceTypes']!.trim()
        : (mechanic['vehicleTypes'] ?? 'General Repair').trim();

    final phone = (mechanic['phone'] ?? 'N/A').trim();
    final rating = (mechanic['rating'] ?? '4.5').trim();
    final distance = (mechanic['distanceKm'] ?? '0.0').trim();

    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            tooltip: 'Call',
            icon: const Icon(Icons.call),
            onPressed: phone == 'N/A'
                ? null
                : () => _showCallConfirmation(context, phone),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ HEADER CARD
            Card(
              color: scheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: scheme.primary,
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 15,
                              color: scheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 16,
                                color: scheme.tertiary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "$rating • $distance km",
                                style: TextStyle(
                                  color: scheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ✅ SERVICES
            Text(
              'Services',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              services.isNotEmpty
                  ? services
                  : "General vehicle repair services.",
              style: TextStyle(
                color: scheme.onSurface.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 18),

            // ✅ CONTACT
            Text(
              'Contact',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.phone_android,
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      phone,
                      style: TextStyle(color: scheme.onSurface),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: phone == "N/A"
                        ? null
                        : () => _showCallConfirmation(context, phone),
                    icon: const Icon(Icons.call),
                    label: const Text("Call"),
                  )
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ✅ ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                    ),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Create Request'),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/create_request',
                        arguments: mechanic,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  onPressed: () {
                    SnackBarHelper.showInfo(
                      context,
                      'Share feature coming soon ✅',
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ✅ NOTES
            Text(
              'Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "• Please confirm service charges before repair.\n"
              "• Payment options may include Cash / UPI.\n"
              "• Always verify mechanic identity before proceeding.",
              style: TextStyle(
                color: scheme.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCallConfirmation(BuildContext context, String phone) {
    final scheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: scheme.surface,
        title: Text(
          'Call Mechanic',
          style: TextStyle(color: scheme.onSurface),
        ),
        content: Text(
          'Do you want to call $phone ?',
          style: TextStyle(color: scheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
            ),
            onPressed: () {
              Navigator.pop(context);
              SnackBarHelper.showInfo(
                context,
                'Calling $phone...',
              );
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }
}