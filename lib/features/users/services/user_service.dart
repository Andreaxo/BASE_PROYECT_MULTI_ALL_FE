import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../models/user_model.dart';

/// Service for user CRUD API calls.
class UserApiService {
  /// Get all users.
  static Future<List<User>> getAll() async {
    final response = await ApiService.get(ApiConfig.usersEndpoint);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  /// Get a single user by ID.
  static Future<User> getById(int id) async {
    final response = await ApiService.get('${ApiConfig.usersEndpoint}/$id');

    if (response.statusCode == 200) {
      return User.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('User not found');
    }
  }

  /// Create a new user.
  static Future<User> create(CreateUserRequest request) async {
    final response = await ApiService.post(
      ApiConfig.usersEndpoint,
      request.toJson(),
    );

    if (response.statusCode == 201) {
      return User.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to create user');
    }
  }

  /// Update an existing user.
  static Future<User> update(int id, UpdateUserRequest request) async {
    final response = await ApiService.put(
      '${ApiConfig.usersEndpoint}/$id',
      request.toJson(),
    );

    if (response.statusCode == 200) {
      return User.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to update user');
    }
  }

  /// Delete a user by ID.
  static Future<void> delete(int id) async {
    final response =
        await ApiService.delete('${ApiConfig.usersEndpoint}/$id');

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to delete user');
    }
  }
}
