// lib/widgets/mechanic_card.dart
import 'package:flutter/material.dart';

class MechanicCard extends StatelessWidget {
  final Map<String, String> mechanic;
  final VoidCallback? onRequest;
  final VoidCallback? onTap;

  const MechanicCard({
    super.key,
    required this.mechanic,
    this.onRequest,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final yellow = Theme.of(context).colorScheme.primary;

    final name = mechanic['name'] ?? 'Mechanic';
    final shop = mechanic['shopName'] ?? '';
    final types = mechanic['vehicleTypes'] ?? '';
    final rating = mechanic['rating'] ?? '4.5';
    final distance = mechanic['distanceKm'] ?? '1.0';

    return Card(
      color: const Color(0xFF1B1B1B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: yellow,
                child: Text(
                  name.isNotEmpty ? name[0] : 'M',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              /// Info Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Name
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    /// Shop Name
                    Text(
                      shop,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// Service Types
                    Row(
                      children: [
                        const Icon(
                          Icons.build,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            types,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              /// Rating + Request Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  /// Rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "$rating · $distance km",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// Request Button (Yellow Filled - matches FAB theme)
                  ElevatedButton(
                    onPressed: onRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow, // YELLOW BACKGROUND (matches FAB)
                      foregroundColor: Colors.black, // BLACK TEXT
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Request",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
