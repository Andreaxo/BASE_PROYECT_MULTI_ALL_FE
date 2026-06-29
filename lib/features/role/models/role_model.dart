class Role {
  final int id;
  final String name;
  final String code;
  final bool isActive;
  final List<RolePermission> permissions;

  Role({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
    this.permissions = const [],
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
      isActive: json['is_active'] as bool,
      permissions: permsList,
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
  final List<PermissionRequest> permissions;

  CreateRoleRequest({
    required this.name,
    required this.code,
    required this.permissions,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'permissions': permissions.map((p) => p.toJson()).toList(),
      };
}

class UpdateRoleRequest {
  final String? name;
  final String? code;
  final bool? isActive;
  final List<PermissionRequest> permissions;

  UpdateRoleRequest({
    this.name,
    this.code,
    this.isActive,
    required this.permissions,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (code != null) map['code'] = code;
    if (isActive != null) map['is_active'] = isActive;
    map['permissions'] = permissions.map((p) => p.toJson()).toList();
    return map;
  }
}
