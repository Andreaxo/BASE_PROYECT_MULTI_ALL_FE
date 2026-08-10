/// Models for Benefit Redemption.

class BenefitRedemption {
  final int id;
  final int benefitId;
  final String benefitName;
  final String codigoValidacion;
  final String estado; // 'generado', 'usado', 'vencido'
  final DateTime? fechaRedencion;
  final DateTime? fechaUso;
  final int? validadoPor;

  BenefitRedemption({
    required this.id,
    required this.benefitId,
    required this.benefitName,
    required this.codigoValidacion,
    required this.estado,
    this.fechaRedencion,
    this.fechaUso,
    this.validadoPor,
  });

  factory BenefitRedemption.fromJson(Map<String, dynamic> json) {
    return BenefitRedemption(
      id: (json['id'] as num?)?.toInt() ?? 0,
      benefitId: (json['benefit_id'] as num?)?.toInt() ?? 0,
      benefitName: (json['benefit_name'] as String?) ?? '',
      codigoValidacion: (json['codigo_validacion'] as String?) ?? '',
      estado: (json['estado'] as String?) ?? 'generado',
      fechaRedencion: json['fecha_redencion'] != null
          ? DateTime.tryParse(json['fecha_redencion'].toString())
          : null,
      fechaUso: json['fecha_uso'] != null
          ? DateTime.tryParse(json['fecha_uso'].toString())
          : null,
      validadoPor: (json['validado_por'] as num?)?.toInt(),
    );
  }
}

class ValidateCodeRequest {
  final String codigoValidacion;

  ValidateCodeRequest({required this.codigoValidacion});

  Map<String, dynamic> toJson() => {
        'codigo_validacion': codigoValidacion,
      };
}

class ValidateCodeResponse {
  final int id;
  final String benefitName;
  final String usuarioNombre;
  final String estado;
  final DateTime? fechaUso;

  ValidateCodeResponse({
    required this.id,
    required this.benefitName,
    required this.usuarioNombre,
    required this.estado,
    this.fechaUso,
  });

  factory ValidateCodeResponse.fromJson(Map<String, dynamic> json) {
    return ValidateCodeResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      benefitName: (json['benefit_name'] as String?) ?? '',
      usuarioNombre: (json['usuario_nombre'] as String?) ?? '',
      estado: (json['estado'] as String?) ?? 'usado',
      fechaUso: json['fecha_uso'] != null
          ? DateTime.tryParse(json['fecha_uso'].toString())
          : null,
    );
  }
}
