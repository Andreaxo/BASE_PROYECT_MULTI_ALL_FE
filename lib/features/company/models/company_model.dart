class Company {
  final int id;
  final String name;
  final bool isActive;
  final int? createBy;
  final String? createAt;

  Company({
    required this.id,
    required this.name,
    required this.isActive,
    this.createBy,
    this.createAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as int,
      name: json['name'] as String,
      isActive: json['is_active'] as bool,
      createBy: json['create_by'] as int?,
      createAt: json['create_at']?.toString(),
    );
  }
}

class CreateCompanyRequest {
  final String name;

  CreateCompanyRequest({required this.name});

  Map<String, dynamic> toJson() => {'name': name};
}

class UpdateCompanyRequest {
  final String? name;
  final bool? isActive;

  UpdateCompanyRequest({this.name, this.isActive});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (isActive != null) map['is_active'] = isActive;
    return map;
  }
}
