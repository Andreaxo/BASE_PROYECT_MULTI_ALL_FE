import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../models/membresia_model.dart';

class MembresiaApiService {
  /// Get membership status for current authenticated user
  static Future<MembresiaModel> getMiMembresia() async {
    final response = await ApiService.get(ApiConfig.miMembresiaEndpoint);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return MembresiaModel.fromJson(data);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al obtener membresía');
    }
  }

  /// Start payment with Wompi
  static Future<IniciarPagoResponse> iniciarPago(String redirectUrl) async {
    final response = await ApiService.post(
      ApiConfig.iniciarPagoMembresiaEndpoint,
      {'redirect_url': redirectUrl},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return IniciarPagoResponse.fromJson(data);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al iniciar pago en Wompi');
    }
  }

  /// Cancel automatic renewal
  static Future<MembresiaModel> cancelarRenovacion() async {
    final response = await ApiService.put(
      ApiConfig.cancelarRenovacionMembresiaEndpoint,
      {},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return MembresiaModel.fromJson(data);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al cancelar renovación automática');
    }
  }

  /// Get all memberships (admin)
  static Future<List<MembresiaModel>> getAllMembresias() async {
    final response = await ApiService.get(ApiConfig.adminMembresiasEndpoint);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => MembresiaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al cargar membresías');
    }
  }

  /// Simulate approved or declined payment in sandbox
  static Future<MembresiaModel> simularPago(String status) async {
    final response = await ApiService.post(
      ApiConfig.simularPagoMembresiaEndpoint,
      {'status': status},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return MembresiaModel.fromJson(data);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al simular pago');
    }
  }
}
