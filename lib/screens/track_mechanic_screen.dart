// lib/screens/track_mechanic_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../utils/snackbar_helper.dart';
import '../widgets/request_status_chip.dart'; // RequestStatus enum
import 'live_tracking_map_screen.dart';
import 'user_mechanic_detail_screen.dart';
import 'chat_mechanic_screen.dart';

/// ============================================================================
/// TRACK MECHANIC SCREEN — PRODUCTION REAL-TIME TRACKING
/// ============================================================================
class TrackMechanicScreen extends StatefulWidget {
  final String requestId;

  const TrackMechanicScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<TrackMechanicScreen> createState() => _TrackMechanicScreenState();
}

class _TrackMechanicScreenState extends State<TrackMechanicScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  GoogleMapController? _mapController;

  // Real-time polyline & ETA
  Set<Polyline> _polylines = {};
  String? _etaText;
  double? _distanceKm;

  // Marker animation
  LatLng? _lastMechanicPos;

  // Google API key (store in environment variables in production)
  static const String _googleApiKey = "YOUR_GOOGLE_DIRECTIONS_API_KEY";

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GOOGLE DIRECTIONS API — fetch route + ETA
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _fetchRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&key=$_googleApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) return;

      final data = json.decode(response.body);
      if (data['status'] != 'OK') return;

      final route = data['routes'][0];
      final leg = route['legs'][0];

      // Decode polyline
      final polylinePoints =
          _decodePolyline(route['overview_polyline']['points']);

      if (!mounted) return;

      final scheme = Theme.of(context).colorScheme;

      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: polylinePoints,
            color: scheme.primary,
            width: 4,
          ),
        };
        _etaText = leg['duration']['text'];
        _distanceKm = (leg['distance']['value'] as int) / 1000;
      });
    } catch (e) {
      debugPrint('Directions API error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Polyline decoder
  // ──────────────────────────────────────────────────────────────────────────
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Smooth marker animation
  // ──────────────────────────────────────────────────────────────────────────
  void _animateMechanicMarker(LatLng newPos) {
    if (_lastMechanicPos == null) {
      setState(() => _lastMechanicPos = newPos);
      return;
    }

    const steps = 10;
    const duration = Duration(milliseconds: 100);
    int step = 0;

    Timer.periodic(duration, (timer) {
      if (step >= steps) {
        timer.cancel();
        return;
      }

      if (!mounted) {
        timer.cancel();
        return;
      }

      final lat = _lastMechanicPos!.latitude +
          (newPos.latitude - _lastMechanicPos!.latitude) * (step / steps);
      final lng = _lastMechanicPos!.longitude +
          (newPos.longitude - _lastMechanicPos!.longitude) * (step / steps);

      setState(() => _lastMechanicPos = LatLng(lat, lng));
      step++;
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Camera bounds to fit both markers
  // ──────────────────────────────────────────────────────────────────────────
  void _fitBounds(LatLng userPos, LatLng mechanicPos) {
    if (_mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        userPos.latitude < mechanicPos.latitude
            ? userPos.latitude
            : mechanicPos.latitude,
        userPos.longitude < mechanicPos.longitude
            ? userPos.longitude
            : mechanicPos.longitude,
      ),
      northeast: LatLng(
        userPos.latitude > mechanicPos.latitude
            ? userPos.latitude
            : mechanicPos.latitude,
        userPos.longitude > mechanicPos.longitude
            ? userPos.longitude
            : mechanicPos.longitude,
      ),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UI helpers
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _callMechanic(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Cannot launch phone dialer');
    }
  }

  /// Map RequestStatus (business layer) to TrackingStatus (UI layer)
  /// 
  /// Design notes:
  /// - RequestStatus.onTheWay maps to TrackingStatus.onTheWay
  /// - TrackingStatus.arrived exists but RequestStatus does not have "arrived"
  /// - If Firestore contains "arrived", parseRequestStatus() defaults to pending
  /// - All other states default to TrackingStatus.onTheWay for safety
  TrackingStatus _mapToTrackingStatus(RequestStatus status) {
    switch (status) {
      case RequestStatus.onTheWay:
        return TrackingStatus.onTheWay;
        
      case RequestStatus.completed:
        // Completed could mean arrived - map to arrived for UI
        return TrackingStatus.arrived;
        
      case RequestStatus.accepted:
      case RequestStatus.pending:
      case RequestStatus.cancelled:
      default:
        return TrackingStatus.onTheWay;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Mechanic"),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('requests').doc(widget.requestId).snapshots(),
        builder: (context, requestSnap) {
          // Loading
          if (requestSnap.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: scheme.primary),
            );
          }

          // Error
          if (requestSnap.hasError ||
              !requestSnap.hasData ||
              !requestSnap.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: scheme.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Request not found',
                    style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
                  ),
                ],
              ),
            );
          }

          final reqData = requestSnap.data!.data() as Map<String, dynamic>;
          final status = parseRequestStatus(reqData['status'] as String?);
          final mechanicId = reqData['mechanicId'] as String?;
          final userLat = (reqData['userLat'] as num?)?.toDouble();
          final userLng = (reqData['userLng'] as num?)?.toDouble();
          final vehicleType = reqData['vehicleType'] as String? ?? 'Vehicle';
          final issue =
              reqData['issueDescription'] ?? reqData['issue'] ?? 'Issue not specified';
          final createdAt = (reqData['createdAt'] as Timestamp?)?.toDate();

          // No mechanic assigned yet
          if (mechanicId == null || mechanicId.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty, color: scheme.tertiary, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Waiting for mechanic assignment…',
                    style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
                  ),
                ],
              ),
            );
          }

          // Invalid user location
          if (userLat == null || userLng == null) {
            return Center(
              child: Text(
                'User location not available',
                style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
              ),
            );
          }

          final userPos = LatLng(userLat, userLng);

          // Nested: mechanic data stream
          return StreamBuilder<DocumentSnapshot>(
            stream: _db.collection('mechanics').doc(mechanicId).snapshots(),
            builder: (context, mechanicSnap) {
              if (mechanicSnap.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: scheme.primary),
                );
              }

              if (mechanicSnap.hasError ||
                  !mechanicSnap.hasData ||
                  !mechanicSnap.data!.exists) {
                return Center(
                  child: Text(
                    'Mechanic data not found',
                    style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
                  ),
                );
              }

              final mechData = mechanicSnap.data!.data() as Map<String, dynamic>;
              final mechanicName = mechData['name'] as String? ?? 'Mechanic';
              final phone = mechData['phone'] as String? ?? '';
              final liveLat = (mechData['liveLat'] as num?)?.toDouble();
              final liveLng = (mechData['liveLng'] as num?)?.toDouble();
              final lastUpdated =
                  (mechData['lastUpdated'] as Timestamp?)?.toDate();
              final rating = (mechData['rating'] as num?)?.toDouble() ?? 4.5;
              final totalReviews = mechData['totalReviews'] as int? ?? 0;

              if (liveLat == null || liveLng == null) {
                return Center(
                  child: Text(
                    'Mechanic location not available',
                    style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
                  ),
                );
              }

              final mechanicPos = LatLng(liveLat, liveLng);

              // Offline detection (2 min threshold)
              final now = DateTime.now();
              final isOffline = lastUpdated == null ||
                  now.difference(lastUpdated).inMinutes > 2;

              // Fetch route once mechanic position changes
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_lastMechanicPos == null ||
                    _lastMechanicPos!.latitude != mechanicPos.latitude ||
                    _lastMechanicPos!.longitude != mechanicPos.longitude) {
                  _animateMechanicMarker(mechanicPos);
                  _fetchRoute(origin: mechanicPos, destination: userPos);
                }
              });

              // UI LAYOUT
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // STATUS TIMELINE
                    _StatusTimeline(status: status, scheme: scheme),

                    // OFFLINE BANNER
                    if (isOffline)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        color: scheme.errorContainer,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.signal_wifi_off,
                              color: scheme.onErrorContainer,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Mechanic Offline',
                              style: TextStyle(
                                color: scheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // GOOGLE MAP
                    SizedBox(
                      height: 210,
                      child: GoogleMap(
                        onMapCreated: (controller) {
                          _mapController = controller;
                          _fitBounds(userPos, _lastMechanicPos ?? mechanicPos);
                        },
                        initialCameraPosition: CameraPosition(
                          target: mechanicPos,
                          zoom: 14,
                        ),
                        markers: {
                          // User marker
                          Marker(
                            markerId: const MarkerId('user'),
                            position: userPos,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueBlue),
                            infoWindow: const InfoWindow(title: 'You'),
                          ),
                          // Mechanic marker (animated position)
                          Marker(
                            markerId: const MarkerId('mechanic'),
                            position: _lastMechanicPos ?? mechanicPos,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueYellow),
                            infoWindow: InfoWindow(title: mechanicName),
                          ),
                        },
                        polylines: _polylines,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      ),
                    ),

                    // ETA PILL
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_etaText != null && !isOffline)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: scheme.primary),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_alarm,
                                    size: 17,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ETA $_etaText',
                                    style: TextStyle(
                                      color: scheme.onPrimaryContainer,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_distanceKm != null)
                            Text(
                              '${_distanceKm!.toStringAsFixed(1)} km',
                              style: TextStyle(
                                color: scheme.onSurface.withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: scheme.primary,
                              foregroundColor: scheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LiveTrackingMapScreen(
                                  mechanicName: mechanicName,
                                  distanceKm: _distanceKm ?? 0,
                                  etaMinutes: _parseEtaMinutes(_etaText),
                                  status: _mapToTrackingStatus(status),
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.fullscreen, size: 17),
                            label: const Text(
                              'Full Map',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // MECHANIC CARD
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _MechanicCard(
                        name: mechanicName,
                        rating: rating,
                        totalReviews: totalReviews,
                        phone: phone,
                        isOnline: !isOffline,
                        scheme: scheme,
                        onTapProfile: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  UserMechanicDetailScreen(mechanicId: mechanicId),
                            ),
                          );
                        },
                        onCall: () => _callMechanic(phone),
                      ),
                    ),

                    // REQUEST SUMMARY
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _SummaryCard(
                        requestId: widget.requestId,
                        vehicleType: vehicleType,
                        issue: issue,
                        createdAt: createdAt,
                        scheme: scheme,
                      ),
                    ),

                    // ACTION BUTTONS
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _Actions(
                        canCancel: status == RequestStatus.accepted,
                        phone: phone,
                        mechanicId: mechanicId,
                        requestId: widget.requestId,
                        scheme: scheme,
                        onCall: () => _callMechanic(phone),
                        onChat: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatMechanicScreen(mechanicName: mechanicName),
                          ),
                        ),
                        onCancel: () => _showCancelDialog(),
                        onSOS: () {
                          SnackBarHelper.showWarning(
                            context,
                            '🚨 SOS call initiated!',
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  int _parseEtaMinutes(String? etaText) {
    if (etaText == null) return 0;
    final match = RegExp(r'(\d+)\s*min').firstMatch(etaText);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }

  // ──────────────────────────────────────────────────────────────────────────
  void _showCancelDialog() {
    final scheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: scheme.surface,
        title: Text(
          'Cancel Request',
          style: TextStyle(color: scheme.onSurface),
        ),
        content: Text(
          'Are you sure? You can only cancel before the mechanic starts travelling.',
          style: TextStyle(color: scheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _db.collection('requests').doc(widget.requestId).update({
                  'status': 'cancelled',
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                if (!mounted) return;
                SnackBarHelper.showSuccess(context, 'Request cancelled');
              } catch (e) {
                if (!mounted) return;
                SnackBarHelper.showError(context, 'Failed to cancel: $e');
              }
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// STATUS TIMELINE
// ══════════════════════════════════════════════════════════════════════════
class _StatusTimeline extends StatelessWidget {
  final RequestStatus status;
  final ColorScheme scheme;
  
  const _StatusTimeline({
    required this.status,
    required this.scheme,
  });

  static const _steps = [
    RequestStatus.accepted,
    RequestStatus.onTheWay,
    RequestStatus.completed,
  ];
  
  static const _labels = {
    RequestStatus.accepted: 'Accepted',
    RequestStatus.onTheWay: 'On the Way',
    RequestStatus.completed: 'Completed',
  };
  
  static const _icons = {
    RequestStatus.accepted: Icons.check_circle_outline,
    RequestStatus.onTheWay: Icons.directions_bike,
    RequestStatus.completed: Icons.star,
  };

  @override
  Widget build(BuildContext context) {
    // Handle arrived as onTheWay for timeline display
    final displayStatus = status == RequestStatus.pending
        ? RequestStatus.accepted
        : status;
    
    final cur = _steps.indexOf(displayStatus).clamp(0, _steps.length - 1);

    return Container(
      color: scheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: List.generate(_steps.length, (i) {
          final done = i <= cur;
          final active = i == cur;

          return Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: active ? 44 : 34,
                      height: active ? 44 : 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? scheme.primaryContainer
                            : scheme.surfaceContainerHigh,
                      ),
                      child: Icon(
                        _icons[_steps[i]]!,
                        size: active ? 22 : 17,
                        color: done
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _labels[_steps[i]]!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        color: done
                            ? scheme.onSurface
                            : scheme.onSurface.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                if (i < _steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: i < cur
                            ? scheme.primary
                            : scheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// MECHANIC CARD
// ══════════════════════════════════════════════════════════════════════════
class _MechanicCard extends StatelessWidget {
  final String name;
  final double rating;
  final int totalReviews;
  final String phone;
  final bool isOnline;
  final ColorScheme scheme;
  final VoidCallback onTapProfile;
  final VoidCallback onCall;

  const _MechanicCard({
    required this.name,
    required this.rating,
    required this.totalReviews,
    required this.phone,
    required this.isOnline,
    required this.scheme,
    required this.onTapProfile,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            GestureDetector(
              onTap: onTapProfile,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      name.isNotEmpty ? name[0] : 'M',
                      style: TextStyle(
                        fontSize: 22,
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isOnline ? scheme.tertiary : scheme.outlineVariant,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: scheme.surfaceContainerHighest,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onTapProfile,
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 15, color: scheme.tertiary),
                      const SizedBox(width: 3),
                      Text(
                        '$rating ($totalReviews)',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onCall,
              icon: Icon(Icons.phone, color: scheme.primary, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// REQUEST SUMMARY
// ══════════════════════════════════════════════════════════════════════════
class _SummaryCard extends StatelessWidget {
  final String requestId;
  final String vehicleType;
  final String issue;
  final DateTime? createdAt;
  final ColorScheme scheme;

  const _SummaryCard({
    required this.requestId,
    required this.vehicleType,
    required this.issue,
    required this.createdAt,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = createdAt != null ? _fmt(createdAt!) : 'Unknown';

    return Card(
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment_outlined, color: scheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Request Summary',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _field('Request ID', requestId),
            _field('Vehicle', vehicleType),
            _field('Requested At', timeStr),
            _fieldMulti('Issue', issue),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day}/${dt.month}/${dt.year}  $h:$m $ap';
  }

  Widget _field(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _fieldMulti(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════
// ACTION BUTTONS
// ══════════════════════════════════════════════════════════════════════════
class _Actions extends StatelessWidget {
  final bool canCancel;
  final String phone;
  final String mechanicId;
  final String requestId;
  final ColorScheme scheme;
  final VoidCallback onCall, onChat, onCancel, onSOS;

  const _Actions({
    required this.canCancel,
    required this.phone,
    required this.mechanicId,
    required this.requestId,
    required this.scheme,
    required this.onCall,
    required this.onChat,
    required this.onCancel,
    required this.onSOS,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _btn(
                context,
                Icons.phone,
                'Call',
                scheme.primaryContainer,
                scheme.onPrimaryContainer,
                onCall,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _btn(
                context,
                Icons.chat_bubble_outline,
                'Chat',
                scheme.secondaryContainer,
                scheme.onSecondaryContainer,
                onChat,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (canCancel) ...[
              Expanded(
                child: _btn(
                  context,
                  Icons.cancel_outlined,
                  'Cancel',
                  scheme.surfaceContainerHigh,
                  scheme.onSurface,
                  onCancel,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: _btn(
                context,
                Icons.emergency,
                'SOS',
                scheme.errorContainer,
                scheme.onErrorContainer,
                onSOS,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _btn(
    BuildContext ctx,
    IconData icon,
    String label,
    Color bgColor,
    Color fgColor,
    VoidCallback onTap,
  ) =>
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(double.infinity, 0),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}