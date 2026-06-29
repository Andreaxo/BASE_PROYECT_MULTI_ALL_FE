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

  static Future<void> delete(int id) async {
    final response =
        await ApiService.delete('${ApiConfig.companiesEndpoint}/$id');

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to delete company');
    }
  }
}
