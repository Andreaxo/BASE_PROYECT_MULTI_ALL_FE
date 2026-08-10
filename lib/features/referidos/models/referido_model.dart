/// Modelo principal de Referido.
/// Representa el evento de referencia/invitación completo.
class Referido {
  final int id;
  final int usuarioReferenteId;
  final String nombreReferente;
  final int? usuarioReferidoId;
  final String nombreReferidoUser;
  final String emailReferido;
  final String? nombreReferido;
  final String estado;
  final String fechaReferido;
  final String? fechaConversion;
  final bool recompensaOtorgada;

  Referido({
    required this.id,
    required this.usuarioReferenteId,
    required this.nombreReferente,
    this.usuarioReferidoId,
    required this.nombreReferidoUser,
    required this.emailReferido,
    this.nombreReferido,
    required this.estado,
    required this.fechaReferido,
    this.fechaConversion,
    required this.recompensaOtorgada,
  });

  factory Referido.fromJson(Map<String, dynamic> json) {
    return Referido(
      id: (json['id'] as num).toInt(),
      usuarioReferenteId: (json['usuario_referente_id'] as num).toInt(),
      nombreReferente: (json['nombre_referente'] as String?) ?? '',
      usuarioReferidoId: json['usuario_referido_id'] as int?,
      nombreReferidoUser: (json['nombre_referido_user'] as String?) ?? '',
      emailReferido: (json['email_referido'] as String?) ?? '',
      nombreReferido: json['nombre_referido'] as String?,
      estado: (json['estado'] as String?) ?? 'pendiente',
      fechaReferido: json['fecha_referido']?.toString() ?? '',
      fechaConversion: json['fecha_conversion']?.toString(),
      recompensaOtorgada: (json['recompensa_otorgada'] as bool?) ?? false,
    );
  }

  /// Returns a human-readable label for the estado.
  String get estadoLabel {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'registrado':
        return 'Registrado';
      case 'afiliado':
        return 'Afiliado';
      default:
        return estado;
    }
  }
}

/// Request payload to create a new referral invitation.
class CreateReferidoRequest {
  final String emailReferido;
  final String? nombreReferido;

  CreateReferidoRequest({
    required this.emailReferido,
    this.nombreReferido,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'email_referido': emailReferido,
    };
    if (nombreReferido != null) {
      map['nombre_referido'] = nombreReferido;
    }
    return map;
  }
}
