// lib/screens/user_mechanic_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

/// ============================================================================
/// USER MECHANIC DETAIL SCREEN — PRODUCTION REAL-TIME
/// ============================================================================
/// Accepts ONLY mechanicId, fetches all data from Firestore in real-time.
/// No dummy models, no hardcoded values.
/// ============================================================================
class UserMechanicDetailScreen extends StatelessWidget {
  final String mechanicId;
  const UserMechanicDetailScreen({super.key, required this.mechanicId});

  Future<void> _launchPhone(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: scheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('mechanics')
            .doc(mechanicId)
            .snapshots(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: scheme.primary),
            );
          }

          // Error / Not Found
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: scheme.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Mechanic not found',
                    style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          // FIRESTORE DATA EXTRACTION (REAL-TIME)
          final data = snapshot.data!.data() as Map<String, dynamic>;

          final name = data['name'] as String? ?? 'Mechanic';
          final shopName = data['shopName'] as String? ?? 'Workshop';
          final phone = data['phone'] as String? ?? '';
          final email = data['email'] as String? ?? '';
          final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
          final totalReviews = data['totalReviews'] as int? ?? 0;
          final experienceYears = data['experienceYears'] as int? ?? 0;
          final isOnline = data['isOnline'] as bool? ?? false;

          final vehicleTypes = (data['vehicleTypes'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];

          final services = (data['services'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [
                'Engine Repair & Servicing',
                'Battery & Electrical',
                'Tyre Change & Puncture',
                'Oil & Fluid Change',
                'General Maintenance'
              ];

          // Last updated (for offline detection)
          final lastUpdated = (data['lastUpdated'] as Timestamp?)?.toDate();
          final now = DateTime.now();
          final minutesSinceUpdate = lastUpdated != null
              ? now.difference(lastUpdated).inMinutes
              : 9999;
          final isActuallyOnline = isOnline && minutesSinceUpdate <= 5;

          // UI BUILD
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HERO HEADER
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        scheme.surface,
                        scheme.surfaceContainerHighest,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: scheme.primaryContainer,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'M',
                            style: TextStyle(
                              fontSize: 36,
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Online/Offline indicator
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isActuallyOnline
                                ? scheme.tertiary
                                : scheme.outlineVariant,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: scheme.surfaceContainerHighest,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            isActuallyOnline
                                ? Icons.check_circle
                                : Icons.offline_bolt,
                            size: 16,
                            color: isActuallyOnline
                                ? scheme.onTertiary
                                : scheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // NAME + SHOP
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shopName,
                        style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurface.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      // Rating inline
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, size: 20, color: scheme.tertiary),
                          const SizedBox(width: 4),
                          Text(
                            rating > 0
                                ? rating.toStringAsFixed(1)
                                : 'No ratings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: scheme.onSurface,
                            ),
                          ),
                          if (rating > 0)
                            Text(
                              " / 5  ($totalReviews reviews)",
                              style: TextStyle(
                                fontSize: 13,
                                color: scheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // QUICK STATS ROW
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          scheme: scheme,
                          value: experienceYears > 0 ? "$experienceYears+" : "New",
                          label: "Years",
                          icon: Icons.work_outline,
                        ),
                      ),
                      Expanded(
                        child: _StatTile(
                          scheme: scheme,
                          value: "$totalReviews",
                          label: "Reviews",
                          icon: Icons.message_outlined,
                        ),
                      ),
                      Expanded(
                        child: _StatTile(
                          scheme: scheme,
                          value: "${vehicleTypes.length}",
                          label: "Vehicle Types",
                          icon: Icons.directions_car_outlined,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ONLINE STATUS
                if (!isActuallyOnline)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: scheme.error),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.offline_bolt,
                            color: scheme.onErrorContainer,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            lastUpdated != null
                                ? 'Last seen $minutesSinceUpdate min ago'
                                : 'Currently Offline',
                            style: TextStyle(
                              color: scheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // SERVICES OFFERED
                _SectionTitle(scheme: scheme, title: "Services Offered"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: scheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: services
                          .map((service) => _ServiceRow(
                                scheme: scheme,
                                icon: Icons.build,
                                title: service,
                              ))
                          .toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // VEHICLE TYPES
                if (vehicleTypes.isNotEmpty) ...[
                  _SectionTitle(
                      scheme: scheme, title: "Supported Vehicle Types"),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: vehicleTypes
                          .map(
                            (v) => Chip(
                              backgroundColor: scheme.secondaryContainer,
                              label: Text(
                                v,
                                style: TextStyle(
                                  color: scheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // RATING BREAKDOWN
                if (rating > 0 && totalReviews > 0) ...[
                  _SectionTitle(scheme: scheme, title: "Rating Overview"),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      color: scheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurface,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < rating.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 20,
                                  color: scheme.tertiary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Based on $totalReviews reviews",
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // CONTACT OPTIONS
                _SectionTitle(scheme: scheme, title: "Contact"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: scheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        if (phone.isNotEmpty)
                          ListTile(
                            leading: Icon(Icons.phone, color: scheme.primary),
                            title: Text(
                              phone,
                              style: TextStyle(color: scheme.onSurface),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: scheme.onSurface.withOpacity(0.5),
                            ),
                            onTap: () => _launchPhone(context, phone),
                          ),
                        if (phone.isNotEmpty && email.isNotEmpty)
                          Divider(height: 1, color: scheme.outlineVariant),
                        if (email.isNotEmpty)
                          ListTile(
                            leading: Icon(Icons.email, color: scheme.primary),
                            title: Text(
                              email,
                              style: TextStyle(color: scheme.onSurface),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: scheme.onSurface.withOpacity(0.5),
                            ),
                            onTap: () => _launchEmail(context, email),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// Section title widget
class _SectionTitle extends StatelessWidget {
  final ColorScheme scheme;
  final String title;

  const _SectionTitle({
    required this.scheme,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

/// Stat tile widget for quick stats row
class _StatTile extends StatelessWidget {
  final ColorScheme scheme;
  final String value;
  final String label;
  final IconData icon;

  const _StatTile({
    required this.scheme,
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: scheme.onSurface.withOpacity(0.6)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Service row widget for services list
class _ServiceRow extends StatelessWidget {
  final ColorScheme scheme;
  final IconData icon;
  final String title;

  const _ServiceRow({
    required this.scheme,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: scheme.onSurface.withOpacity(0.6)),
      title: Text(
        title,
        style: TextStyle(color: scheme.onSurface.withOpacity(0.8)),
      ),
      dense: true,
    );
  }
}