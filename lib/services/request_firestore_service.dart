// lib/services/request_firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to manage service requests in Firestore
class RequestFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Create a new service request in Firestore
  /// Returns the generated request ID
  Future<String> createRequest({
    required String vehicleType,
    required String issue,
    required String location,
    String? mechanicId,
    List<String>? images,
  }) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User must be logged in to create a request');
    }

    final requestId = _db.collection('requests').doc().id;

    final requestData = <String, dynamic>{
      'requestId': requestId,
      'userId': userId,
      'vehicleType': vehicleType,
      'issue': issue,
      'location': location,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Add optional fields only if they are not null
    if (mechanicId != null && mechanicId.isNotEmpty) {
      requestData['mechanicId'] = mechanicId;
    }

    if (images != null && images.isNotEmpty) {
      requestData['images'] = images;
    }

    await _db.collection('requests').doc(requestId).set(requestData);

    return requestId;
  }

  /// Get a stream of requests for the current user
  /// Ordered by createdAt descending (newest first)
  Stream<List<Map<String, dynamic>>> getUserRequestsStream() {
    final userId = _currentUserId;
    if (userId == null) {
      // Return empty stream if user is not logged in
      return Stream.value([]);
    }

    return _db
        .collection('requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        
        // Convert Timestamp to DateTime if present
        DateTime? createdAt;
        if (data['createdAt'] != null) {
          final timestamp = data['createdAt'] as Timestamp?;
          createdAt = timestamp?.toDate();
        }

        DateTime? updatedAt;
        if (data['updatedAt'] != null) {
          final timestamp = data['updatedAt'] as Timestamp?;
          updatedAt = timestamp?.toDate();
        }

        return {
          'id': data['requestId'] ?? doc.id,
          'requestId': data['requestId'] ?? doc.id,
          'userId': data['userId'] ?? '',
          'mechanicId': data['mechanicId'],
          'vehicleType': data['vehicleType'] ?? '',
          'vehicle': data['vehicleType'] ?? '', // For backward compatibility
          'issue': data['issue'] ?? '',
          'location': data['location'] ?? '',
          'status': data['status'] ?? 'pending',
          'images': (data['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
          'createdAt': createdAt,
          'updatedAt': updatedAt,
        };
      }).toList();
    });
  }

  /// Update request status
  Future<void> updateRequestStatus(String requestId, String status) async {
    await _db.collection('requests').doc(requestId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ================= MECHANIC-SPECIFIC METHODS =================

  /// Get stream of all requests assigned to a mechanic
  /// Ordered by createdAt descending (newest first)
  Stream<List<Map<String, dynamic>>> getMechanicRequestsStream(String mechanicId) {
    return _db
        .collection('requests')
        .where('mechanicId', isEqualTo: mechanicId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _mapRequestData(doc.id, data);
      }).toList();
    });
  }

  /// Get stream of requests for a mechanic filtered by status
  /// Ordered by createdAt descending (newest first)
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
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _mapRequestData(doc.id, data);
      }).toList();
    });
  }

  /// Get stream of incoming requests (pending, not yet assigned to any mechanic)
  /// Ordered by createdAt descending (newest first)
  Stream<List<Map<String, dynamic>>> getIncomingRequestsStream() {
    return _db
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            // Only show requests that don't have a mechanicId assigned yet
            return data['mechanicId'] == null;
          })
          .map((doc) {
            final data = doc.data();
            return _mapRequestData(doc.id, data);
          })
          .toList();
    });
  }

  /// Accept a request (assigns mechanic and updates status to 'accepted')
  Future<void> acceptRequest(String requestId, String mechanicId) async {
    await _db.collection('requests').doc(requestId).update({
      'mechanicId': mechanicId,
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reject a request (updates status to 'rejected')
  Future<void> rejectRequest(String requestId) async {
    await _db.collection('requests').doc(requestId).update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark request as completed
  Future<void> completeRequest(String requestId) async {
    await _db.collection('requests').doc(requestId).update({
      'status': 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get count stream for incoming requests (pending, unassigned)
  Stream<int> getIncomingRequestsCountStream() {
    return _db
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data()['mechanicId'] == null)
          .length;
    });
  }

  /// Get count stream for active requests (accepted) for a mechanic
  Stream<int> getActiveRequestsCountStream(String mechanicId) {
    return _db
        .collection('requests')
        .where('mechanicId', isEqualTo: mechanicId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get count stream for completed requests for a mechanic
  Stream<int> getCompletedRequestsCountStream(String mechanicId) {
    return _db
        .collection('requests')
        .where('mechanicId', isEqualTo: mechanicId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get user profile by userId (for displaying user name in requests)
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data();
    }
    return null;
  }

  // ================= HELPER METHODS =================

  /// Map Firestore document data to request map
  Map<String, dynamic> _mapRequestData(String docId, Map<String, dynamic> data) {
    // Convert Timestamp to DateTime if present
    DateTime? createdAt;
    if (data['createdAt'] != null) {
      final timestamp = data['createdAt'] as Timestamp?;
      createdAt = timestamp?.toDate();
    }

    DateTime? updatedAt;
    if (data['updatedAt'] != null) {
      final timestamp = data['updatedAt'] as Timestamp?;
      updatedAt = timestamp?.toDate();
    }

    return {
      'id': data['requestId'] ?? docId,
      'requestId': data['requestId'] ?? docId,
      'userId': data['userId'] ?? '',
      'mechanicId': data['mechanicId'],
      'vehicleType': data['vehicleType'] ?? '',
      'vehicle': data['vehicleType'] ?? '', // For backward compatibility
      'issue': data['issue'] ?? '',
      'location': data['location'] ?? '',
      'status': data['status'] ?? 'pending',
      'images': (data['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
