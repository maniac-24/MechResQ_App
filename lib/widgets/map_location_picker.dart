// lib/widgets/map_location_picker.dart
// Reusable full-screen map with draggable marker for location selection.

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Result returned when user confirms location.
class MapLocationResult {
  const MapLocationResult({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  final double latitude;
  final double longitude;
  final String? address;
}

/// Full-screen map with a draggable marker. User can adjust position and confirm.
class MapLocationPicker extends StatefulWidget {
  const MapLocationPicker({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.onConfirm,
    this.optionalAddress,
  });

  final double initialLatitude;
  final double initialLongitude;
  final String? optionalAddress;
  final void Function(MapLocationResult result) onConfirm;

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  late LatLng _markerPosition;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _markerPosition = LatLng(widget.initialLatitude, widget.initialLongitude);
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() => _mapReady = true);
  }

  void _onConfirm() {
    widget.onConfirm(MapLocationResult(
      latitude: _markerPosition.latitude,
      longitude: _markerPosition.longitude,
      address: widget.optionalAddress,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select your location'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _markerPosition,
              zoom: 16,
            ),
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _markerPosition,
                draggable: true,
                onDragEnd: (LatLng position) {
                  setState(() => _markerPosition = position);
                },
              ),
            },
            onTap: (LatLng position) {
              setState(() => _markerPosition = position);
            },
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
                      SizedBox(height: 16),
                      Text('Loading map...'),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: _mapReady ? _onConfirm : null,
                icon: const Icon(Icons.check, color: Colors.black),
                label: const Text(
                  'Confirm Location',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
