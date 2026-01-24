// lib/services/mechanic_firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to fetch verified mechanics from Firestore
class MechanicFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
