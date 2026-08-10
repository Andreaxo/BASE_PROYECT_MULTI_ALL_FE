import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/company/screens/company_list_screen.dart';
import 'features/menu/screens/menu_list_screen.dart';
import 'features/role/screens/role_list_screen.dart';
import 'features/users/screens/user_list_screen.dart';
import 'features/users/screens/profile_screen.dart';
import 'features/benefits/screens/benefit_list_screen.dart';
import 'features/benefits/screens/my_company_benefits_screen.dart';
import 'features/benefits/screens/redemption_validator_screen.dart';
import 'features/benefits/screens/admin_redemptions_screen.dart';
import 'features/referidos/screens/mis_referidos_screen.dart';
import 'features/referidos/screens/referido_admin_screen.dart';
import 'features/rifas/screens/rifa_user_screen.dart';
import 'features/rifas/screens/rifa_admin_screen.dart';

class MulticlienteApp extends StatelessWidget {
  final bool isLoggedIn;
  final String roleCode;

  const MulticlienteApp({
    super.key,
    required this.isLoggedIn,
    required this.roleCode,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();

    final currentIsLoggedIn = authProvider.isLoggedIn || isLoggedIn;
    final currentRoleCode = authProvider.roleCode.isNotEmpty
        ? authProvider.roleCode
        : roleCode;

    String initialRoute = '/login';
    if (currentIsLoggedIn) {
      if (currentRoleCode == 'business_validator' || currentRoleCode == 'negocio') {
        initialRoute = '/redemptions';
      } else if (currentRoleCode == 'user' || currentRoleCode == 'user_member') {
        initialRoute = '/referidos';
      } else {
        initialRoute = '/users';
      }
    }

    return MaterialApp(
      locale: languageProvider.locale,
      supportedLocales: const [
        Locale('es', ''),
        Locale('en', ''),
        Locale('fr', ''),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'Conexiate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        Widget builder;
        switch (settings.name) {
          case '/login':
            builder = const LoginScreen();
            break;
          case '/users':
            builder = const UserListScreen();
            break;
          case '/companies':
            builder = const CompanyListScreen();
            break;
          case '/roles':
            builder = const RoleListScreen();
            break;
          case '/menus':
            builder = const MenuListScreen();
            break;
          case '/profile':
            builder = const ProfileScreen();
            break;
          case '/benefit':
          case '/benefits':
          case '/negocios-aliados':
          case '/aliados':
            builder = const BenefitListScreen();
            break;
          case '/company-benefits':
          case '/mis-beneficios':
            builder = const MyCompanyBenefitsScreen();
            break;
          case '/redemptions':
          case '/validar-redencion':
            // Role Guard: Only business_validator or admins can access redemption validator screen
            if (currentRoleCode == 'business_validator' || currentRoleCode == 'negocio') {
              builder = const RedemptionValidatorScreen();
            } else if (currentRoleCode == 'superadmin' || currentRoleCode == 'admin') {
              builder = const AdminRedemptionsScreen();
            } else {
              builder = const BenefitListScreen(); // Safe fallback for regular members
            }
            break;
          case '/admin/redemptions':
            if (currentRoleCode == 'superadmin' || currentRoleCode == 'admin') {
              builder = const AdminRedemptionsScreen();
            } else {
              builder = const BenefitListScreen();
            }
            break;
          case '/referidos':
          case '/mis-referidos':
            final isAdmin = currentRoleCode == 'superadmin' || currentRoleCode == 'admin';
            builder = isAdmin
                ? const ReferidoAdminScreen()
                : const MisReferidosScreen();
            break;
          case '/rifas':
          case '/rifa':
          case '/mis-rifas':
            final isAdmin = currentRoleCode == 'superadmin' || currentRoleCode == 'admin';
            builder = isAdmin
                ? const RifaAdminScreen()
                : const RifaUserScreen();
            break;
          default:
            final isUser =
                currentRoleCode == 'user' || currentRoleCode == 'user_member';
            builder = currentIsLoggedIn
                ? (isUser ? const MisReferidosScreen() : const UserListScreen())
                : const LoginScreen();
        }

        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => builder,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
      },
    );
  }
}
