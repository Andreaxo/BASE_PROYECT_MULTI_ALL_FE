import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../models/referido_model.dart';

/// Service for referidos API calls.
class ReferidoApiService {
  /// Get all referidos (admin endpoint).
  static Future<List<Referido>> getAll() async {
    final response = await ApiService.get(ApiConfig.referidosEndpoint);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => Referido.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error al cargar referidos');
    }
  }

  /// Get referidos for the authenticated user (mis-referidos).
  static Future<List<Referido>> getMisReferidos() async {
    final response = await ApiService.get(ApiConfig.misReferidosEndpoint);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => Referido.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['error'] != null) {
          throw Exception(body['error'].toString());
        }
      } catch (e) {
        if (e is! FormatException) rethrow;
      }
      throw Exception('Error al cargar mis referidos');
    }
  }

  /// Get the authenticated user's own referral code.
  static Future<String> getMyCodeRefer() async {
    final response = await ApiService.get(ApiConfig.myCodeReferEndpoint);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (body['code_refer'] as String?) ?? '';
    } else {
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['error'] != null) {
          throw Exception(body['error'].toString());
        }
      } catch (e) {
        if (e is! FormatException) rethrow;
      }
      throw Exception('Error al obtener código de referido');
    }
  }

  /// Create a new referral invitation.
  static Future<Referido> create(CreateReferidoRequest request) async {
    final response = await ApiService.post(
      ApiConfig.referidosEndpoint,
      request.toJson(),
    );

    if (response.statusCode == 201) {
      return Referido.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Error al crear referido');
    }
  }

  /// Get a referido by ID.
  static Future<Referido> getById(int id) async {
    final response =
        await ApiService.get('${ApiConfig.referidosEndpoint}/$id');

    if (response.statusCode == 200) {
      return Referido.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Referido no encontrado');
    }
  }

  /// Mark a referido as 'afiliado' (admin action).
  static Future<Referido> afiliar(int id) async {
    final response = await ApiService.put(
      '${ApiConfig.referidosEndpoint}/$id/afiliar',
      {},
    );

    if (response.statusCode == 200) {
      return Referido.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Error al afiliar referido');
    }
  }

  /// Grant reward for an affiliated referido (admin action).
  static Future<Referido> otorgarRecompensa(int id) async {
    final response = await ApiService.put(
      '${ApiConfig.referidosEndpoint}/$id/recompensa',
      {},
    );

    if (response.statusCode == 200) {
      return Referido.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Error al otorgar recompensa');
    }
  }

  /// Delete a referido (admin action).
  static Future<void> delete(int id) async {
    final response = await ApiService.delete(
      '${ApiConfig.referidosEndpoint}/$id',
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Error al eliminar referido');
    }
  }
}
