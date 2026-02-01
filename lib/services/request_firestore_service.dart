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

  /// Create a new service request
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
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final requestRef = _db.collection('requests').doc();

    final data = {
      'requestId': requestRef.id,
      'userId': userId,
      'vehicleType': vehicleType,
      'issue': issue,
      'location': location,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'mechanicId': mechanicId,
      'images': images ?? [],
      'userLat': userLat,
      'userLng': userLng,
      'locationAddress': locationAddress,
    };

    await requestRef.set(data);
    return requestRef.id;
  }

  /// User request history
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

  /// Cancel request (user side)
  Future<void> cancelRequest(String requestId) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final doc = await _db.collection('requests').doc(requestId).get();
    if (!doc.exists) {
      throw Exception('Request not found');
    }

    if (doc.data()!['userId'] != userId) {
      throw Exception('Not authorized');
    }

    await _db.collection('requests').doc(requestId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // MECHANIC SIDE (ONLINE AWARE)
  // =========================================================

  /// 🔔 Incoming requests (ONLY when mechanic is ONLINE)
  Stream<List<Map<String, dynamic>>> getIncomingRequestsStream({
    required String mechanicId,
    required bool isOnline,
  }) {
    if (!isOnline) {
      return Stream.value([]);
    }

    return _db
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((d) => d.data()['mechanicId'] == null)
            .map(_mapDoc)
            .toList());
  }

  /// Requests by mechanic + status
  Stream<List<Map<String, dynamic>>> getMechanicRequestsByStatusStream(
    String mechanicId,
    String status,
  ) {
    return _db
        .collection('requests')
        .where('mechanicId', isEqualTo: mechanicId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapSnapshot);
  }

  /// ✅ Accept request (BLOCKED if mechanic is offline)
  Future<void> acceptRequest({
    required String requestId,
    required String mechanicId,
  }) async {
    final mechanicDoc =
        await _db.collection('mechanics').doc(mechanicId).get();

    final isOnline = mechanicDoc.data()?['isOnline'] ?? false;
    if (!isOnline) {
      throw Exception('You are offline. Go online to accept requests.');
    }

    await _db.collection('requests').doc(requestId).update({
      'mechanicId': mechanicId,
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reject request
  Future<void> rejectRequest(String requestId) async {
    await _db.collection('requests').doc(requestId).update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Complete request with amount
  Future<void> completeRequest(
    String requestId,
    double amount,
  ) async {
    await _db.collection('requests').doc(requestId).update({
      'status': 'completed',
      'amount': amount,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // COUNTS (MECHANIC DASHBOARD)
  // =========================================================

  /// 🔔 Incoming count (ONLINE ONLY)
  Stream<int> getIncomingRequestsCountStream({
    required String mechanicId,
    required bool isOnline,
  }) {
    if (!isOnline) {
      return Stream.value(0);
    }

    return _db
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((d) => d.data()['mechanicId'] == null)
            .length);
  }

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

  // =========================================================
  // EARNINGS
  // =========================================================

  Stream<double> getTotalEarningsStream(String mechanicId) {
    return _db
        .collection('requests')
        .where('mechanicId', isEqualTo: mechanicId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
      double total = 0;
      for (var d in snapshot.docs) {
        total += (d.data()['amount'] ?? 0).toDouble();
      }
      return total;
    });
  }

  Stream<List<Map<String, dynamic>>> getDailyEarningsStream(
    String mechanicId,
  ) {
    return _db
        .collection('requests')
        .where('mechanicId', isEqualTo: mechanicId)
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final Map<String, Map<String, dynamic>> grouped = {};

      for (var d in snapshot.docs) {
        final date = (d['completedAt'] as Timestamp).toDate();
        final key = '${date.day}-${date.month}-${date.year}';

        grouped.putIfAbsent(key, () => {
              'date': date,
              'jobs': 0,
              'amount': 0.0,
            });

        grouped[key]!['jobs']++;
        grouped[key]!['amount'] +=
            (d.data()['amount'] ?? 0).toDouble();
      }

      return grouped.values.toList();
    });
  }

  // =========================================================
  // USER PROFILE (READ ONLY)
  // =========================================================

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  // =========================================================
  // HELPERS
  // =========================================================

  List<Map<String, dynamic>> _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map(_mapDoc).toList();
  }

  Map<String, dynamic> _mapDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();

    return {
      'requestId': d['requestId'] ?? doc.id,
      'userId': d['userId'],
      'mechanicId': d['mechanicId'],
      'vehicleType': d['vehicleType'],
      'issue': d['issue'],
      'location': d['location'],
      'locationAddress': d['locationAddress'],
      'userLat': d['userLat'],
      'userLng': d['userLng'],
      'status': d['status'],
      'amount': d['amount'] ?? 0,
      'createdAt': (d['createdAt'] as Timestamp?)?.toDate(),
      'completedAt': (d['completedAt'] as Timestamp?)?.toDate(),
    };
  }
}
