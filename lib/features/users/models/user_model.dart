/// User model matching the backend UserResponse.
class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final bool isActive;
  final String photoUrl;
  final int? createBy;
  final String? createAt;
  final String? createByName;
  final int? updateBy;
  final String? updateAt;
  final String? updateByName;
  final int? roleId;
  final String roleCode;
  final List<UserCompanyInfo> companies;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isActive,
    this.photoUrl = '',
    this.createBy,
    this.createAt,
    this.createByName,
    this.updateBy,
    this.updateAt,
    this.updateByName,
    this.roleId,
    required this.roleCode,
    this.companies = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    var companiesList = <UserCompanyInfo>[];
    if (json['companies'] != null) {
      final List<dynamic> list = json['companies'];
      companiesList = list
          .map((item) => UserCompanyInfo.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: (json['email'] as String?) ?? '',
      firstName: (json['first_name'] as String?) ?? '',
      lastName: (json['last_name'] as String?) ?? '',
      isActive: (json['is_active'] as bool?) ?? false,
      photoUrl: json['photo_url'] as String? ?? '',
      createBy: json['create_by'] as int?,
      createAt: json['create_at']?.toString(),
      createByName: json['create_by_name']?.toString(),
      updateBy: json['update_by'] as int?,
      updateAt: json['update_at']?.toString(),
      updateByName: json['update_by_name']?.toString(),
      roleId: json['role_id'] as int?,
      roleCode: (json['role_code'] as String?) ?? '',
      companies: companiesList,
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}

/// Helper model for user companies representation.
class UserCompanyInfo {
  final int id;
  final String name;
  final String photoUrl;

  UserCompanyInfo({required this.id, required this.name, this.photoUrl = ''});

  factory UserCompanyInfo.fromJson(Map<String, dynamic> json) {
    return UserCompanyInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      photoUrl: json['photo_url'] as String? ?? '',
    );
  }
}

/// Payload for creating a new user.
class CreateUserRequest {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final int? roleId;
  final List<int> companyIds;

  CreateUserRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.roleId,
    this.companyIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        if (roleId != null) 'role_id': roleId,
        'company_ids': companyIds,
      };
}

/// Payload for updating an existing user.
class UpdateUserRequest {
  final String? email;
  final String? password;
  final String? firstName;
  final String? lastName;
  final bool? isActive;
  final int? roleId;
  final List<int>? companyIds;
  final String? photoUrl;

  UpdateUserRequest({
    this.email,
    this.password,
    this.firstName,
    this.lastName,
    this.isActive,
    this.roleId,
    this.companyIds,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (email != null) map['email'] = email;
    if (password != null && password!.isNotEmpty) map['password'] = password;
    if (firstName != null) map['first_name'] = firstName;
    if (lastName != null) map['last_name'] = lastName;
    if (isActive != null) map['is_active'] = isActive;
    if (roleId != null) map['role_id'] = roleId;
    if (companyIds != null) map['company_ids'] = companyIds;
    if (photoUrl != null) map['photo_url'] = photoUrl;
    return map;
  }
}
