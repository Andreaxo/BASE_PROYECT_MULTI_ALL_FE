import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../models/company_model.dart';

class CompanyApiService {
  static Future<List<Company>> getAll() async {
    final response = await ApiService.get(ApiConfig.companiesEndpoint);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => Company.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load companies');
    }
  }

  static Future<Company> getById(int id) async {
    final response = await ApiService.get('${ApiConfig.companiesEndpoint}/$id');

    if (response.statusCode == 200) {
      return Company.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Company not found');
    }
  }

  static Future<Company> create(CreateCompanyRequest request) async {
    final response = await ApiService.post(
      ApiConfig.companiesEndpoint,
      request.toJson(),
    );

    if (response.statusCode == 201) {
      return Company.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to create company');
    }
  }

  static Future<Company> update(int id, UpdateCompanyRequest request) async {
    final response = await ApiService.put(
      '${ApiConfig.companiesEndpoint}/$id',
      request.toJson(),
    );

    if (response.statusCode == 200) {
      return Company.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to update company');
    }
  }

  static Future<void> delete(int id, {bool force = false}) async {
    final uri = force
        ? '${ApiConfig.companiesEndpoint}/$id?force=true'
        : '${ApiConfig.companiesEndpoint}/$id';
    final response = await ApiService.delete(uri);

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? body['message'] ?? 'Failed to delete company');
    }
  }

  static Future<Map<String, dynamic>> checkActiveBenefits(int id) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.companiesEndpoint}/$id/check-benefits',
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {'has_active_benefits': false, 'active_benefits_count': 0};
  }

  static Future<Map<String, dynamic>> solicitarReactivacion() async {
    final response = await ApiService.post(
      '${ApiConfig.companiesEndpoint}/solicitar-reactivacion',
      {},
    );

    Map<String, dynamic> body = {};
    if (response.body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      } catch (_) {
        if (response.statusCode != 200 && response.statusCode != 201) {
          throw Exception('Error del servidor (${response.statusCode}): ${response.body.trim().isNotEmpty ? response.body : "Sin respuesta del servidor. Asegúrate de reiniciar el backend."}');
        }
      }
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return body;
    } else {
      throw Exception(body['error'] ?? body['message'] ?? 'Error al procesar la solicitud (código ${response.statusCode})');
    }
  }
}
