// lib/utils/location_permission_utils.dart
// Reusable location permission handling: explanation dialog, request, open settings.

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Result of requesting location permission.
enum LocationPermissionResult {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  error,
}

/// Message to show before requesting permission.
const String kLocationExplanationMessage =
    'We need your location to send help to the nearest mechanic.';

/// Shows an explanation dialog, then requests location permission.
/// Returns [LocationPermissionResult] (does not throw).
Future<LocationPermissionResult> requestLocationPermissionWithExplanation(
  BuildContext context,
) async {
  final shouldRequest = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Location access'),
      content: const Text(kLocationExplanationMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Allow'),
        ),
      ],
    ),
  );

  if (shouldRequest != true || !context.mounted) {
    return LocationPermissionResult.denied;
  }

  return requestLocationPermission();
}

/// Requests location permission (no dialog).
/// Returns [LocationPermissionResult].
Future<LocationPermissionResult> requestLocationPermission() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionResult.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationPermissionResult.granted;
      case LocationPermission.denied:
        return LocationPermissionResult.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionResult.deniedForever;
      case LocationPermission.unableToDetermine:
        return LocationPermissionResult.denied;
    }
  } catch (e) {
    return LocationPermissionResult.error;
  }
}

/// Opens app settings so the user can enable location permission.
Future<bool> openAppSettingsForLocation() {
  return Geolocator.openAppSettings();
}

/// Shows a snackbar or dialog for permission result and optionally
/// offers "Open settings" for deniedForever.
void handlePermissionResult(
  BuildContext context, {
  required LocationPermissionResult result,
  VoidCallback? onGranted,
  VoidCallback? onDeniedForeverOpenSettings,
}) {
  switch (result) {
    case LocationPermissionResult.granted:
      onGranted?.call();
      break;
    case LocationPermissionResult.denied:
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location access was denied.'),
          ),
        );
      }
      break;
    case LocationPermissionResult.deniedForever:
      if (context.mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Location access'),
            content: const Text(
              'Location is permanently denied. Please enable it in app settings to use this feature.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  openAppSettingsForLocation();
                  onDeniedForeverOpenSettings?.call();
                },
                child: const Text('Open settings'),
              ),
            ],
          ),
        );
      }
      break;
    case LocationPermissionResult.serviceDisabled:
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled. Please turn on GPS.'),
          ),
        );
      }
      break;
    case LocationPermissionResult.error:
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong with location. Please try again.'),
          ),
        );
      }
      break;
  }
}
