import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ----------------------------------------------------------------
/// ENUMS (DEFINED HERE TO FIX YOUR BUILD ERRORS)
/// ----------------------------------------------------------------
enum UserRole { user, mechanic }

enum VerificationStatus {
  pending,
  approved,
  rejected;

  String get value => name;
}

/// ----------------------------------------------------------------
/// FIRESTORE SERVICE
/// ----------------------------------------------------------------
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // =========================================================
  // CREATE USER PROFILE
  // =========================================================
  Future<void> createUserProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    if (_uid == null) {
      throw Exception('User not authenticated');
    }

    final now = FieldValue.serverTimestamp();

    await _db.collection("users").doc(_uid).set(
      {
        "uid": _uid,
        "role": UserRole.user.name,
        "name": name,
        "email": email,
        "phone": phone,
        "createdAt": now,
        "updatedAt": now,
      },
      SetOptions(merge: true),
    );
  }

  // =========================================================
  // CREATE MECHANIC PROFILE
  // =========================================================
  Future<void> createMechanicProfile({
    required String name,
    required String email,
    required String phone,
    required String shopName,
    required List<String> vehicleTypes,
    required List<String> services,
    required String address,
    double? shopLat,
    double? shopLng,
    String? shopAddress,
    String? idType,
    String? idNumber,
    String? idFileName,
    String? idFilePath,
  }) async {
    if (_uid == null) {
      throw Exception('User not authenticated');
    }

    final now = FieldValue.serverTimestamp();

    await _db.collection("mechanics").doc(_uid).set(
      {
        "uid": _uid,
        "role": UserRole.mechanic.name,
        "name": name,
        "email": email,
        "phone": phone,
        "shopName": shopName,
        "vehicleTypes": vehicleTypes,
        "services": services,
        "address": address,

        // Verification
        "isVerified": false,
        "verificationStatus": VerificationStatus.pending.value,

        // ID
        if (idType != null) "idType": idType,
        if (idNumber != null) "idNumber": idNumber,
        if (idFileName != null) "idFileName": idFileName,
        if (idFilePath != null) "idFilePath": idFilePath,

        // Shop location
        if (shopLat != null) "shopLat": shopLat,
        if (shopLng != null) "shopLng": shopLng,
        if (shopAddress != null && shopAddress.isNotEmpty)
          "shopAddress": shopAddress,

        "createdAt": now,
        "updatedAt": now,
      },
      SetOptions(merge: true),
    );
  }

  // =========================================================
  // GET CURRENT PROFILE (FUTURE)
  // =========================================================
  Future<Map<String, dynamic>?> getMyProfile() async {
    if (_uid == null) return null;

    final userDoc =
        await _db.collection("users").doc(_uid).get();

    if (userDoc.exists) return userDoc.data();

    final mechDoc =
        await _db.collection("mechanics").doc(_uid).get();

    if (mechDoc.exists) return mechDoc.data();

    return null;
  }

  // =========================================================
  // PROFILE STREAM (FIXED VERSION)
  // =========================================================
  Stream<Map<String, dynamic>?> getMyProfileStream() {
    if (_uid == null) {
      return const Stream.empty();
    }

    final userRef = _db.collection("users").doc(_uid);
    final mechRef = _db.collection("mechanics").doc(_uid);

    return userRef.snapshots().asyncMap((userSnap) async {
      if (userSnap.exists) {
        return userSnap.data();
      }

      final mechSnap = await mechRef.get();
      if (mechSnap.exists) {
        return mechSnap.data();
      }

      return null;
    });
  }
}
