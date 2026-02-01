import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

import '../utils/location_permission_utils.dart';

/// ------------------------------------------------------
/// RESULT MODEL
/// ------------------------------------------------------
class ShopLocationResult {
  const ShopLocationResult({
    required this.latitude,
    required this.longitude,
    this.shopAddress,
  });

  final double latitude;
  final double longitude;
  final String? shopAddress;
}

/// ------------------------------------------------------
/// CONSTANTS
/// ------------------------------------------------------
const String kTitle = 'Set Workshop Location';
const String kPrivacyText =
    'This helps users find nearby mechanics.\nYour shop location is not publicly visible.';

const double kDefaultLat = 20.5937;
const double kDefaultLng = 78.9629;

/// ------------------------------------------------------
/// SCREEN
/// ------------------------------------------------------
class ShopLocationPickerScreen extends StatefulWidget {
  ShopLocationPickerScreen({super.key});

  @override
  State<ShopLocationPickerScreen> createState() =>
      _ShopLocationPickerScreenState();
}

class _ShopLocationPickerScreenState extends State<ShopLocationPickerScreen> {
  GoogleMapController? _mapController;

  LatLng _marker = const LatLng(kDefaultLat, kDefaultLng);

  bool _mapReady = false;
  bool _busy = false;
  bool _permissionGranted = false;
  bool _showHint = true;

  String? _error;

  @override
  void initState() {
    super.initState();
    _initPermissionAndLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// ------------------------------------------------------
  /// PERMISSION + INITIAL LOCATION
  /// ------------------------------------------------------
  Future<void> _initPermissionAndLocation() async {
    final allow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text(kTitle),
        content: const Text(
          '$kPrivacyText\n\nAllow location to auto-center your workshop?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (allow != true) {
      setState(() {
        _permissionGranted = false;
        _error =
            'Location permission denied. Drag the map to set your workshop.';
      });
      return;
    }

    final result = await requestLocationPermission();
    if (!mounted) return;

    if (result == LocationPermissionResult.granted) {
      _permissionGranted = true;
      await _moveToCurrentLocation();
    } else {
      setState(() {
        _permissionGranted = false;
        _error =
            'Unable to access location. Drag the map to choose your workshop.';
      });
    }
  }

  Future<void> _moveToCurrentLocation() async {
    setState(() => _busy = true);

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      if (!mounted) return;

      _marker = LatLng(pos.latitude, pos.longitude);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_marker, 16),
      );
    } catch (_) {
      _error = 'Could not fetch current location.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// ------------------------------------------------------
  /// MAP EVENTS
  /// ------------------------------------------------------
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _mapReady = true);
    });
  }

  void _updateMarker(LatLng pos) {
    setState(() {
      _marker = pos;
      _showHint = false;
      _error = null;
    });
  }

  /// ------------------------------------------------------
  /// SAVE LOCATION
  /// ------------------------------------------------------
  Future<void> _saveLocation() async {
    setState(() => _busy = true);

    String? address;

    try {
      final placemarks = await placemarkFromCoordinates(
        _marker.latitude,
        _marker.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        address = [
          p.name,
          p.street,
          p.locality,
          p.administrativeArea,
          p.country,
        ].where((e) => e != null && e!.isNotEmpty).join(', ');
      }
    } catch (_) {}

    if (!mounted) return;

    Navigator.pop(
      context,
      ShopLocationResult(
        latitude: _marker.latitude,
        longitude: _marker.longitude,
        shopAddress: address,
      ),
    );
  }

  /// ------------------------------------------------------
  /// UI
  /// ------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(kTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _marker,
              zoom: 14,
            ),
            onMapCreated: _onMapCreated,
            myLocationEnabled: _permissionGranted,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId('shop'),
                position: _marker,
                draggable: true,
                onDragEnd: _updateMarker,
              ),
            },
            onTap: _updateMarker,
          ),

          if (!_mapReady)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Loading map…'),
                    ],
                  ),
                ),
              ),
            ),

          if (_showHint)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '$kPrivacyText\n\nTap or drag the pin to set location.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            ),

          if (_error != null)
            Positioned(
              top: 110,
              left: 16,
              right: 16,
              child: Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed:
                  _permissionGranted && !_busy && _mapReady
                      ? _moveToCurrentLocation
                      : null,
              icon: const Icon(Icons.my_location),
              label: const Text('Use Current Location'),
            ),
          ),

          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _mapReady && !_busy ? _saveLocation : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Shop Location'),
            ),
          ),
        ],
      ),
    );
  }
}
