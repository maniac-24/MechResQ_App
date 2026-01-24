import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  // ✅ REGISTER USER
  Future<void> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);

    await _firestore.createUserProfile(
      name: name,
      email: email,
      phone: phone,
    );
  }

  // ✅ REGISTER MECHANIC
  Future<void> registerMechanic({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String shopName,
    required String vehicleTypes,
    required String address,
  }) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);

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
      address: address,
    );
  }

  // ✅ LOGIN
  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // ✅ FORGOT PASSWORD
  Future<void> forgotPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ✅ USED IN SPLASH
  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  // ✅ GET CURRENT PROFILE
  Future<Map<String, dynamic>?> getMyProfile() async {
    return _firestore.getMyProfile();
  }

  // ✅ USED IN SPLASH
  Future<String?> getRole() async {
    final profile = await getMyProfile();
    return profile?["role"]?.toString();
  }

  // ✅ USED IN PROFILE + HOME
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    return getMyProfile();
  }

  // ✅ LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}
