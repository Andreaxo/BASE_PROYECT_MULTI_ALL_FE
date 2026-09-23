import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_storage.dart';

/// Base HTTP service that automatically attaches JWT Bearer token and X-Company-ID headers to requests.
class ApiService {
  /// Callback triggered whenever an authenticated request receives HTTP 401 Unauthorized
  /// indicating that the session has expired or the token was revoked.
  static void Function()? onSessionExpired;

  static void _handleResponse(String url, http.Response response) {
    if (response.statusCode == 401 &&
        !url.contains('/auth/login') &&
        !url.contains('/auth/register') &&
        !url.contains('/auth/logout')) {
      onSessionExpired?.call();
    }
  }

  /// GET request with auth headers.
  static Future<http.Response> get(String url) async {
    final token = await AuthStorage.getToken();
    final companyId = await AuthStorage.getActiveCompanyId();
    final response = await http.get(
      Uri.parse(url),
      headers: _buildHeaders(token, companyId),
    );
    _handleResponse(url, response);
    return response;
  }

  /// POST request with auth headers and JSON body.
  static Future<http.Response> post(String url, Map<String, dynamic> body,
      {bool requiresAuth = true}) async {
    final token = requiresAuth ? await AuthStorage.getToken() : null;
    final companyId = requiresAuth ? await AuthStorage.getActiveCompanyId() : null;
    final response = await http.post(
      Uri.parse(url),
      headers: _buildHeaders(token, companyId),
      body: jsonEncode(body),
    );
    _handleResponse(url, response);
    return response;
  }

  /// PUT request with auth headers and JSON body.
  static Future<http.Response> put(
      String url, Map<String, dynamic> body) async {
    final token = await AuthStorage.getToken();
    final companyId = await AuthStorage.getActiveCompanyId();
    final response = await http.put(
      Uri.parse(url),
      headers: _buildHeaders(token, companyId),
      body: jsonEncode(body),
    );
    _handleResponse(url, response);
    return response;
  }

  /// DELETE request with auth headers.
  static Future<http.Response> delete(String url) async {
    final token = await AuthStorage.getToken();
    final companyId = await AuthStorage.getActiveCompanyId();
    final response = await http.delete(
      Uri.parse(url),
      headers: _buildHeaders(token, companyId),
    );
    _handleResponse(url, response);
    return response;
  }

  static Map<String, String> _buildHeaders(String? token, int? companyId) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': ApiConfig.activeLocale,
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (companyId != null) {
      headers['X-Company-ID'] = companyId.toString();
    }
    return headers;
  }
}
