import 'package:flutter_test/flutter_test.dart';
import 'package:multicliente_app/features/rifas/models/rifa_model.dart';

void main() {
  group('Rifas Models & Premio Mayor Tests', () {
    test('Rifa model should parse es_premio_mayor correctly', () {
      final jsonPremioMayor = {
        'id': 1,
        'nombre': 'Gran Rifa de Navidad',
        'descripcion': 'Auto 0km',
        'premio': 'Chevrolet Onix',
        'fecha_inicio': '2026-11-01T00:00:00Z',
        'fecha_fin': '2026-12-24T00:00:00Z',
        'fecha_sorteo': '2026-12-25T00:00:00Z',
        'estado': 'activa',
        'es_premio_mayor': true,
        'create_at': '2026-10-01T00:00:00Z',
      };

      final rifa = Rifa.fromJson(jsonPremioMayor);

      expect(rifa.id, 1);
      expect(rifa.nombre, 'Gran Rifa de Navidad');
      expect(rifa.premio, 'Chevrolet Onix');
      expect(rifa.esPremioMayor, true);
      expect(rifa.isActiva, true);
      expect(rifa.estadoLabel, 'Activa');

      // Check toJson serialization
      final serialized = rifa.toJson();
      expect(serialized['es_premio_mayor'], true);
    });

    test('Rifa model should default esPremioMayor to false when omitted', () {
      final jsonEstandar = {
        'id': 2,
        'nombre': 'Rifa Mensual Estándar',
        'premio': 'Bono \$500.000',
        'fecha_inicio': '2026-10-01T00:00:00Z',
        'fecha_fin': '2026-10-30T00:00:00Z',
        'fecha_sorteo': '2026-10-31T00:00:00Z',
        'estado': 'activa',
        'create_at': '2026-10-01T00:00:00Z',
      };

      final rifa = Rifa.fromJson(jsonEstandar);

      expect(rifa.esPremioMayor, false);
      expect(rifa.toJson()['es_premio_mayor'], false);
    });

    test('CreateRifaRequest should serialize es_premio_mayor correctly', () {
      final req = CreateRifaRequest(
        nombre: 'Sorteo Especial',
        premio: 'Viaje a Cancún',
        fechaInicio: '2026-10-01',
        fechaFin: '2026-10-20',
        fechaSorteo: '2026-10-21',
        esPremioMayor: true,
      );

      final json = req.toJson();
      expect(json['nombre'], 'Sorteo Especial');
      expect(json['premio'], 'Viaje a Cancún');
      expect(json['es_premio_mayor'], true);
    });

    test('UpdateRifaRequest should serialize es_premio_mayor correctly', () {
      final req = UpdateRifaRequest(
        premio: 'Moto Yamaha',
        esPremioMayor: false,
      );

      final json = req.toJson();
      expect(json['premio'], 'Moto Yamaha');
      expect(json['es_premio_mayor'], false);
    });

    test('ParticipacionRifa should parse origin labels properly', () {
      final jsonAfiliacion = {
        'id': 101,
        'rifa_id': 1,
        'usuario_id': 5,
        'nombre_usuario': 'Carlos Gómez',
        'numero_participacion': '10042',
        'origen': 'afiliacion',
        'fecha_participacion': '2026-10-02T10:00:00Z',
      };

      final p = ParticipacionRifa.fromJson(jsonAfiliacion);

      expect(p.id, 101);
      expect(p.numeroParticipacion, '10042');
      expect(p.origen, 'afiliacion');
      expect(p.origenLabel, 'Afiliación');
    });
  });
}
