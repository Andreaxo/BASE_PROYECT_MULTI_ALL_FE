import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../models/benefit_model.dart';

class BenefitApiService {
  static Future<List<Benefit>> getAll() async {
    final response = await ApiService.get(ApiConfig.benefitsEndpoint);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded == null) return [];
      final List<dynamic> data = decoded is List ? decoded : [];
      return data
          .map((json) => Benefit.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load benefits');
    }
  }

  static Future<List<Benefit>> getMyCompanyBenefits() async {
    final response = await ApiService.get('${ApiConfig.benefitsEndpoint}/my-company');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded == null) return [];
      final List<dynamic> data = decoded is List ? decoded : [];
      return data
          .map((json) => Benefit.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load company benefits');
    }
  }

  static Future<Benefit> getById(int id) async {
    final response = await ApiService.get('${ApiConfig.benefitsEndpoint}/$id');

    if (response.statusCode == 200) {
      return Benefit.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Benefit not found');
    }
  }

  static Future<Benefit> create(CreateBenefitRequest request) async {
    final response = await ApiService.post(
      ApiConfig.benefitsEndpoint,
      request.toJson(),
    );

    if (response.statusCode == 201) {
      return Benefit.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to create benefit');
    }
  }

  static Future<Benefit> update(int id, UpdateBenefitRequest request) async {
    final response = await ApiService.put(
      '${ApiConfig.benefitsEndpoint}/$id',
      request.toJson(),
    );

    if (response.statusCode == 200) {
      return Benefit.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to update benefit');
    }
  }

  static Future<void> delete(int id) async {
    final response = await ApiService.delete(
      '${ApiConfig.benefitsEndpoint}/$id',
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to delete benefit');
    }
  }
}
