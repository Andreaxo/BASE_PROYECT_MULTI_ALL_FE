import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:multicliente_app/app.dart';
import 'package:multicliente_app/features/auth/providers/auth_provider.dart';
import 'package:multicliente_app/features/users/providers/user_provider.dart';

void main() {
  testWidgets('App smoke test - shows login screen initially when logged out', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => UserProvider(),
          ),
        ],
        child: const MulticlienteApp(isLoggedIn: false, roleCode: ''),
      ),
    );

    // Verify that the login screen title 'Bienvenido' is shown.
    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Inicia sesión para continuar'), findsOneWidget);
  });
}
