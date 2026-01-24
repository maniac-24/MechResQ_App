import 'package:flutter/material.dart';

class MechanicDetailScreen extends StatelessWidget {
  final Map<String, String> mechanic;

  const MechanicDetailScreen({super.key, required this.mechanic});

  @override
  Widget build(BuildContext context) {
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
              color: const Color(0xFF1B1B1B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
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
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 16, color: Colors.amber),
                              const SizedBox(width: 6),
                              Text(
                                "$rating • $distance km",
                                style: const TextStyle(color: Colors.white70),
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
            const Text(
              'Services',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              services.isNotEmpty ? services : "General vehicle repair services.",
              style: const TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 18),

            // ✅ CONTACT
            const Text(
              'Contact',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_android, color: Colors.white70),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      phone,
                      style: const TextStyle(color: Colors.white),
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
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Create Request'),

                    // ✅ FIXED: Navigate to CreateRequestScreen
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/create_request',
                        arguments: mechanic, // passing mechanic details ✅
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share feature coming soon ✅')),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ✅ NOTES
            const Text(
              'Notes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "• Please confirm service charges before repair.\n"
              "• Payment options may include Cash / UPI.\n"
              "• Always verify mechanic identity before proceeding.",
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  void _showCallConfirmation(BuildContext context, String phone) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Call Mechanic'),
        content: Text('Do you want to call $phone ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling $phone...')),
              );
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }
}
