import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../models/notificacion_model.dart';

class NotificacionService {
  /// Obtiene la lista de notificaciones del usuario autenticado
  Future<List<NotificacionModel>> getNotificaciones({int limit = 20, int offset = 0}) async {
    final response = await ApiService.get(
      '${ApiConfig.notificacionesEndpoint}?limit=$limit&offset=$offset',
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> data = json['data'] as List<dynamic>? ?? [];
      return data.map((item) => NotificacionModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Obtiene el conteo de notificaciones no leídas
  Future<int> getCountNoLeidas() async {
    final response = await ApiService.get(
      ApiConfig.notificacionesNoLeidasCountEndpoint,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return json['count'] as int? ?? 0;
    }
    return 0;
  }

  /// Marca una notificación específica como leída
  Future<bool> marcarLeida(int id) async {
    final response = await ApiService.put(
      '${ApiConfig.notificacionesEndpoint}/$id/leido',
      {},
    );
    return response.statusCode == 200;
  }

  /// Marca todas las notificaciones pendientes como leídas
  Future<bool> marcarTodasLeidas() async {
    final response = await ApiService.put(
      ApiConfig.notificacionesMarcarTodasLeidasEndpoint,
      {},
    );
    return response.statusCode == 200;
  }
}
