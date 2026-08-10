/// Modelo principal de Benefit.
/// El campo [companyBenefits] almacena el ID de la empresa vinculada.
/// La resolución del nombre de la empresa se hace en el Provider/View
/// consultando el [CompanyProvider] por ese ID.
class Benefit {
  final int id;
  final String name;
  final String description;
  final int companyBenefits; // ID de la empresa vinculada
  final bool isActive;
  final int? createBy;
  final String? createAt;
  final String? createByName;
  final int? updateBy;
  final String? updateAt;
  final String? updateByName;

  Benefit({
    required this.id,
    required this.name,
    required this.description,
    required this.companyBenefits,
    this.isActive = true,
    this.createBy,
    this.createAt,
    this.createByName,
    this.updateBy,
    this.updateAt,
    this.updateByName,
  });

  factory Benefit.fromJson(Map<String, dynamic> json) {
    final estadoStr = (json['estado'] as String?)?.toLowerCase();
    final bool isActiveFromBool = (json['is_active'] as bool?) ?? true;
    final bool isActiveFromEstado = estadoStr == null || estadoStr == '' || estadoStr == 'activo';

    return Benefit(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      companyBenefits: (json['company_benefits'] as num?)?.toInt() ??
          (json['company_benefit'] as num?)?.toInt() ??
          0,
      isActive: isActiveFromBool && isActiveFromEstado,
      createBy: (json['create_by'] as num?)?.toInt(),
      createAt: json['create_at']?.toString(),
      createByName: json['create_by_name']?.toString(),
      updateBy: (json['update_by'] as num?)?.toInt(),
      updateAt: json['update_at']?.toString(),
      updateByName: json['update_by_name']?.toString(),
    );
  }
}

class CreateBenefitRequest {
  final String name;
  final String description;
  final int companyBenefits; // ID de la empresa

  CreateBenefitRequest({
    required this.name,
    required this.description,
    required this.companyBenefits,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'company_benefits': companyBenefits,
  };
}

class UpdateBenefitRequest {
  final String? name;
  final String? description;
  final int? companyBenefits;
  final bool? isActive;

  UpdateBenefitRequest({
    this.name,
    this.description,
    this.companyBenefits,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (description != null) map['description'] = description;
    if (companyBenefits != null && companyBenefits! > 0) map['company_benefits'] = companyBenefits;
    if (isActive != null) map['is_active'] = isActive;
    return map;
  }
}
