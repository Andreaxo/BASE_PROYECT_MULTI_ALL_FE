import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../../users/models/user_model.dart';
import '../models/login_model.dart';

/// Custom exception thrown when user account is temporarily locked due to brute force protection.
class AccountLockedException implements Exception {
  final String message;
  final int minutes;
  AccountLockedException({required this.message, this.minutes = 15});
  @override
  String toString() => message;
}

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
      if (response.statusCode == 423 || body['is_locked'] == true) {
        final mins = int.tryParse('${body['minutes'] ?? 15}') ?? 15;
        throw AccountLockedException(
          message: body['error'] ??
              'Tu cuenta ha sido bloqueada temporalmente por 15 minutos debido a múltiples intentos fallidos de inicio de sesión.',
          minutes: mins,
        );
      }
      throw Exception(body['error'] ?? 'Login failed');
    }
  }

  /// Invalidate server session, clear blacklist token and destroy cookies.
  static Future<void> logout() async {
    try {
      await ApiService.post('${ApiConfig.baseUrl}/auth/logout', {});
    } catch (_) {
      // Do not block local logout on network issues
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
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Error al actualizar el perfil');
    }
  }

  /// Request a password reset link by email.
  static Future<String> olvidePassword(String email) async {
    final response = await ApiService.post(
      ApiConfig.olvidePasswordEndpoint,
      {'email': email.trim()},
      requiresAuth: false,
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['message'] ?? 'Solicitud procesada con éxito.';
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Error al solicitar restablecimiento de contraseña');
    }
  }

  /// Verify the 6-digit OTP code received by email. Returns the temporary reset_token.
  static Future<String> verificarCodigo(String email, String codigo) async {
    final response = await ApiService.post(
      ApiConfig.verificarCodigoEndpoint,
      {
        'email': email.trim(),
        'codigo': codigo.trim(),
      },
      requiresAuth: false,
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['reset_token'] ?? '';
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Error al verificar el código');
    }
  }

  /// Set a new password using an activation or reset token.
  static Future<String> resetPassword(String token, String newPassword) async {
    final response = await ApiService.post(
      ApiConfig.resetPasswordEndpoint,
      {
        'token': token.trim(),
        'password': newPassword,
      },
      requiresAuth: false,
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['message'] ?? 'Contraseña actualizada con éxito.';
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Error al actualizar la contraseña');
    }
  }
}
