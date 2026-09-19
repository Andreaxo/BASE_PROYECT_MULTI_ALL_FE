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
      return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to load user profile');
    }
  }

  /// Register a new user with optional referral code and company code.
  static Future<LoginResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? refCode,
    String? codigoEmpresa,
  }) async {
    final response = await ApiService.post(ApiConfig.registerEndpoint, {
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      if (refCode != null && refCode.trim().isNotEmpty)
        'ref_code': refCode.trim(),
      if (codigoEmpresa != null && codigoEmpresa.trim().isNotEmpty)
        'codigo_empresa': codigoEmpresa.trim(),
    }, requiresAuth: false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return LoginResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Falló el registro');
    }
  }

  /// Validate a company code in real-time.
  static Future<Map<String, dynamic>> validarCodigoEmpresa(String codigo) async {
    final response = await ApiService.get(
      '${ApiConfig.baseUrl}/auth/validar-codigo-empresa/${Uri.encodeComponent(codigo.trim())}',
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Código de empresa no válido');
    }
  }

  /// Update own profile details.
  static Future<User> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final response = await ApiService.put('${ApiConfig.baseUrl}/auth/profile', {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
    });
    print("DEBUG updateProfile response status: ${response.statusCode}");
    print("DEBUG updateProfile response body: ${response.body}");
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Error al actualizar el perfil');
    }
  }
}
