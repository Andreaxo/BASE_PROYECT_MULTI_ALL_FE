import 'dart:convert';
import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../models/rifa_model.dart';

/// API service for the Rifas module.
class RifaApiService {
  // --- User endpoints ---

  /// Get the currently active rifa (public/user endpoint).
  static Future<Rifa?> getActiva() async {
    final response = await ApiService.get('${ApiConfig.rifasEndpoint}/activa');

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return Rifa.fromJson(body);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al obtener rifa activa');
    }
  }

  /// Get the authenticated user's participations in the active rifa.
  static Future<List<ParticipacionRifa>> getMisParticipaciones() async {
    final response = await ApiService.get('${ApiConfig.rifasEndpoint}/mis-participaciones');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => ParticipacionRifa.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al obtener mis participaciones');
    }
  }

  /// User self-joins an active rifa.
  static Future<ParticipacionRifa> participar(int rifaId) async {
    final response = await ApiService.post(
      '${ApiConfig.rifasEndpoint}/$rifaId/participar',
      {},
    );

    if (response.statusCode == 201) {
      return ParticipacionRifa.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al participar en la rifa');
    }
  }

  /// Get past rifas history and winners.
  static Future<List<RifaHistorialItem>> getHistorial() async {
    final response = await ApiService.get('${ApiConfig.rifasEndpoint}/historial');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => RifaHistorialItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al obtener historial de rifas');
    }
  }

  // --- Admin endpoints ---

  /// Get all rifas (admin endpoint).
  static Future<List<Rifa>> getAll() async {
    final response = await ApiService.get(ApiConfig.rifasEndpoint);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => Rifa.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al cargar rifas');
    }
  }

  /// Get a single rifa by ID.
  static Future<Rifa> getById(int id) async {
    final response = await ApiService.get('${ApiConfig.rifasEndpoint}/$id');

    if (response.statusCode == 200) {
      return Rifa.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Rifa no encontrada');
    }
  }

  /// Create a new rifa.
  static Future<Rifa> create(CreateRifaRequest request) async {
    final response = await ApiService.post(
      ApiConfig.rifasEndpoint,
      request.toJson(),
    );

    if (response.statusCode == 201) {
      return Rifa.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al crear la rifa');
    }
  }

  /// Update an existing rifa.
  static Future<Rifa> update(int id, UpdateRifaRequest request) async {
    final response = await ApiService.put(
      '${ApiConfig.rifasEndpoint}/$id',
      request.toJson(),
    );

    if (response.statusCode == 200) {
      return Rifa.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al actualizar la rifa');
    }
  }

  /// Activate a rifa (dispara recompensas de referidos pendientes).
  static Future<Rifa> activar(int id) async {
    final response = await ApiService.put(
      '${ApiConfig.rifasEndpoint}/$id/activar',
      {},
    );

    if (response.statusCode == 200) {
      return Rifa.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al activar la rifa');
    }
  }

  /// Close a rifa.
  static Future<Rifa> cerrar(int id) async {
    final response = await ApiService.put(
      '${ApiConfig.rifasEndpoint}/$id/cerrar',
      {},
    );

    if (response.statusCode == 200) {
      return Rifa.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al cerrar la rifa');
    }
  }

  /// Mark a rifa as drawn.
  static Future<Rifa> sortear(int id) async {
    final response = await ApiService.put(
      '${ApiConfig.rifasEndpoint}/$id/sortear',
      {},
    );

    if (response.statusCode == 200) {
      return Rifa.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al sortear la rifa');
    }
  }

  /// Cancel a rifa.
  static Future<Rifa> cancelar(int id) async {
    final response = await ApiService.put(
      '${ApiConfig.rifasEndpoint}/$id/cancelar',
      {},
    );

    if (response.statusCode == 200) {
      return Rifa.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al cancelar la rifa');
    }
  }

  // --- Participaciones ---

  /// Get all participations for a specific rifa.
  static Future<List<ParticipacionRifa>> getParticipaciones(int rifaId) async {
    final response = await ApiService.get('${ApiConfig.rifasEndpoint}/$rifaId/participaciones');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => ParticipacionRifa.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al obtener participaciones');
    }
  }

  /// Add a manual participation for a user.
  static Future<ParticipacionRifa> agregarParticipacionManual(
    int rifaId,
    AgregarParticipacionManualRequest request,
  ) async {
    final response = await ApiService.post(
      '${ApiConfig.rifasEndpoint}/$rifaId/participaciones',
      request.toJson(),
    );

    if (response.statusCode == 201) {
      return ParticipacionRifa.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al agregar participación manual');
    }
  }

  // --- Ganadores ---

  /// Get winners of a rifa.
  static Future<List<GanadorRifa>> getGanadores(int rifaId) async {
    final response = await ApiService.get('${ApiConfig.rifasEndpoint}/$rifaId/ganadores');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => GanadorRifa.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al obtener ganadores');
    }
  }

  /// Register a winner for a rifa.
  static Future<GanadorRifa> registrarGanador(
    int rifaId,
    RegistrarGanadorRequest request,
  ) async {
    final response = await ApiService.post(
      '${ApiConfig.rifasEndpoint}/$rifaId/ganador',
      request.toJson(),
    );

    if (response.statusCode == 201) {
      return GanadorRifa.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al registrar ganador');
    }
  }

  /// Update delivery status of a winner.
  static Future<GanadorRifa> actualizarEntrega(
    int ganadorId,
    ActualizarEntregaRequest request,
  ) async {
    final response = await ApiService.put(
      '${ApiConfig.rifasEndpoint}/ganadores/$ganadorId/entrega',
      request.toJson(),
    );

    if (response.statusCode == 200) {
      return GanadorRifa.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(body?['error'] ?? 'Error al actualizar estado de entrega');
    }
  }
}
