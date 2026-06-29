import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../models/role_model.dart';

class RoleApiService {
  static Future<List<Role>> getAll() async {
    final response = await ApiService.get(ApiConfig.rolesEndpoint);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => Role.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load roles');
    }
  }

  static Future<Role> getById(int id) async {
    final response = await ApiService.get('${ApiConfig.rolesEndpoint}/$id');

    if (response.statusCode == 200) {
      return Role.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Role not found');
    }
  }

  static Future<Role> create(CreateRoleRequest request) async {
    final response = await ApiService.post(
      ApiConfig.rolesEndpoint,
      request.toJson(),
    );

    if (response.statusCode == 201) {
      return Role.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to create role');
    }
  }

  static Future<Role> update(int id, UpdateRoleRequest request) async {
    final response = await ApiService.put(
      '${ApiConfig.rolesEndpoint}/$id',
      request.toJson(),
    );

    if (response.statusCode == 200) {
      return Role.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to update role');
    }
  }

  static Future<void> delete(int id) async {
    final response =
        await ApiService.delete('${ApiConfig.rolesEndpoint}/$id');

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to delete role');
    }
  }

  static Future<List<OptionModel>> getOptions() async {
    final response = await ApiService.get('${ApiConfig.rolesEndpoint}/options');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => OptionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load permission options');
    }
  }
}
