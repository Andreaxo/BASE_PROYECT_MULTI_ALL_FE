import 'category_model.dart';

class Article {
  final int id;
  final int companyId;
  final int categoryId;
  final Category? category;
  final String name;
  final int? createBy;
  final String? createAt;
  final String? createByName;
  final int? updateBy;
  final String? updateAt;
  final String? updateByName;

  Article({
    required this.id,
    required this.companyId,
    required this.categoryId,
    this.category,
    required this.name,
    this.createBy,
    this.createAt,
    this.createByName,
    this.updateBy,
    this.updateAt,
    this.updateByName,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as int,
      companyId: json['company_id'] as int,
      categoryId: json['category_id'] as int,
      category: json['category'] != null
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      name: json['name'] as String,
      createBy: json['create_by'] as int?,
      createAt: json['create_at']?.toString(),
      createByName: json['create_by_name']?.toString(),
      updateBy: json['update_by'] as int?,
      updateAt: json['update_at']?.toString(),
      updateByName: json['update_by_name']?.toString(),
    );
  }
}

class CreateArticleRequest {
  final int categoryId;
  final String name;

  CreateArticleRequest({
    required this.categoryId,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
        'category_id': categoryId,
        'name': name,
      };
}

class UpdateArticleRequest {
  final int? categoryId;
  final String? name;

  UpdateArticleRequest({
    this.categoryId,
    this.name,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (categoryId != null) map['category_id'] = categoryId;
    if (name != null) map['name'] = name;
    return map;
  }
}
