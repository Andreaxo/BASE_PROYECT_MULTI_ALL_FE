/// Model for login request payload.
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

/// Model for login response from the API.
class LoginResponse {
  final String token;
  final UserInfo user;

  LoginResponse({required this.token, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Basic user info returned in the login response.
class UserInfo {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final int? roleId;
  final String roleCode;

  UserInfo({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.roleId,
    required this.roleCode,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: (json['email'] as String?) ?? '',
      firstName: (json['first_name'] as String?) ?? '',
      lastName: (json['last_name'] as String?) ?? '',
      roleId: (json['role_id'] as num?)?.toInt(),
      roleCode: (json['role_code'] as String?) ?? '',
    );
  }
}
