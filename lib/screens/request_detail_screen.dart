// lib/screens/request_detail_screen.dart
import 'package:flutter/material.dart';
import '../services/request_service.dart';

class RequestDetailScreen extends StatelessWidget {
  /// Accepts the request data map either via constructor or via
  /// ModalRoute.of(context).settings.arguments.
  final Map<String, dynamic>? data;

  const RequestDetailScreen({super.key, this.data});

  Map<String, dynamic> _resolveData(BuildContext context) {
    final fromRoute = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return (data ?? fromRoute) ?? <String, dynamic>{};
  }

  Widget _buildMechanicCard(Map<String, dynamic> mech, BuildContext context) {
    final yellow = Theme.of(context).colorScheme.primary;
    final name = mech['name'] ?? 'N/A';
    final garage = mech['garageName'] ?? '';
    final exp = mech['experienceYears']?.toString() ?? '—';
    final types = (mech['vehicleTypes'] is List) ? (mech['vehicleTypes'] as List).join(', ') : (mech['vehicleTypes']?.toString() ?? '');
    final rating = mech['rating']?.toString() ?? '—';
    final distance = mech['distanceKm']?.toString() ?? '—';
    final phone = mech['phone'] ?? 'N/A';

    return Card(
      color: const Color(0xFF1B1B1B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: yellow,
                  child: Text(name.isNotEmpty ? name[0] : 'M', style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(garage, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(name, style: const TextStyle(color: Colors.white70)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              Chip(label: Text('Exp: $exp yrs')),
              Chip(label: Text('Types: $types')),
              Chip(label: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.star, size: 14, color: Colors.amber), SizedBox(width: 6), Text(rating)])),
              Chip(label: Text('$distance km')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.phone_android, color: Colors.white70),
              const SizedBox(width: 8),
              Text(phone, style: const TextStyle(color: Colors.white70)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Call $phone (simulated)')));
                },
                icon: const Icon(Icons.call, color: Colors.black),
                label: const Text('Call', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(backgroundColor: yellow),
              )
            ]),
            const SizedBox(height: 12),
            Text('Notes', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              mech['notes'] ?? 'No additional notes provided by mechanic.',
              style: const TextStyle(color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImages(List<dynamic> images) {
    if (images.isEmpty) {
      return Center(child: Text('No images attached', style: TextStyle(color: Colors.white70)));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: images.map<Widget>((img) {
        final name = img?.toString() ?? 'photo.jpg';
        return Container(
          width: 120,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Center(
            child: Text(name, textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> req = _resolveData(context);
    final mechanic = req['mechanic'] is Map<String, dynamic> ? Map<String, dynamic>.from(req['mechanic']) : <String, dynamic>{};
    final issue = req['issue'] ?? '';
    final images = req['images'] is List ? List.from(req['images']) : <dynamic>[];
    final status = (req['status'] ?? 'pending').toString();
    final createdAt = req['createdAt'] is DateTime ? req['createdAt'] as DateTime : (req['createdAt'] != null ? DateTime.tryParse(req['createdAt'].toString()) : null);

    final createdStr = createdAt != null ? '${createdAt.toLocal()}'.split('.').first : (req['createdAt']?.toString() ?? 'Unknown');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                // Header: status + created time
                Row(
                  children: [
                    Expanded(
                      child: Text('Request • ${status.toUpperCase()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    Text(createdStr, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 12),

                // Responsive two-column layout
                LayoutBuilder(builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 820;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: mechanic / service details (takes 40%)
                        Expanded(flex: 4, child: _buildMechanicCard(mechanic, context)),
                        const SizedBox(width: 12),

                        // Right: request details (takes 6)
                        Expanded(
                          flex: 6,
                          child: Card(
                            color: const Color(0xFF1B1B1B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Your Details', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  Text('Issue', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Text(issue, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                  const SizedBox(height: 12),
                                  Text('Attached Images', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  _buildImages(images),
                                  const SizedBox(height: 14),
                                  Text('Actions', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            // simulate cancel
                                            if (req['id'] != null) {
                                              RequestService.update(req['id'], {'status': 'cancelled'});
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request cancelled (simulated)')));
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request cancelled (simulated)')));
                                            }
                                            Navigator.pop(context);
                                          },
                                          icon: const Icon(Icons.cancel, color: Colors.black),
                                          label: const Text('Cancel Request', style: TextStyle(color: Colors.black)),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          // simulate reassign (just go back to mechanics list)
                                          Navigator.pushNamed(context, '/home', arguments: {'prefillIssue': issue});
                                        },
                                        icon: const Icon(Icons.repeat),
                                        label: const Text('Request Another'),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    // stacked layout for narrow screens
                    return Column(
                      children: [
                        _buildMechanicCard(mechanic, context),
                        const SizedBox(height: 12),
                        Card(
                          color: const Color(0xFF1B1B1B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Your Details', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                Text('Issue', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Text(issue, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                const SizedBox(height: 12),
                                Text('Attached Images', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                _buildImages(images),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          if (req['id'] != null) {
                                            RequestService.update(req['id'], {'status': 'cancelled'});
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request cancelled (simulated)')));
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request cancelled (simulated)')));
                                          }
                                          Navigator.pop(context);
                                        },
                                        icon: const Icon(Icons.cancel, color: Colors.black),
                                        label: const Text('Cancel Request', style: TextStyle(color: Colors.black)),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/home', arguments: {'prefillIssue': issue});
                                      },
                                      icon: const Icon(Icons.repeat),
                                      label: const Text('Request Another'),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                }),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
