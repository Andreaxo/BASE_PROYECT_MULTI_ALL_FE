import 'package:flutter/material.dart';
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
import 'package:multicliente_app/features/faq/screens/faq_screen.dart';

void main() {
  Widget createTestApp() {
    return MultiProvider(
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
    );
  }

  testWidgets('UI Flow 1: Navigate to FAQ from Login and test search/category filter', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    // 1. Verify FAQ link is present on Login
    final faqLinkFinder = find.text('Preguntas Frecuentes y Ayuda');
    expect(faqLinkFinder, findsOneWidget);

    // 2. Tap FAQ link
    await tester.tap(faqLinkFinder);
    await tester.pumpAndSettle();

    // 3. Verify FAQ screen is displayed
    expect(find.byType(FaqScreen), findsOneWidget);
    expect(find.text('Preguntas Frecuentes'), findsOneWidget);
    expect(find.text('Centro de Ayuda y Preguntas'), findsOneWidget);

    // 4. Test searching in FAQ
    final searchInputFinder = find.byType(TextField);
    expect(searchInputFinder, findsOneWidget);
    await tester.enterText(searchInputFinder, 'Premio Mayor');
    await tester.pumpAndSettle();

    expect(find.text('¿Qué es un "Premio Mayor" y cómo aumentan mis posibilidades?'), findsOneWidget);

    // 5. Test returning back to Login
    final backBtnFinder = find.text('Volver al Inicio de Sesión');
    expect(backBtnFinder, findsOneWidget);
    await tester.ensureVisible(backBtnFinder);
    await tester.tap(backBtnFinder);
    await tester.pumpAndSettle();

    // 6. Confirms back on login screen
    expect(find.text('Iniciar Sesión'), findsWidgets);
  });

  testWidgets('UI Flow 2: Registration Wizard Step 2 displays survey questions & dynamic entrepreneur field', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    // 1. Tap on 'Crear Cuenta' tab
    final registerTab = find.text('Crear Cuenta');
    expect(registerTab, findsWidgets);
    await tester.tap(registerTab.first);
    await tester.pumpAndSettle();

    // 2. Fill step 1 fields
    final textFields = find.byType(TextFormField);
    expect(textFields, findsWidgets);

    // Enter First Name
    await tester.enterText(textFields.at(0), 'Laura');
    // Enter Last Name
    await tester.enterText(textFields.at(1), 'Gómez');
    // Enter Email
    await tester.enterText(textFields.at(2), 'laura.test@example.com');
    // Enter Password
    await tester.enterText(textFields.at(3), 'Password123!');
    // Enter Confirm Password
    await tester.enterText(textFields.at(4), 'Password123!');

    await tester.pumpAndSettle();

    // 3. Click 'Continuar' to advance to Step 2
    final continueButton = find.text('Continuar');
    expect(continueButton, findsOneWidget);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    // 4. Verify survey questions appear in Step 2:
    expect(find.text('¿Tienes familiares en el exterior?'), findsOneWidget);
    expect(find.text('¿Casa propia o en arriendo?'), findsOneWidget);
    expect(find.text('¿Eres emprendedor?'), findsOneWidget);

    // 5. Verify NIT company referral option and input
    final companyChipFinder = find.text('Empresa (NIT / Código)');
    expect(companyChipFinder, findsOneWidget);
    await tester.ensureVisible(companyChipFinder);
    await tester.tap(companyChipFinder);
    await tester.pumpAndSettle();

    expect(find.text('NIT o Código de Empresa Aliada'), findsOneWidget);

    // 6. Test dynamic entrepreneur field:
    // Initially, the description field should NOT be visible
    expect(find.text('¿De qué es tu emprendimiento?'), findsNothing);

    // Tap 'Sí' on '¿Eres emprendedor?'
    final siChips = find.text('Sí');
    expect(siChips, findsWidgets);
    await tester.ensureVisible(siChips.last);
    await tester.tap(siChips.last);
    await tester.pumpAndSettle();

    // Now '¿De qué es tu emprendimiento?' MUST be visible!
    expect(find.text('¿De qué es tu emprendimiento?'), findsOneWidget);

    // Tap 'No' on '¿Eres emprendedor?'
    final noChips = find.text('No');
    await tester.ensureVisible(noChips.last);
    await tester.tap(noChips.last);
    await tester.pumpAndSettle();

    // Now the description field should disappear!
    expect(find.text('¿De qué es tu emprendimiento?'), findsNothing);
  });
}
