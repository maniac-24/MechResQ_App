import 'package:cloud_firestore/cloud_firestore.dart';

class MechanicStatusService {
  final _db = FirebaseFirestore.instance;

  /// Set mechanic availability
  Future<void> setOnlineStatus({
    required String mechanicId,
    required bool isOnline,
  }) async {
    await _db.collection('mechanics').doc(mechanicId).update({
      'isOnline': isOnline,
      'lastSeenAt': FieldValue.serverTimestamp(),
    });
  }

  /// Realtime availability listener
  Stream<bool> onlineStatusStream(String mechanicId) {
    return _db
        .collection('mechanics')
        .doc(mechanicId)
        .snapshots()
        .map((doc) => (doc.data()?['isOnline'] ?? false) as bool);
  }
}
