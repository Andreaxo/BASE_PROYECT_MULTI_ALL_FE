class Category {
  final int id;
  final int companyId;
  final String name;
  final bool isActive;
  final String? createAt;

  Category({
    required this.id,
    required this.companyId,
    required this.name,
    required this.isActive,
    this.createAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      companyId: json['company_id'] as int,
      name: json['name'] as String,
      isActive: json['is_active'] as bool,
      createAt: json['create_at'] as String?,
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
