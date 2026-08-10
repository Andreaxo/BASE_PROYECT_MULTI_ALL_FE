import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../models/redemption_model.dart';

class RedemptionApiService {
  /// Generate a redemption code for an employee (POST /api/benefits/:id/redeem).
  static Future<BenefitRedemption> redeem(int benefitId) async {
    final response = await ApiService.post(
      '${ApiConfig.redeemBenefitEndpoint}/$benefitId/redeem',
      {},
    );

    if (response.statusCode == 201) {
      return BenefitRedemption.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'No se pudo redimir el beneficio');
    }
  }

  /// Get employee's redemption history (GET /api/benefits/mis-redenciones).
  static Future<List<BenefitRedemption>> getMyRedemptions() async {
    final response = await ApiService.get(ApiConfig.myRedemptionsEndpoint);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded == null) return [];
      final List<dynamic> data = decoded is List ? decoded : [];
      return data
          .map((json) => BenefitRedemption.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error al cargar mis redenciones');
    }
  }

  /// Validate a redemption code for a business user (POST /api/redemptions/validate).
  static Future<ValidateCodeResponse> validateCode(String code) async {
    final request = ValidateCodeRequest(codigoValidacion: code);
    final response = await ApiService.post(
      ApiConfig.validateRedemptionEndpoint,
      request.toJson(),
    );

    if (response.statusCode == 200) {
      return ValidateCodeResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Error al validar el código');
    }
  }

  /// Get business's company redemption history (GET /api/redemptions).
  static Future<List<BenefitRedemption>> getCompanyRedemptions() async {
    final response = await ApiService.get(ApiConfig.companyRedemptionsEndpoint);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded == null) return [];
      final List<dynamic> data = decoded is List ? decoded : [];
      return data
          .map((json) => BenefitRedemption.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error al cargar las redenciones de la empresa');
    }
  }

  /// Get all redemptions for platform admin (GET /api/admin/redemptions).
  static Future<List<BenefitRedemption>> getAllRedemptions() async {
    final response = await ApiService.get(ApiConfig.adminRedemptionsEndpoint);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded == null) return [];
      final List<dynamic> data = decoded is List ? decoded : [];
      return data
          .map((json) => BenefitRedemption.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error al cargar redenciones globales');
    }
  }
}
