import 'package:flutter_test/flutter_test.dart';
import 'package:multicliente_app/features/benefits/models/benefit_model.dart';

void main() {
  group('Benefit Model & Payment Status Tests', () {
    test('Benefit with deshabilitado_falta_pago should have isActive false and isDeshabilitadoFaltaPago true', () {
      final json = {
        'id': 10,
        'name': '2x1 en Pizzas',
        'description': 'Aplica martes y jueves',
        'company_benefits': 5,
        'is_active': false,
        'estado': 'deshabilitado_falta_pago',
      };

      final benefit = Benefit.fromJson(json);

      expect(benefit.id, 10);
      expect(benefit.isActive, false);
      expect(benefit.isDeshabilitadoFaltaPago, true);
      expect(benefit.estado, 'deshabilitado_falta_pago');
    });

    test('Active benefit from paid company should have isActive true and isDeshabilitadoFaltaPago false', () {
      final json = {
        'id': 11,
        'name': '15% Descuento en Odontología',
        'description': 'En limpieza y profilaxis',
        'company_benefits': 8,
        'is_active': true,
        'estado': 'activo',
      };

      final benefit = Benefit.fromJson(json);

      expect(benefit.id, 11);
      expect(benefit.isActive, true);
      expect(benefit.isDeshabilitadoFaltaPago, false);
    });

    test('Member filter should exclude unpaid and inactive benefits', () {
      final b1 = Benefit(id: 1, name: 'B1 Activo', description: '', companyBenefits: 1, isActive: true, estado: 'activo');
      final b2 = Benefit(id: 2, name: 'B2 Moroso', description: '', companyBenefits: 2, isActive: false, estado: 'deshabilitado_falta_pago');
      final b3 = Benefit(id: 3, name: 'B3 Inactivo', description: '', companyBenefits: 3, isActive: false, estado: 'inactivo');

      final allBenefits = [b1, b2, b3];

      // Filtering criteria applied in member view
      final memberVisibleBenefits = allBenefits.where((b) => b.isActive && !b.isDeshabilitadoFaltaPago).toList();

      expect(memberVisibleBenefits.length, 1);
      expect(memberVisibleBenefits.first.id, 1);
      expect(memberVisibleBenefits.any((b) => b.id == 2), false);
    });
  });
}
