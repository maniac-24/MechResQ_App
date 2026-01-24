class AuthUser {
  final String accessToken;
  final String role;
  final String userId;
  final String name;
  final String email;
  final String phone;

  AuthUser({
    required this.accessToken,
    required this.role,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      accessToken: json['access_token']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}
