// lib/services/request_service.dart
//
// Clean, stable in-memory RequestService for demo/development.
// You can later replace this with API / Firebase / SQLite backend.

class RequestService {
  // Internal store (most recent request at the top)
  static final List<Map<String, dynamic>> _store = [];

  /// ----------------------------------------------------------
  /// SAVE a new request → returns generated unique request ID
  /// ----------------------------------------------------------
  static String save(Map<String, dynamic> data) {
    final id = 'req-${DateTime.now().millisecondsSinceEpoch}';

    final entry = {
      ...data,                     // user submitted fields
      'id': id,                    // generated id
      'status': data['status'] ?? 'pending',
      'createdAt': DateTime.now(), // auto timestamp
    };

    _store.insert(0, entry); // newest first
    return id;
  }

  /// ----------------------------------------------------------
  /// GET ALL REQUESTS → returns a *copy* (safe)
  /// ----------------------------------------------------------
  static List<Map<String, dynamic>> all() {
    return _store.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// ----------------------------------------------------------
  /// FIND request by ID → returns copy or null
  /// ----------------------------------------------------------
  static Map<String, dynamic>? find(String id) {
    try {
      final found = _store.firstWhere((r) => r['id'] == id);
      return Map<String, dynamic>.from(found);
    } catch (_) {
      return null;
    }
  }

  /// ----------------------------------------------------------
  /// UPDATE request by ID (merge new fields)
  /// ----------------------------------------------------------
  static bool update(String id, Map<String, dynamic> updates) {
    final index = _store.indexWhere((r) => r['id'] == id);
    if (index == -1) return false;

    _store[index] = {
      ..._store[index],
      ...updates,
    };

    return true;
  }

  /// ----------------------------------------------------------
  /// DELETE request (optional)
  /// ----------------------------------------------------------
  static bool remove(String id) {
    final index = _store.indexWhere((r) => r['id'] == id);
    if (index == -1) return false;

    _store.removeAt(index);
    return true;
  }

  /// ----------------------------------------------------------
  /// CLEAR all requests (debug only)
  /// ----------------------------------------------------------
  static void clear() {
    _store.clear();
  }
}
