import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestore service for handling service requests, counts & earnings
class RequestFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // =========================================================
  // USER SIDE
  // =========================================================

  Future<String> createRequest({
    required String vehicleType,
    required String issue,
    required String location,
    String? mechanicId,
    List<String>? images,
    double? userLat,
    double? userLng,
    String? locationAddress,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final requestRef = _db.collection('requests').doc();

    await requestRef.set({
      'requestId': requestRef.id,
      'userId': userId,
      'vehicleType': vehicleType,
      'issue': issue,
      'location': location,
      'status': 'pending',
      'mechanicId': mechanicId,
      'images': images ?? [],
      'userLat': userLat,
      'userLng': userLng,
      'locationAddress': locationAddress,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return requestRef.id;
  }

  Stream<List<Map<String, dynamic>>> getUserRequestsStream() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);

    return _db
        .collection('requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapSnapshot);
  }

  Future<void> cancelRequest(String requestId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    await _db.collection('requests').doc(requestId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // MECHANIC SIDE
  // =========================================================

  Future<void> acceptRequest({
    required String requestId,
    required String mechanicId,
  }) async {
    final mechanicDoc =
        await _db.collection('mechanics').doc(mechanicId).get();

    if (!(mechanicDoc.data()?['isOnline'] ?? false)) {
      throw Exception('Mechanic is offline');
    }

    await _db.collection('requests').doc(requestId).update({
      'mechanicId': mechanicId,
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectRequest(String requestId) async {
    await _db.collection('requests').doc(requestId).update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeRequest(String requestId, double amount) async {
    await _db.collection('requests').doc(requestId).update({
      'status': 'completed',
      'amount': amount,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // COUNTS & EARNINGS
  // =========================================================

  Stream<int> getActiveRequestsCountStream(String mechanicId) {
    return _db
        .collection('requests')
        .where('mechanicId', isEqualTo: mechanicId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<int> getCompletedRequestsCountStream(String mechanicId) {
    return _db
        .collection('requests')
        .where('mechanicId', isEqualTo: mechanicId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<double> getTotalEarningsStream(String mechanicId) {
    return _db
        .collection('requests')
        .where('mechanicId', isEqualTo: mechanicId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((s) => s.docs.fold<double>(
            0, (sum, d) => sum + (d['amount'] ?? 0)));
  }

  // ── RESTORED: required by mechanic screens ──────────────────────────────

  /// Returns pending requests that have no mechanic assigned yet.
  /// Used by IncomingRequestsScreen and MechanicHomeScreen badge.
  Stream<List<Map<String, dynamic>>> getIncomingRequestsStream({
    required String mechanicId,
    required bool isOnline,
  }) {
    if (!isOnline) return Stream.value([]);

    return _db
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs
            .where((d) => d['mechanicId'] == null)
            .map(_mapDoc)
            .toList());
  }

  /// Count of unassigned pending requests.
  /// Used by MechanicHomeScreen for the badge counter.
  Stream<int> getIncomingRequestsCountStream({
    required String mechanicId,
    required bool isOnline,
  }) {
    if (!isOnline) return Stream.value(0);

    return _db
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) =>
            s.docs.where((d) => d['mechanicId'] == null).length);
  }

  /// Returns requests assigned to a specific mechanic filtered by status.
  /// Used by ActiveServiceScreen and ServiceHistoryScreen.
  Stream<List<Map<String, dynamic>>> getMechanicRequestsByStatusStream(
    String mechanicId,
    String status,
  ) {
    return _db
        .collection('requests')
        .where('mechanicId', isEqualTo: mechanicId)
        .where('status', isEqualTo: status)
        .snapshots()
        .map(_mapSnapshot);
  }

  /// Fetches user profile data (name, phone, etc.).
  /// Used by IncomingRequestsScreen and ServiceHistoryScreen to show user info.
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  /// Returns completed requests grouped by day for earnings breakdown.
  /// Used by EarningsScreen to show daily earnings list.
  Stream<List<Map<String, dynamic>>> getDailyEarningsStream(
    String mechanicId,
  ) {
    return _db
        .collection('requests')
        .where('mechanicId', isEqualTo: mechanicId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((s) => s.docs.map(_mapDoc).toList());
  }

  // =========================================================
  // HELPERS
  // =========================================================

  List<Map<String, dynamic>> _mapSnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map(_mapDoc).toList();
  }

  Map<String, dynamic> _mapDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return {
      'requestId': d['requestId'] ?? doc.id,
      'userId': d['userId'],
      'mechanicId': d['mechanicId'],
      'vehicleType': d['vehicleType'],
      'issue': d['issue'],
      'status': d['status'],
      'userLat': d['userLat'],
      'userLng': d['userLng'],
      'createdAt': (d['createdAt'] as Timestamp?)?.toDate(),
      'completedAt': (d['completedAt'] as Timestamp?)?.toDate(),
      'amount': d['amount'] ?? 0,
    };
  }
}