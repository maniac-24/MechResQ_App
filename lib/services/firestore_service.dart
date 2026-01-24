import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");
    return user.uid;
  }

  // ✅ USERS COLLECTION
  Future<void> createUserProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    await _db.collection("users").doc(_uid).set(
      {
        "uid": _uid,
        "role": "user",
        "name": name,
        "email": email,
        "phone": phone,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ✅ MECHANICS COLLECTION
  Future<void> createMechanicProfile({
    required String name,
    required String email,
    required String phone,
    required String shopName, // ✅ fixed
    required List<String> vehicleTypes,
    required String address,
  }) async {
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
        "isVerified": false,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ✅ GET CURRENT PROFILE
  Future<Map<String, dynamic>?> getMyProfile() async {
    final userDoc = await _db.collection("users").doc(_uid).get();
    if (userDoc.exists) return userDoc.data();

    final mechDoc = await _db.collection("mechanics").doc(_uid).get();
    if (mechDoc.exists) return mechDoc.data();

    return null;
  }
}
