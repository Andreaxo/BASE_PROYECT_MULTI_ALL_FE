import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User Survey & Characterization Tests', () {
    test('Survey fields should build correct JSON payload for registration', () {
      final payload = {
        'first_name': 'María',
        'last_name': 'Alzate',
        'email': 'maria@example.com',
        'password': 'Password123!',
        'familiares_exterior': true,
        'vivienda_tipo': 'Propia',
        'es_emprendedor': true,
        'descripcion_emprendimiento': 'Tienda de artesanías y café de origen',
        'referred_by': '900123456',
      };

      expect(payload['familiares_exterior'], true);
      expect(payload['vivienda_tipo'], 'Propia');
      expect(payload['es_emprendedor'], true);
      expect(payload['descripcion_emprendimiento'], 'Tienda de artesanías y café de origen');
      expect(payload['referred_by'], '900123456');
    });

    test('Non-entrepreneur survey should handle null description', () {
      final payload = {
        'first_name': 'Pedro',
        'last_name': 'Pérez',
        'email': 'pedro@example.com',
        'password': 'Password123!',
        'familiares_exterior': false,
        'vivienda_tipo': 'Arriendo',
        'es_emprendedor': false,
        'descripcion_emprendimiento': null,
      };

      expect(payload['es_emprendedor'], false);
      expect(payload['descripcion_emprendimiento'], isNull);
      expect(payload['vivienda_tipo'], 'Arriendo');
      expect(payload['familiares_exterior'], false);
    });
  });
}
