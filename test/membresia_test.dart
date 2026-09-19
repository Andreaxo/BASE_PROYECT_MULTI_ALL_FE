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
  });
}
