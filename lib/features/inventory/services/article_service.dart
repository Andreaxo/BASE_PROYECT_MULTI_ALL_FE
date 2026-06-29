import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../models/article_model.dart';

class ArticleApiService {
  static Future<List<Article>> getAll() async {
    final response = await ApiService.get('${ApiConfig.baseUrl}/articles');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((item) => Article.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to load articles');
    }
  }

  static Future<Article> create(CreateArticleRequest request) async {
    final response = await ApiService.post(
      '${ApiConfig.baseUrl}/articles',
      request.toJson(),
    );
    if (response.statusCode == 201) {
      return Article.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to create article');
    }
  }

  static Future<Article> update(int id, UpdateArticleRequest request) async {
    final response = await ApiService.put(
      '${ApiConfig.baseUrl}/articles/$id',
      request.toJson(),
    );
    if (response.statusCode == 200) {
      return Article.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to update article');
    }
  }

  static Future<void> delete(int id) async {
    final response = await ApiService.delete('${ApiConfig.baseUrl}/articles/$id');
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to delete article');
    }
  }
}
