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
    final d = doc.data();
    final lat = d?['shopLat'];
    final lng = d?['shopLng'];
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
        if (shopAddress != null && shopAddress.isNotEmpty) 'shopAddress': shopAddress,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Returns a stream of verified mechanics as List<Map<String, dynamic>>
  /// Only mechanics where isVerified == true are included
  Stream<List<Map<String, dynamic>>> getVerifiedMechanicsStream() {
    return _db
        .collection('mechanics')
        .where('isVerified', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final uid = doc.id;

        return {
          'uid': uid,
          'id': uid,

          'name': (data['name'] ?? '').toString(),
          'shopName': (data['shopName'] ?? '').toString(),
          'email': (data['email'] ?? '').toString(),
          'phone': (data['phone'] ?? '').toString(),
          'address': (data['address'] ?? '').toString(),

          // ✅ VehicleTypes as List<String>
          'vehicleTypes': (data['vehicleTypes'] is List)
              ? List<String>.from(data['vehicleTypes'])
              : <String>[],

          'isVerified': data['isVerified'] ?? false,

          // Optional fields with safe defaults
          'rating': (data['rating'] as num?)?.toDouble() ?? 0.0,
          'totalReviews': (data['totalReviews'] as num?)?.toInt() ?? 0,

          // Dummy compatibility fields (can remove later)
          'experienceYears': (data['experienceYears'] as num?)?.toInt() ?? 0,
          'serviceTypes': data['serviceTypes'] ?? [],
          'priceRange': data['priceRange']?.toString() ?? '',
          'distanceKm': (data['distanceKm'] as num?)?.toDouble() ?? 0.0,

          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        };
      }).toList(); // ✅ IMPORTANT: convert Iterable -> List
    });
  }
}
