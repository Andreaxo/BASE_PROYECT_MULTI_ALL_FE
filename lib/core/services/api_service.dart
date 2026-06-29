import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_storage.dart';

/// Base HTTP service that automatically attaches JWT Bearer token and X-Company-ID headers to requests.
class ApiService {
  /// GET request with auth headers.
  static Future<http.Response> get(String url) async {
    final token = await AuthStorage.getToken();
    final companyId = await AuthStorage.getActiveCompanyId();
    return http.get(
      Uri.parse(url),
      headers: _buildHeaders(token, companyId),
    );
  }

  /// POST request with auth headers and JSON body.
  static Future<http.Response> post(String url, Map<String, dynamic> body,
      {bool requiresAuth = true}) async {
    final token = requiresAuth ? await AuthStorage.getToken() : null;
    final companyId = requiresAuth ? await AuthStorage.getActiveCompanyId() : null;
    return http.post(
      Uri.parse(url),
      headers: _buildHeaders(token, companyId),
      body: jsonEncode(body),
    );
  }

  /// PUT request with auth headers and JSON body.
  static Future<http.Response> put(
      String url, Map<String, dynamic> body) async {
    final token = await AuthStorage.getToken();
    final companyId = await AuthStorage.getActiveCompanyId();
    return http.put(
      Uri.parse(url),
      headers: _buildHeaders(token, companyId),
      body: jsonEncode(body),
    );
  }

  /// DELETE request with auth headers.
  static Future<http.Response> delete(String url) async {
    final token = await AuthStorage.getToken();
    final companyId = await AuthStorage.getActiveCompanyId();
    return http.delete(
      Uri.parse(url),
      headers: _buildHeaders(token, companyId),
    );
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
