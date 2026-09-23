class MembresiaModel {
  final int id;
  final int usuarioId;
  final String estado; // 'activa', 'inactiva', 'vencida', 'cancelada'
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool renovacionAutomatica;
  final bool tieneMetodoPago;
  final DateTime? createAt;
  final String? ultimoPagoEstado;

  MembresiaModel({
    required this.id,
    required this.usuarioId,
    required this.estado,
    this.fechaInicio,
    this.fechaFin,
    required this.renovacionAutomatica,
    required this.tieneMetodoPago,
    this.createAt,
    this.ultimoPagoEstado,
  });

  bool get isActiva => estado.toLowerCase() == 'activa';
  bool get isInactiva => estado.toLowerCase() == 'inactiva';
  bool get isVencida => estado.toLowerCase() == 'vencida';
  bool get isCancelada => estado.toLowerCase() == 'cancelada';
  bool get isUltimoPagoRechazado {
    final s = ultimoPagoEstado?.toLowerCase();
    return s == 'rechazado' ||
        s == 'declined' ||
        s == 'error' ||
        s == 'voided' ||
        s == 'fallido';
  }

  bool get isUltimoPagoAprobado {
    final s = ultimoPagoEstado?.toLowerCase();
    return s == 'aprobado' || s == 'approved';
  }

  bool get isUltimoPagoPendiente {
    final s = ultimoPagoEstado?.toLowerCase();
    return s == 'pendiente' || s == 'pending';
  }

  int get diasRestantes {
    if (fechaFin == null) return 0;
    final diff = fechaFin!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  factory MembresiaModel.fromJson(Map<String, dynamic> json) {
    return MembresiaModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      usuarioId: json['usuario_id'] is int
          ? json['usuario_id']
          : (int.tryParse(json['usuario_id']?.toString() ?? '0') ?? 0),
      estado: json['estado']?.toString() ?? 'inactiva',
      fechaInicio: json['fecha_inicio'] != null
          ? DateTime.tryParse(json['fecha_inicio'].toString())
          : null,
      fechaFin: json['fecha_fin'] != null
          ? DateTime.tryParse(json['fecha_fin'].toString())
          : null,
      renovacionAutomatica: json['renovacion_automatica'] == true,
      tieneMetodoPago: json['tiene_metodo_pago'] == true,
      createAt: json['create_at'] != null
          ? DateTime.tryParse(json['create_at'].toString())
          : null,
      ultimoPagoEstado: json['ultimo_pago_estado']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'estado': estado,
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'renovacion_automatica': renovacionAutomatica,
      'tiene_metodo_pago': tieneMetodoPago,
      'create_at': createAt?.toIso8601String(),
    };
  }
}

class IniciarPagoResponse {
  final String transactionId;
  final String checkoutUrl;
  final String referencia;

  IniciarPagoResponse({
    required this.transactionId,
    required this.checkoutUrl,
    required this.referencia,
  });

  factory IniciarPagoResponse.fromJson(Map<String, dynamic> json) {
    return IniciarPagoResponse(
      transactionId: json['transaction_id']?.toString() ?? '',
      checkoutUrl: json['checkout_url']?.toString() ?? '',
      referencia: json['referencia']?.toString() ?? '',
    );
  }
}
