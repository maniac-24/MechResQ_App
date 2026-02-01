import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");
    return user.uid;
  }

  // =========================================================
  // USERS COLLECTION
  // =========================================================
  Future<void> createUserProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final now = FieldValue.serverTimestamp();

    await _db.collection("users").doc(_uid).set(
      {
        "uid": _uid,
        "role": "user",
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
  // MECHANICS COLLECTION
  // =========================================================
  /// Shop location is stored for backend logic only.
  /// ID details are stored for admin verification.
  Future<void> createMechanicProfile({
    required String name,
    required String email,
    required String phone,
    required String shopName,
    required List<String> vehicleTypes,
    required String address,

    // 📍 Workshop location (private)
    double? shopLat,
    double? shopLng,
    String? shopAddress,

    // 🪪 ID verification details
    String? idType,
    String? idNumber,
    String? idFileName,
    String? idFilePath,
  }) async {
    final now = FieldValue.serverTimestamp();

    await _db.collection("mechanics").doc(_uid).set(
      {
        "uid": _uid,
        "role": "mechanic",
        "name": name,
        "email": email,
        "phone": phone,
        "shopName": shopName,
        "vehicleTypes": vehicleTypes,
        "address": address,

        // 🔐 Verification
        "isVerified": false,
        "verificationStatus": "pending", // pending | approved | rejected

        // 🪪 ID DETAILS
        if (idType != null) "idType": idType,
        if (idNumber != null) "idNumber": idNumber,
        if (idFileName != null) "idFileName": idFileName,
        if (idFilePath != null) "idFilePath": idFilePath,

        // 📍 SHOP LOCATION (NOT PUBLIC)
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
  // GET CURRENT PROFILE (USER OR MECHANIC)
  // =========================================================
  Future<Map<String, dynamic>?> getMyProfile() async {
    final userDoc = await _db.collection("users").doc(_uid).get();
    if (userDoc.exists) return userDoc.data();

    final mechDoc = await _db.collection("mechanics").doc(_uid).get();
    if (mechDoc.exists) return mechDoc.data();

    return null;
  }
}
