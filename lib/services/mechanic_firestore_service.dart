// lib/services/mechanic_firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to fetch verified mechanics from Firestore
class MechanicFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches current mechanic's shop coordinates (for mechanic-only screens e.g. request route preview).
  /// Returns null if not logged in or shop location not set.
  Future<({double lat, double lng})?> getCurrentMechanicShopLocation() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db.collection('mechanics').doc(uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    // Role safety check
    if (data['role'] != 'mechanic') return null;

    final lat = data['shopLat'];
    final lng = data['shopLng'];

    if (lat is num && lng is num) {
      return (lat: lat.toDouble(), lng: lng.toDouble());
    }

    return null;
  }

  /// Saves shop location for the current mechanic. Used only for backend (sorting by distance, eligibility).
  /// Shop location must NOT be exposed as a pin on user-facing maps.
  Future<void> saveShopLocation({
    required double shopLat,
    required double shopLng,
    String? shopAddress,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    await _db.collection('mechanics').doc(uid).set(
      {
        'shopLat': shopLat,
        'shopLng': shopLng,
        if (shopAddress != null && shopAddress.isNotEmpty)
          'shopAddress': shopAddress,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Returns a stream of verified mechanics as List<Map<String, dynamic>>
  /// Only mechanics where isVerified == true are included
  /// Ordered by creation date (newest first) for consistent UI presentation
  Stream<List<Map<String, dynamic>>> getVerifiedMechanicsStream() {
    return _db
        .collection('mechanics')
        .where('isVerified', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final uid = doc.id;

        // Role safety: only include documents with mechanic role
        if (data['role'] != 'mechanic') {
          return null;
        }

        return {
          'uid': uid,
          'id': uid,

          // Core mechanic info
          'name': (data['name'] ?? '').toString(),
          'shopName': (data['shopName'] ?? '').toString(),
          'email': (data['email'] ?? '').toString(),
          'phone': (data['phone'] ?? '').toString(),
          'address': (data['address'] ?? '').toString(),

          // Vehicle types as List<String>
          'vehicleTypes': (data['vehicleTypes'] is List)
              ? List<String>.from(data['vehicleTypes'])
              : <String>[],

          // Services offered as List<String>
          'services': (data['services'] is List)
              ? List<String>.from(data['services'])
              : <String>[],

          // Verification status
          'isVerified': data['isVerified'] ?? false,

          // Real metrics (not dummy data)
          'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
          'totalReviews': (data['totalReviews'] as num?)?.toInt() ?? 0,
          'experienceYears': (data['experienceYears'] as num?)?.toInt() ?? 0,

          // Timestamps
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],

          // NOTE: distanceKm is NOT stored in Firestore
          // It must be computed client-side based on user location:
          // double distanceKm = calculateDistance(userLat, userLng, mechLat, mechLng);
        };
      }).whereType<Map<String, dynamic>>().toList(); // Filter out nulls from role check
    });
  }
}