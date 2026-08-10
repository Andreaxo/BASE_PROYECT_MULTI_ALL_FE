/// Models and DTOs for the Rifas module.

class Rifa {
  final int id;
  final String nombre;
  final String? descripcion;
  final String premio;
  final String? imagenUrl;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final DateTime fechaSorteo;
  final String estado; // 'activa', 'cerrada', 'sorteada', 'cancelada'
  final int? createBy;
  final DateTime createAt;
  final int? updateBy;
  final DateTime? updateAt;

  Rifa({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.premio,
    this.imagenUrl,
    required this.fechaInicio,
    required this.fechaFin,
    required this.fechaSorteo,
    required this.estado,
    this.createBy,
    required this.createAt,
    this.updateBy,
    this.updateAt,
  });

  factory Rifa.fromJson(Map<String, dynamic> json) {
    return Rifa(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: (json['nombre'] as String?) ?? '',
      descripcion: json['descripcion']?.toString(),
      premio: (json['premio'] as String?) ?? '',
      imagenUrl: json['imagen_url']?.toString(),
      fechaInicio: json['fecha_inicio'] != null
          ? (DateTime.tryParse(json['fecha_inicio'].toString()) ?? DateTime.now())
          : DateTime.now(),
      fechaFin: json['fecha_fin'] != null
          ? (DateTime.tryParse(json['fecha_fin'].toString()) ?? DateTime.now())
          : DateTime.now(),
      fechaSorteo: json['fecha_sorteo'] != null
          ? (DateTime.tryParse(json['fecha_sorteo'].toString()) ?? DateTime.now())
          : DateTime.now(),
      estado: (json['estado'] as String?) ?? 'activa',
      createBy: (json['create_by'] as num?)?.toInt(),
      createAt: json['create_at'] != null
          ? (DateTime.tryParse(json['create_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updateBy: (json['update_by'] as num?)?.toInt(),
      updateAt: json['update_at'] != null
          ? DateTime.tryParse(json['update_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'premio': premio,
      'imagen_url': imagenUrl,
      'fecha_inicio': fechaInicio.toIso8601String().split('T').first,
      'fecha_fin': fechaFin.toIso8601String().split('T').first,
      'fecha_sorteo': fechaSorteo.toIso8601String().split('T').first,
      'estado': estado,
      'create_by': createBy,
      'create_at': createAt.toIso8601String(),
      'update_by': updateBy,
      'update_at': updateAt?.toIso8601String(),
    };
  }

  String get estadoLabel {
    switch (estado) {
      case 'activa':
        return 'Activa';
      case 'cerrada':
        return 'Cerrada';
      case 'sorteada':
        return 'Sorteada';
      case 'cancelada':
        return 'Cancelada';
      default:
        return estado;
    }
  }

  bool get isActiva => estado == 'activa';
  bool get isCerrada => estado == 'cerrada';
  bool get isSorteada => estado == 'sorteada';
  bool get isCancelada => estado == 'cancelada';
}

class ParticipacionRifa {
  final int id;
  final int rifaId;
  final int usuarioId;
  final String nombreUsuario;
  final String numeroParticipacion;
  final String origen; // 'afiliacion', 'referido', 'beneficio', 'manual'
  final DateTime fechaParticipacion;

  ParticipacionRifa({
    required this.id,
    required this.rifaId,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.numeroParticipacion,
    required this.origen,
    required this.fechaParticipacion,
  });

  factory ParticipacionRifa.fromJson(Map<String, dynamic> json) {
    return ParticipacionRifa(
      id: (json['id'] as num?)?.toInt() ?? 0,
      rifaId: (json['rifa_id'] as num?)?.toInt() ?? 0,
      usuarioId: (json['usuario_id'] as num?)?.toInt() ?? 0,
      nombreUsuario: (json['nombre_usuario'] as String?) ?? '',
      numeroParticipacion: (json['numero_participacion'] as String?) ?? '',
      origen: (json['origen'] as String?) ?? 'manual',
      fechaParticipacion: json['fecha_participacion'] != null
          ? (DateTime.tryParse(json['fecha_participacion'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  String get origenLabel {
    switch (origen) {
      case 'afiliacion':
        return 'Afiliación';
      case 'referido':
        return 'Referido';
      case 'beneficio':
        return 'Beneficio';
      case 'manual':
        return 'Manual';
      default:
        return origen;
    }
  }
}

class GanadorRifa {
  final int id;
  final int rifaId;
  final int participacionId;
  final String numeroParticipacion;
  final int usuarioId;
  final String nombreGanador;
  final DateTime? fechaNotificacion;
  final String estadoEntrega; // 'pendiente', 'notificado', 'entregado'

  GanadorRifa({
    required this.id,
    required this.rifaId,
    required this.participacionId,
    required this.numeroParticipacion,
    required this.usuarioId,
    required this.nombreGanador,
    this.fechaNotificacion,
    required this.estadoEntrega,
  });

  factory GanadorRifa.fromJson(Map<String, dynamic> json) {
    return GanadorRifa(
      id: (json['id'] as num?)?.toInt() ?? 0,
      rifaId: (json['rifa_id'] as num?)?.toInt() ?? 0,
      participacionId: (json['participacion_id'] as num?)?.toInt() ?? 0,
      numeroParticipacion: (json['numero_participacion'] as String?) ?? '',
      usuarioId: (json['usuario_id'] as num?)?.toInt() ?? 0,
      nombreGanador: (json['nombre_ganador'] as String?) ?? '',
      fechaNotificacion: json['fecha_notificacion'] != null
          ? DateTime.tryParse(json['fecha_notificacion'].toString())
          : null,
      estadoEntrega: (json['estado_entrega'] as String?) ?? 'pendiente',
    );
  }

  String get estadoEntregaLabel {
    switch (estadoEntrega) {
      case 'pendiente':
        return 'Pendiente';
      case 'notificado':
        return 'Notificado';
      case 'entregado':
        return 'Entregado';
      default:
        return estadoEntrega;
    }
  }
}

class RifaHistorialItem {
  final Rifa rifa;
  final List<GanadorRifa> ganadores;

  RifaHistorialItem({
    required this.rifa,
    required this.ganadores,
  });

  factory RifaHistorialItem.fromJson(Map<String, dynamic> json) {
    final List<dynamic> ganadoresJson = json['ganadores'] as List<dynamic>? ?? [];
    final rifaMap = json['rifa'] != null ? (json['rifa'] as Map<String, dynamic>) : json;
    return RifaHistorialItem(
      rifa: Rifa.fromJson(rifaMap),
      ganadores: ganadoresJson
          .map((g) => GanadorRifa.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }
}

// --- Request DTOs ---

class CreateRifaRequest {
  final String nombre;
  final String? descripcion;
  final String premio;
  final String? imagenUrl;
  final String fechaInicio; // YYYY-MM-DD
  final String fechaFin; // YYYY-MM-DD
  final String fechaSorteo; // YYYY-MM-DD

  CreateRifaRequest({
    required this.nombre,
    this.descripcion,
    required this.premio,
    this.imagenUrl,
    required this.fechaInicio,
    required this.fechaFin,
    required this.fechaSorteo,
  });

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        if (descripcion != null && descripcion!.isNotEmpty)
          'descripcion': descripcion,
        'premio': premio,
        if (imagenUrl != null && imagenUrl!.isNotEmpty) 'imagen_url': imagenUrl,
        'fecha_inicio': fechaInicio,
        'fecha_fin': fechaFin,
        'fecha_sorteo': fechaSorteo,
      };
}

class UpdateRifaRequest {
  final String? nombre;
  final String? descripcion;
  final String? premio;
  final String? imagenUrl;
  final String? fechaInicio;
  final String? fechaFin;
  final String? fechaSorteo;

  UpdateRifaRequest({
    this.nombre,
    this.descripcion,
    this.premio,
    this.imagenUrl,
    this.fechaInicio,
    this.fechaFin,
    this.fechaSorteo,
  });

  Map<String, dynamic> toJson() => {
        if (nombre != null) 'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (premio != null) 'premio': premio,
        if (imagenUrl != null) 'imagen_url': imagenUrl,
        if (fechaInicio != null) 'fecha_inicio': fechaInicio,
        if (fechaFin != null) 'fecha_fin': fechaFin,
        if (fechaSorteo != null) 'fecha_sorteo': fechaSorteo,
      };
}

class AgregarParticipacionManualRequest {
  final int usuarioId;

  AgregarParticipacionManualRequest({required this.usuarioId});

  Map<String, dynamic> toJson() => {
        'usuario_id': usuarioId,
      };
}

class RegistrarGanadorRequest {
  final int participacionId;

  RegistrarGanadorRequest({required this.participacionId});

  Map<String, dynamic> toJson() => {
        'participacion_id': participacionId,
      };
}

class ActualizarEntregaRequest {
  final String estadoEntrega;

  ActualizarEntregaRequest({required this.estadoEntrega});

  Map<String, dynamic> toJson() => {
        'estado_entrega': estadoEntrega,
      };
}
