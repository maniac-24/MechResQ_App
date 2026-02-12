import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  // ─────────────────────────────────────────────────────────────
  // SINGLETON
  // ─────────────────────────────────────────────────────────────
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  // ─────────────────────────────────────────────────────────────
  // REGISTER USER (ATOMIC + SAFE)
  // ─────────────────────────────────────────────────────────────
  Future<void> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    UserCredential? credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.createUserProfile(
        name: name,
        email: email,
        phone: phone,
      );
    } catch (e) {
      if (credential?.user != null) {
        await credential!.user!.delete();
      }
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // REGISTER MECHANIC (ATOMIC + SAFE)
  // ─────────────────────────────────────────────────────────────
  Future<void> registerMechanic({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String shopName,
    required String vehicleTypes,
    required String address,
    double? shopLat,
    double? shopLng,
    String? shopAddress,
    String? idType,
    String? idNumber,
    String? idFileName,
    required List<String> services,
  }) async {
    UserCredential? credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final vehicleTypesList = vehicleTypes
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await _firestore.createMechanicProfile(
        name: name,
        email: email,
        phone: phone,
        shopName: shopName,
        vehicleTypes: vehicleTypesList,
        services: services,
        address: address,
        shopLat: shopLat,
        shopLng: shopLng,
        shopAddress: shopAddress,
        idType: idType,
        idNumber: idNumber,
        idFileName: idFileName,
      );
    } catch (e) {
      if (credential?.user != null) {
        await credential!.user!.delete();
      }
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────────────────────────
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FORGOT PASSWORD
  // ─────────────────────────────────────────────────────────────
  Future<void> forgotPassword({
    required String email,
  }) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ─────────────────────────────────────────────────────────────
  // AUTH STATE
  // ─────────────────────────────────────────────────────────────
  bool isLoggedIn() => _auth.currentUser != null;

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.uid;

  // ─────────────────────────────────────────────────────────────
  // PROFILE ACCESS (UI SAFE)
  // ─────────────────────────────────────────────────────────────

  /// Used in FutureBuilder screens
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    return _firestore.getMyProfile();
  }

  /// Backward compatibility (if some screens use this name)
  Future<Map<String, dynamic>?> getMyProfile() async {
    return _firestore.getMyProfile();
  }

  /// Used in StreamBuilder screens
  Stream<Map<String, dynamic>?> getMyProfileStream() {
    return _firestore.getMyProfileStream();
  }

  /// Used in splash / routing
  Future<String?> getRole() async {
    final profile = await getCurrentUserProfile();
    return profile?['role']?.toString();
  }

  // ─────────────────────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }
}
