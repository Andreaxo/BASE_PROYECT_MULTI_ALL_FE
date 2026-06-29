import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../models/menu_model.dart';

class MenuApiService {
  static Future<List<MenuModel>> getAll() async {
    final response = await ApiService.get(ApiConfig.menusEndpoint);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => MenuModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load menus');
    }
  }

  static Future<MenuModel> getById(int id) async {
    final response = await ApiService.get('${ApiConfig.menusEndpoint}/$id');

    if (response.statusCode == 200) {
      return MenuModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Menu not found');
    }
  }

  static Future<MenuModel> create(CreateMenuRequest request) async {
    final response = await ApiService.post(
      ApiConfig.menusEndpoint,
      request.toJson(),
    );

    if (response.statusCode == 201) {
      return MenuModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to create menu');
    }
  }

  static Future<MenuModel> update(int id, UpdateMenuRequest request) async {
    final response = await ApiService.put(
      '${ApiConfig.menusEndpoint}/$id',
      request.toJson(),
    );

    if (response.statusCode == 200) {
      return MenuModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to update menu');
    }
  }

  static Future<void> delete(int id) async {
    final response =
        await ApiService.delete('${ApiConfig.menusEndpoint}/$id');

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to delete menu');
    }
  }

  static Future<List<AllowedMenu>> getMyMenus() async {
    final response = await ApiService.get(ApiConfig.myMenusEndpoint);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => AllowedMenu.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load user menus');
    }
  }
}
