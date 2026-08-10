class Category {
  final int id;
  final int companyId;
  final String name;
  final bool isActive;
  final int? createBy;
  final String? createAt;
  final String? createByName;
  final int? updateBy;
  final String? updateAt;
  final String? updateByName;

  Category({
    required this.id,
    required this.companyId,
    required this.name,
    required this.isActive,
    this.createBy,
    this.createAt,
    this.createByName,
    this.updateBy,
    this.updateAt,
    this.updateByName,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] as num?)?.toInt() ?? 0,
      companyId: (json['company_id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      isActive: (json['is_active'] as bool?) ?? true,
      createBy: json['create_by'] as int?,
      createAt: json['create_at']?.toString(),
      createByName: json['create_by_name']?.toString(),
      updateBy: json['update_by'] as int?,
      updateAt: json['update_at']?.toString(),
      updateByName: json['update_by_name']?.toString(),
    );
  }
}

class CreateCategoryRequest {
  final String name;

  CreateCategoryRequest({required this.name});

  Map<String, dynamic> toJson() => {'name': name};
}

class UpdateCategoryRequest {
  final String? name;
  final bool? isActive;

  UpdateCategoryRequest({this.name, this.isActive});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (isActive != null) map['is_active'] = isActive;
    return map;
  }
}
