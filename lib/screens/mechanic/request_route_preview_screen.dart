// lib/screens/mechanic/request_route_preview_screen.dart
// Mechanic-side request preview with map route, distance, ETA, and estimated earning.
// Visible only to mechanic; no live tracking; shop coordinates not exposed to user.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../services/request_firestore_service.dart';
import '../../utils/directions_service.dart';
// ============================================================
// ARGUMENTS
// ============================================================

class RequestRoutePreviewArgs {
  const RequestRoutePreviewArgs({
    required this.requestId,
    required this.userLat,
    required this.userLng,
    required this.locationAddress,
    required this.shopLat,
    required this.shopLng,
  });

  final String requestId;
  final double userLat;
  final double userLng;
  final String locationAddress;
  final double shopLat;
  final double shopLng;

  static RequestRoutePreviewArgs? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final requestId = map['requestId']?.toString();
    final userLat = (map['userLat'] as num?)?.toDouble();
    final userLng = (map['userLng'] as num?)?.toDouble();
    final locationAddress = map['locationAddress']?.toString() ?? '';
    final shopLat = (map['shopLat'] as num?)?.toDouble();
    final shopLng = (map['shopLng'] as num?)?.toDouble();
    if (requestId == null || requestId.isEmpty ||
        userLat == null || userLng == null ||
        shopLat == null || shopLng == null) {
      return null;
    }
    return RequestRoutePreviewArgs(
      requestId: requestId,
      userLat: userLat,
      userLng: userLng,
      locationAddress: locationAddress,
      shopLat: shopLat,
      shopLng: shopLng,
    );
  }
}

// ============================================================
// EARNING CONSTANTS (MVP)
// ============================================================

const double _baseFare = 150;
const double _perKmRate = 20;

// ============================================================
// SCREEN
// ============================================================

class RequestRoutePreviewScreen extends StatefulWidget {
  const RequestRoutePreviewScreen({
    super.key,
    required this.args,
    this.onAccepted,
  });

  final RequestRoutePreviewArgs args;

  /// Callback when mechanic accepts (e.g. switch to Active tab). Called before pop.
  final VoidCallback? onAccepted;

  @override
  State<RequestRoutePreviewScreen> createState() =>
      _RequestRoutePreviewScreenState();
}

class _RequestRoutePreviewScreenState extends State<RequestRoutePreviewScreen> {
  final RequestFirestoreService _requestService = RequestFirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  GoogleMapController? _mapController;
  bool _directionsLoading = true;
  String? _directionsError;
  DirectionsResult? _directions;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDirections();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadDirections() async {
    setState(() {
      _directionsLoading = true;
      _directionsError = null;
      _directions = null;
    });

    DirectionsResult? result;
    try {
      result = await fetchDirections(
        originLat: widget.args.shopLat,
        originLng: widget.args.shopLng,
        destLat: widget.args.userLat,
        destLng: widget.args.userLng,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _directionsLoading = false;
          _directionsError = 'Failed to load route. Please try again.';
        });
      }
      return;
    }

    if (!mounted) return;
    if (result == null) {
      setState(() {
        _directionsLoading = false;
        _directionsError = 'Could not get route. Check your connection.';
      });
      return;
    }

    setState(() {
      _directionsLoading = false;
      _directions = result;
      _directionsError = null;
    });

    _fitBoundsAfterDelay();
  }

  void _fitBoundsAfterDelay() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || _mapController == null || _directions == null) return;
      final points = _directions!.polylinePoints;
      if (points.isEmpty) return;
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;
      final shop = LatLng(widget.args.shopLat, widget.args.shopLng);
      final user = LatLng(widget.args.userLat, widget.args.userLng);
      for (final p in points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
      if (shop.latitude < minLat) minLat = shop.latitude;
      if (shop.latitude > maxLat) maxLat = shop.latitude;
      if (shop.longitude < minLng) minLng = shop.longitude;
      if (shop.longitude > maxLng) maxLng = shop.longitude;
      if (user.latitude < minLat) minLat = user.latitude;
      if (user.latitude > maxLat) maxLat = user.latitude;
      if (user.longitude < minLng) minLng = user.longitude;
      if (user.longitude > maxLng) maxLng = user.longitude;
      final padding = 0.02;
      final latPadding = (maxLat - minLat).clamp(padding, double.infinity);
      final lngPadding = (maxLng - minLng).clamp(padding, double.infinity);
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat - latPadding, minLng - lngPadding),
            northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
          ),
          48,
        ),
      );
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitBoundsAfterDelay();
  }

  double get _distanceKm => _directions?.distanceKm ?? 0;
  int get _etaMinutes => _directions?.durationMinutes ?? 0;
  int get _estimatedEarning =>
      (_baseFare + (_distanceKm * _perKmRate)).round();

  Future<void> _acceptRequest() async {
    final mechanicId = _auth.currentUser?.uid;
    if (mechanicId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to accept.')),
      );
      return;
    }

    setState(() => _actionLoading = true);
    try {
     await _requestService.acceptRequest(
  requestId: widget.args.requestId,
  mechanicId: mechanicId,
);

      if (!mounted) return;
      widget.onAccepted?.call();
      Navigator.of(context).pop('accepted');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request accepted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting request: $e')),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _rejectRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Request'),
        content: const Text(
          'Are you sure you want to reject this service request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _actionLoading = true);
    try {
      await _requestService.rejectRequest(widget.args.requestId);
      if (!mounted) return;
      Navigator.of(context).pop('rejected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting request: $e')),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final shop = LatLng(args.shopLat, args.shopLng);
    final user = LatLng(args.userLat, args.userLng);

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('shop'),
        position: shop,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your workshop'),
      ),
      Marker(
        markerId: const MarkerId('user'),
        position: user,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Customer location'),
      ),
    };

    Set<Polyline> polylines = {};
    if (_directions != null && _directions!.polylinePoints.isNotEmpty) {
      polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: _directions!.polylinePoints,
          color: Theme.of(context).colorScheme.primary,
          width: 4,
        ),
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Preview'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ---------- Map (top 60%) ----------
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      (args.shopLat + args.userLat) / 2,
                      (args.shopLng + args.userLng) / 2,
                    ),
                    zoom: 12,
                  ),
                  onMapCreated: _onMapCreated,
                  markers: markers,
                  polylines: polylines,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
                if (_directionsLoading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x44000000),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                if (_directionsError != null && !_directionsLoading)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _directionsError!,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            TextButton(
                              onPressed: _loadDirections,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ---------- Info panel ----------
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Address
                  const Text(
                    'Address',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    args.locationAddress.isEmpty
                        ? 'Location (${args.userLat.toStringAsFixed(4)}, ${args.userLng.toStringAsFixed(4)})'
                        : args.locationAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Distance & ETA
                  Row(
                    children: [
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.straighten,
                          label: 'Distance',
                          value: _directionsLoading
                              ? '—'
                              : '${_distanceKm.toStringAsFixed(1)} km',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.schedule,
                          label: 'ETA',
                          value: _directionsLoading
                              ? '—'
                              : '$_etaMinutes min',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Estimated earning
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Estimated earning: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          '₹$_estimatedEarning',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _actionLoading ? null : _rejectRequest,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Reject Request',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _actionLoading ? null : _acceptRequest,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _actionLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ) 
                              : const Text('Accept Request'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white70),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  }
