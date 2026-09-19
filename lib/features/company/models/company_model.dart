class Company {
  final int id;
  final String name;
  final bool isActive;
  final String photoUrl;
  final int? createBy;
  final String? createAt;
  final String? createByName;
  final int? updateBy;
  final String? updateAt;
  final String? updateByName;
  final int nit;
  final String? razonSocial;
  final String suscripcionEstado;
  final String? fechaFinPrueba;
  final String? codigoEmpresa;

  Company({
    required this.id,
    required this.name,
    required this.nit,
    required this.isActive,
    this.photoUrl = '',
    this.createBy,
    this.createAt,
    this.createByName,
    this.updateBy,
    this.updateAt,
    this.updateByName,
    this.razonSocial,
    this.suscripcionEstado = 'prueba',
    this.fechaFinPrueba,
    this.codigoEmpresa,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      isActive: (json['is_active'] as bool?) ?? true,
      photoUrl: json['photo_url'] as String? ?? '',
      createBy: (json['create_by'] as num?)?.toInt(),
      createAt: json['create_at']?.toString(),
      createByName: json['create_by_name']?.toString(),
      updateBy: (json['update_by'] as num?)?.toInt(),
      updateAt: json['update_at']?.toString(),
      updateByName: json['update_by_name']?.toString(),
      nit: (json['nit'] as num?)?.toInt() ?? 0,
      razonSocial: json['razon_social']?.toString(),
      suscripcionEstado: (json['suscripcion_estado'] as String?) ?? 'prueba',
      fechaFinPrueba: json['fecha_fin_prueba']?.toString(),
      codigoEmpresa: json['codigo_empresa'] as String?,
    );
  }
}

class CreateCompanyRequest {
  final String name;
  final String photoUrl;
  final String? razonSocial;
  final int? nit;
  final String? validatorEmail;
  final String? validatorPassword;
  final String? validatorFirstName;
  final String? validatorLastName;

  CreateCompanyRequest({
    required this.name,
    this.photoUrl = '',
    this.razonSocial,
    this.nit,
    this.validatorEmail,
    this.validatorPassword,
    this.validatorFirstName,
    this.validatorLastName,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'photo_url': photoUrl,
    'razon_social': razonSocial,
    'nit': nit,
    if (validatorEmail != null && validatorEmail!.isNotEmpty) 'validator_email': validatorEmail,
    if (validatorPassword != null && validatorPassword!.isNotEmpty) 'validator_password': validatorPassword,
    if (validatorFirstName != null && validatorFirstName!.isNotEmpty) 'validator_first_name': validatorFirstName,
    if (validatorLastName != null && validatorLastName!.isNotEmpty) 'validator_last_name': validatorLastName,
  };
}

class UpdateCompanyRequest {
  final String? name;
  final int nit;
  final bool? isActive;
  final String? photoUrl;
  final String? razonSocial;

  UpdateCompanyRequest({
    this.name,
    required this.nit,
    this.isActive,
    this.photoUrl,
    this.razonSocial,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    map['nit'] = nit;
    if (isActive != null) map['is_active'] = isActive;
    if (photoUrl != null) map['photo_url'] = photoUrl;
    if (razonSocial != null) map['razon_social'] = razonSocial;
    return map;
  }
}
