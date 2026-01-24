import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  // Secure storage instance
  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  // Keys
  static const String _tokenKey = "access_token";
  static const String _roleKey = "user_role";
  static const String _userIdKey = "user_id";

  // ===============================
  // SAVE DATA
  // ===============================

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<void> saveRole(String role) async {
    await _storage.write(key: _roleKey, value: role);
  }

  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  // ===============================
  // READ DATA
  // ===============================

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  // ===============================
  // AUTH STATE
  // ===============================

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ===============================
  // LOGOUT
  // ===============================

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
