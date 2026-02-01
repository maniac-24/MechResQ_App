// lib/utils/directions_service.dart
// Fetches route from Google Directions API and decodes polyline for map display.

import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'google_maps_config.dart';

/// Result of a successful directions fetch.
class DirectionsResult {
  const DirectionsResult({
    required this.polylinePoints,
    required this.distanceKm,
    required this.durationMinutes,
  });

  final List<LatLng> polylinePoints;
  final double distanceKm;
  final int durationMinutes;
}

/// Fetches route from origin to destination using Google Directions API.
/// Returns [DirectionsResult] or null on failure.
Future<DirectionsResult?> fetchDirections({
  required double originLat,
  required double originLng,
  required double destLat,
  required double destLng,
  String apiKey = kGoogleMapsApiKey,
}) async {
  final origin = '$originLat,$originLng';
  final dest = '$destLat,$destLng';
  final uri = Uri.parse(
    'https://maps.googleapis.com/maps/api/directions/json'
    '?origin=${Uri.encodeComponent(origin)}'
    '&destination=${Uri.encodeComponent(dest)}'
    '&key=${Uri.encodeComponent(apiKey)}',
  );

  final response = await http.get(uri);

  if (response.statusCode != 200) {
    return null;
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>?;
  if (json == null) return null;

  final status = json['status'] as String?;
  if (status != 'OK') return null;

  final routes = json['routes'] as List<dynamic>?;
  if (routes == null || routes.isEmpty) return null;

  final route = routes[0] as Map<String, dynamic>?;
  if (route == null) return null;

  final legs = route['legs'] as List<dynamic>?;
  if (legs == null || legs.isEmpty) return null;

  final leg = legs[0] as Map<String, dynamic>?;
  if (leg == null) return null;

  double distanceMeters = 0;
  int durationSeconds = 0;
  final distanceObj = leg['distance'];
  final durationObj = leg['duration'];
  if (distanceObj is Map && distanceObj['value'] != null) {
    distanceMeters = (distanceObj['value'] as num).toDouble();
  }
  if (durationObj is Map && durationObj['value'] != null) {
    durationSeconds = (durationObj['value'] as num).toInt();
  }

  final distanceKm = distanceMeters / 1000;
  final durationMinutes = (durationSeconds / 60).ceil();

  List<LatLng> polylinePoints = [];
  final overviewPolyline = route['overview_polyline'] as Map<String, dynamic>?;
  final encoded = overviewPolyline?['points'] as String?;
  if (encoded != null && encoded.isNotEmpty) {
    polylinePoints = decodePolyline(encoded);
  }

  return DirectionsResult(
    polylinePoints: polylinePoints,
    distanceKm: distanceKm,
    durationMinutes: durationMinutes,
  );
}

/// Decodes Google's encoded polyline format into [LatLng] list.
List<LatLng> decodePolyline(String encoded) {
  final list = <LatLng>[];
  int index = 0;
  int len = encoded.length;
  int lat = 0;
  int lng = 0;

  while (index < len) {
    int b;
    int shift = 0;
    int result = 0;
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

    list.add(LatLng(
      lat / 1e5,
      lng / 1e5,
    ));
  }
  return list;
}
