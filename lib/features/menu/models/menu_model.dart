class MenuModel {
  final int id;
  final String label;
  final String labelEn;
  final String labelFr;
  final String route;
  final String icon;
  final bool isActive;
  final int sortOrder;
  final int? parentId;
  final int? createBy;
  final String? createAt;
  final String? createByName;
  final int? updateBy;
  final String? updateAt;
  final String? updateByName;

  MenuModel({
    required this.id,
    required this.label,
    required this.labelEn,
    required this.labelFr,
    required this.route,
    required this.icon,
    required this.isActive,
    required this.sortOrder,
    this.parentId,
    this.createBy,
    this.createAt,
    this.createByName,
    this.updateBy,
    this.updateAt,
    this.updateByName,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      id: json['id'] as int,
      label: json['label'] as String,
      labelEn: json['label_en'] as String,
      labelFr: (json['label_fr'] as String?) ?? '',
      route: json['route'] as String,
      icon: (json['icon'] as String?) ?? '',
      isActive: json['is_active'] as bool,
      sortOrder: json['sort_order'] as int,
      parentId: json['parent_id'] as int?,
      createBy: json['create_by'] as int?,
      createAt: json['create_at']?.toString(),
      createByName: json['create_by_name']?.toString(),
      updateBy: json['update_by'] as int?,
      updateAt: json['update_at']?.toString(),
      updateByName: json['update_by_name']?.toString(),
    );
  }
}

class AllowedMenu {
  final int id;
  final String label;
  final String labelEn;
  final String labelFr;
  final String route;
  final String icon;
  final int sortOrder;
  final int? parentId;
  final List<String> permissions;
  final List<AllowedMenu> submenus;

  AllowedMenu({
    required this.id,
    required this.label,
    required this.labelEn,
    this.labelFr = '',
    required this.route,
    required this.icon,
    required this.sortOrder,
    this.parentId,
    this.permissions = const [],
    this.submenus = const [],
  });

  factory AllowedMenu.fromJson(Map<String, dynamic> json) {
    var subJson = json['submenus'] as List?;
    List<AllowedMenu> subs = [];
    if (subJson != null) {
      subs = subJson.map((s) => AllowedMenu.fromJson(s as Map<String, dynamic>)).toList();
    }

    return AllowedMenu(
      id: json['id'] as int,
      label: json['label'] as String,
      labelEn: json['label_en'] as String,
      labelFr: (json['label_fr'] as String?) ?? '',
      route: json['route'] as String,
      icon: (json['icon'] as String?) ?? '',
      sortOrder: json['sort_order'] as int,
      parentId: json['parent_id'] as int?,
      permissions: List<String>.from(json['permissions'] ?? []),
      submenus: subs,
    );
  }
}

class CreateMenuRequest {
  final String label;
  final String labelEn;
  final String labelFr;
  final String route;
  final String icon;
  final int sortOrder;
  final int? parentId;

  CreateMenuRequest({
    required this.label,
    required this.labelEn,
    required this.labelFr,
    required this.route,
    this.icon = '',
    this.sortOrder = 0,
    this.parentId,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'label_en': labelEn,
        'label_fr': labelFr,
        'route': route,
        'icon': icon,
        'sort_order': sortOrder,
        'parent_id': parentId,
      };
}

class UpdateMenuRequest {
  final String? label;
  final String? labelEn;
  final String? labelFr;
  final String? route;
  final String? icon;
  final bool? isActive;
  final int? sortOrder;
  final int? parentId;

  UpdateMenuRequest({
    this.label,
    this.labelEn,
    this.labelFr,
    this.route,
    this.icon,
    this.isActive,
    this.sortOrder,
    this.parentId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (label != null) map['label'] = label;
    if (labelEn != null) map['label_en'] = labelEn;
    if (labelFr != null) map['label_fr'] = labelFr;
    if (route != null) map['route'] = route;
    if (icon != null) map['icon'] = icon;
    if (isActive != null) map['is_active'] = isActive;
    if (sortOrder != null) map['sort_order'] = sortOrder;
    // Set 0 as parent_id if it's cleared to No Parent
    if (parentId != null) map['parent_id'] = parentId;
    return map;
  }
}
