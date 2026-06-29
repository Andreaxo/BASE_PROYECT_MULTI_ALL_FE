import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../../users/models/user_model.dart';
import '../models/login_model.dart';

/// Service for authentication API calls.
class AuthApiService {
  /// Perform login and return the response.
  static Future<LoginResponse> login(LoginRequest request) async {
    final response = await ApiService.post(
      ApiConfig.loginEndpoint,
      request.toJson(),
      requiresAuth: false,
    );

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Login failed');
    }
  }

  /// Get current user profile preloaded with their companies.
  static Future<User> getProfile() async {
    final response = await ApiService.get('${ApiConfig.baseUrl}/auth/profile');
    if (response.statusCode == 200) {
      return User.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to load user profile');
    }
  }
}
