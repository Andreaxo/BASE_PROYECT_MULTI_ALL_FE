class NotificacionModel {
  final int id;
  final int usuarioId;
  final String tipo;
  final String titulo;
  final String mensaje;
  final bool leido;
  final int? referenciaId;
  final String? referenciaTipo;
  final DateTime createAt;

  NotificacionModel({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.leido,
    this.referenciaId,
    this.referenciaTipo,
    required this.createAt,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    return NotificacionModel(
      id: json['id'] as int? ?? 0,
      usuarioId: json['usuario_id'] as int? ?? 0,
      tipo: json['tipo'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      mensaje: json['mensaje'] as String? ?? '',
      leido: json['leido'] as bool? ?? false,
      referenciaId: json['referencia_id'] as int?,
      referenciaTipo: json['referencia_tipo'] as String?,
      createAt: json['create_at'] != null
          ? DateTime.tryParse(json['create_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NotificacionModel copyWith({bool? leido}) {
    return NotificacionModel(
      id: id,
      usuarioId: usuarioId,
      tipo: tipo,
      titulo: titulo,
      mensaje: mensaje,
      leido: leido ?? this.leido,
      referenciaId: referenciaId,
      referenciaTipo: referenciaTipo,
      createAt: createAt,
    );
  }
}
