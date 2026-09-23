import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:multicliente_app/app.dart';
import 'package:multicliente_app/core/localization/app_localizations.dart';
import 'package:multicliente_app/core/theme/theme_provider.dart';
import 'package:multicliente_app/features/auth/providers/auth_provider.dart';
import 'package:multicliente_app/features/users/providers/user_provider.dart';
import 'package:multicliente_app/features/referidos/providers/referido_provider.dart';
import 'package:multicliente_app/features/rifas/providers/rifa_provider.dart';
import 'package:multicliente_app/features/membresia/providers/membresia_provider.dart';
import 'package:multicliente_app/features/notificaciones/providers/notificacion_provider.dart';

void main() {
  testWidgets('App smoke test - shows login screen initially when logged out', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => ReferidoProvider()),
          ChangeNotifierProvider(create: (_) => RifaProvider()),
          ChangeNotifierProvider(create: (_) => MembresiaProvider()),
          ChangeNotifierProvider(create: (_) => NotificacionProvider()),
        ],
        child: const MulticlienteApp(isLoggedIn: false, roleCode: ''),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the login and register tab buttons are displayed
    expect(find.text('Iniciar Sesión'), findsWidgets);
    expect(find.text('Crear Cuenta'), findsWidgets);
  });
}
