import 'package:flutter_test/flutter_test.dart';
import 'package:multicliente_app/features/membresia/models/membresia_model.dart';

void main() {
  group('Membresía Models & Logic Tests', () {
    test(
      'MembresiaModel should correctly parse JSON and determine active state',
      () {
        final json = {
          'id': 1,
          'usuario_id': 10,
          'estado': 'activa',
          'fecha_inicio': '2026-08-01T00:00:00Z',
          'fecha_fin': '2026-09-01T00:00:00Z',
          'renovacion_automatica': true,
          'tiene_metodo_pago': true,
        };

        final model = MembresiaModel.fromJson(json);

        expect(model.id, 1);
        expect(model.usuarioId, 10);
        expect(model.isActiva, true);
        expect(model.isInactiva, false);
        expect(model.renovacionAutomatica, true);
        expect(model.tieneMetodoPago, true);
      },
    );

    test(
      'IniciarPagoResponse should correctly parse Wompi transaction JSON',
      () {
        final json = {
          'transaction_id': 'tx_wompi_12345',
          'checkout_url': 'https://checkout.wompi.co/l/tx_12345',
          'referencia': 'MEMB-1-12345678',
        };

        final response = IniciarPagoResponse.fromJson(json);

        expect(response.transactionId, 'tx_wompi_12345');
        expect(response.checkoutUrl, 'https://checkout.wompi.co/l/tx_12345');
        expect(response.referencia, 'MEMB-1-12345678');
      },
    );
    test(
      'MembresiaModel should correctly parse trial membership (prueba) for allied businesses',
      () {
        final now = DateTime.now();
        final oneYearLater = now.add(const Duration(days: 365));
        final json = {
          'id': 2,
          'usuario_id': 25,
          'estado': 'prueba',
          'fecha_inicio': now.toIso8601String(),
          'fecha_fin': oneYearLater.toIso8601String(),
          'renovacion_automatica': false,
          'tiene_metodo_pago': false,
        };

        final model = MembresiaModel.fromJson(json);

        expect(model.id, 2);
        expect(model.usuarioId, 25);
        expect(model.isPrueba, true);
        expect(model.isVigente, true);
        expect(model.isInactiva, false);
        expect(model.isActiva, false);
        expect(model.renovacionAutomatica, false);
        expect(model.diasRestantes, greaterThan(360));
      },
    );

    test(
      'MembresiaModel isVigente is true for both activa and prueba, false for inactiva',
      () {
        final trial = MembresiaModel(
          id: 3,
          usuarioId: 30,
          estado: 'prueba',
          renovacionAutomatica: false,
          tieneMetodoPago: false,
        );
        final active = MembresiaModel(
          id: 4,
          usuarioId: 31,
          estado: 'activa',
          renovacionAutomatica: true,
          tieneMetodoPago: true,
        );
        final inactive = MembresiaModel(
          id: 5,
          usuarioId: 32,
          estado: 'inactiva',
          renovacionAutomatica: false,
          tieneMetodoPago: false,
        );

        expect(trial.isVigente, true);
        expect(trial.isPrueba, true);
        expect(active.isVigente, true);
        expect(active.isActiva, true);
        expect(inactive.isVigente, false);
        expect(inactive.isInactiva, true);
      },
    );
  });
}
