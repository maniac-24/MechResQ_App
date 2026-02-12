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
/// DARK MODE MAP STYLE (Optional Enhancement)
/// ------------------------------------------------------
const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#242f3e"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#242f3e"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#746855"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#263c3f"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#6b9a76"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#38414e"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#212a37"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9ca5b3"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#746855"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#1f2835"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#f3d19c"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#2f3948"}]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d59563"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#17263c"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#515c6d"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#17263c"}]
  }
]
''';

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
    final scheme = Theme.of(context).colorScheme;

    final allow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        backgroundColor: scheme.surface,
        title: Text(
          kTitle,
          style: TextStyle(color: scheme.onSurface),
        ),
        content: Text(
          '$kPrivacyText\n\nAllow location to auto-center your workshop?',
          style: TextStyle(color: scheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
            ),
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
  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;

    // Apply dark mode map style if theme is dark
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      try {
        await controller.setMapStyle(_darkMapStyle);
      } catch (e) {
        // Map styling is optional, continue if it fails
        debugPrint('Failed to set map style: $e');
      }
    }

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
    final scheme = Theme.of(context).colorScheme;

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

          // Loading overlay
          if (!_mapReady)
            Center(
              child: Card(
                color: scheme.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: scheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loading map…',
                        style: TextStyle(color: scheme.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Hint banner
          if (_showHint)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Material(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '$kPrivacyText\n\nTap or drag the pin to set location.',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Error banner
          if (_error != null)
            Positioned(
              top: 110,
              left: 16,
              right: 16,
              child: Material(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ),

          // Use Current Location button
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: _permissionGranted && !_busy && _mapReady
                  ? _moveToCurrentLocation
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.secondaryContainer,
                foregroundColor: scheme.onSecondaryContainer,
              ),
              icon: const Icon(Icons.my_location),
              label: const Text('Use Current Location'),
            ),
          ),

          // Save button
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _mapReady && !_busy ? _saveLocation : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _busy
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
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