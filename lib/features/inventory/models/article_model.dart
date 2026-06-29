import 'category_model.dart';

class Article {
  final int id;
  final int companyId;
  final int categoryId;
  final Category? category;
  final String name;
  final String? createAt;

  Article({
    required this.id,
    required this.companyId,
    required this.categoryId,
    this.category,
    required this.name,
    this.createAt,
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
      createAt: json['create_at'] as String?,
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
