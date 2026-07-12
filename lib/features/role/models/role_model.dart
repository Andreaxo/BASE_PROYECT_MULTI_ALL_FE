class Role {
  final int id;
  final String name;
  final String code;
  final String description;
  final int sessionDays;
  final int sessionHours;
  final int sessionMinutes;
  final bool isActive;
  final List<RolePermission> permissions;
  final int? createBy;
  final String? createAt;
  final String? createByName;
  final int? updateBy;
  final String? updateAt;
  final String? updateByName;

  Role({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.sessionDays,
    required this.sessionHours,
    required this.sessionMinutes,
    required this.isActive,
    this.permissions = const [],
    this.createBy,
    this.createAt,
    this.createByName,
    this.updateBy,
    this.updateAt,
    this.updateByName,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    var permsList = <RolePermission>[];
    if (json['permissions'] != null) {
      final List<dynamic> list = json['permissions'];
      permsList = list
          .map((item) => RolePermission.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return Role(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
      description: json['description']?.toString() ?? '',
      sessionDays: json['session_days'] as int? ?? 0,
      sessionHours: json['session_hours'] as int? ?? 24,
      sessionMinutes: json['session_minutes'] as int? ?? 0,
      isActive: json['is_active'] as bool,
      permissions: permsList,
      createBy: json['create_by'] as int?,
      createAt: json['create_at']?.toString(),
      createByName: json['create_by_name']?.toString(),
      updateBy: json['update_by'] as int?,
      updateAt: json['update_at']?.toString(),
      updateByName: json['update_by_name']?.toString(),
    );
  }
}

class RolePermission {
  final int roleId;
  final int menuId;
  final int optionId;

  RolePermission({
    required this.roleId,
    required this.menuId,
    required this.optionId,
  });

  factory RolePermission.fromJson(Map<String, dynamic> json) {
    return RolePermission(
      roleId: json['role_id'] as int,
      menuId: json['menu_id'] as int,
      optionId: json['option_id'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'role_id': roleId,
        'menu_id': menuId,
        'option_id': optionId,
      };
}

class OptionModel {
  final int id;
  final String name;
  final String code;

  OptionModel({required this.id, required this.name, required this.code});

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    return OptionModel(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }
}

class PermissionRequest {
  final int menuId;
  final int optionId;

  PermissionRequest({required this.menuId, required this.optionId});

  Map<String, dynamic> toJson() => {
        'menu_id': menuId,
        'option_id': optionId,
      };
}

class CreateRoleRequest {
  final String name;
  final String code;
  final String description;
  final int sessionDays;
  final int sessionHours;
  final int sessionMinutes;
  final List<PermissionRequest> permissions;

  CreateRoleRequest({
    required this.name,
    required this.code,
    required this.description,
    required this.sessionDays,
    required this.sessionHours,
    required this.sessionMinutes,
    required this.permissions,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'description': description,
        'session_days': sessionDays,
        'session_hours': sessionHours,
        'session_minutes': sessionMinutes,
        'permissions': permissions.map((p) => p.toJson()).toList(),
      };
}

class UpdateRoleRequest {
  final String? name;
  final String? code;
  final String? description;
  final int? sessionDays;
  final int? sessionHours;
  final int? sessionMinutes;
  final bool? isActive;
  final List<PermissionRequest> permissions;

  UpdateRoleRequest({
    this.name,
    this.code,
    this.description,
    this.sessionDays,
    this.sessionHours,
    this.sessionMinutes,
    this.isActive,
    required this.permissions,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (code != null) map['code'] = code;
    if (description != null) map['description'] = description;
    if (sessionDays != null) map['session_days'] = sessionDays;
    if (sessionHours != null) map['session_hours'] = sessionHours;
    if (sessionMinutes != null) map['session_minutes'] = sessionMinutes;
    if (isActive != null) map['is_active'] = isActive;
    map['permissions'] = permissions.map((p) => p.toJson()).toList();
    return map;
  }
}
