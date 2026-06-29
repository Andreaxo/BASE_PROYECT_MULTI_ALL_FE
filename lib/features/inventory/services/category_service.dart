import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../models/category_model.dart';

class CategoryApiService {
  static Future<List<Category>> getAll() async {
    final response = await ApiService.get('${ApiConfig.baseUrl}/categories');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((item) => Category.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to load categories');
    }
  }

  static Future<Category> create(CreateCategoryRequest request) async {
    final response = await ApiService.post(
      '${ApiConfig.baseUrl}/categories',
      request.toJson(),
    );
    if (response.statusCode == 201) {
      return Category.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to create category');
    }
  }

  static Future<Category> update(int id, UpdateCategoryRequest request) async {
    final response = await ApiService.put(
      '${ApiConfig.baseUrl}/categories/$id',
      request.toJson(),
    );
    if (response.statusCode == 200) {
      return Category.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to update category');
    }
  }

  static Future<void> delete(int id) async {
    final response = await ApiService.delete('${ApiConfig.baseUrl}/categories/$id');
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to delete category');
    }
  }
}
