import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/auth_guard.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/company/screens/company_list_screen.dart';
import 'features/company/screens/business_welcome_screen.dart';
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
import 'features/membresia/screens/membresia_screen.dart';
import 'core/services/api_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class MulticlienteApp extends StatefulWidget {
  final bool isLoggedIn;
  final String roleCode;

  const MulticlienteApp({
    super.key,
    required this.isLoggedIn,
    required this.roleCode,
  });

  @override
  State<MulticlienteApp> createState() => _MulticlienteAppState();
}

class _MulticlienteAppState extends State<MulticlienteApp> {
  late final String _initialRoute;

  @override
  void initState() {
    super.initState();
    // Compute initial route ONCE at startup based on initial login state
    if (widget.isLoggedIn) {
      if (widget.roleCode == 'business_validator' || widget.roleCode == 'negocio') {
        _initialRoute = '/business-home';
      } else if (widget.roleCode == 'user' || widget.roleCode == 'user_member') {
        _initialRoute = '/referidos';
      } else {
        _initialRoute = '/users';
      }
    } else {
      _initialRoute = '/login';
    }

    ApiService.onSessionExpired = () {
      final ctx = appNavigatorKey.currentContext;
      if (ctx != null) {
        final authProvider = ctx.read<AuthProvider>();
        // Only trigger session expiration if the user was actively logged in
        // and avoid resetting if the user is already on the login page.
        final currentRoute = ModalRoute.of(ctx)?.settings.name;
        if (authProvider.isLoggedIn && currentRoute != '/login') {
          authProvider.logout();
          appNavigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Tu sesión ha expirado por inactividad. Por favor, inicia sesión de nuevo.'),
              backgroundColor: Color(0xFFEF4444),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    // NOTE: We intentionally do NOT watch AuthProvider here. Watching AuthProvider
    // at root caused MaterialApp to rebuild its entire Navigator and route stack on
    // every notifyListeners() (e.g. isLoading=true during login), wiping inputs.

    return MaterialApp(
      navigatorKey: appNavigatorKey,
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
      initialRoute: _initialRoute,
      onGenerateRoute: (settings) {
        final authProvider = context.read<AuthProvider>();
        final currentRoleCode = authProvider.roleCode.isNotEmpty
            ? authProvider.roleCode
            : widget.roleCode;
        final currentIsLoggedIn = authProvider.isLoggedIn;

        final uri = Uri.parse(settings.name ?? '');
        Widget builder;
        switch (uri.path) {
          // ── Rutas públicas (no requieren sesión) ──────────────────────────
          case '/login':
            builder = const LoginScreen(initialTab: AuthTab.login);
            break;
          case '/register':
          case '/registro':
            builder = LoginScreen(
              initialTab: AuthTab.register,
              initialRefCode: uri.queryParameters['ref'],
              initialCompanyCode: uri.queryParameters['company'] ?? uri.queryParameters['empresa'],
            );
            break;
          case '/olvide-password':
          case '/forgot-password':
            builder = const ForgotPasswordScreen();
            break;
          case '/activar-cuenta':
            builder = ResetPasswordScreen(
              initialToken: uri.queryParameters['token'],
              isActivationFlow: true,
            );
            break;
          case '/reset-password':
            builder = ResetPasswordScreen(
              initialToken: uri.queryParameters['token'],
              isActivationFlow: false,
            );
            break;

          // ── Rutas protegidas (requieren sesión activa) ────────────────────
          case '/business-home':
          case '/negocio':
            builder = const AuthGuard(child: BusinessWelcomeScreen());
            break;
          case '/users':
            builder = const AuthGuard(child: UserListScreen());
            break;
          case '/companies':
            builder = const AuthGuard(child: CompanyListScreen());
            break;
          case '/roles':
            builder = const AuthGuard(child: RoleListScreen());
            break;
          case '/menus':
            builder = const AuthGuard(child: MenuListScreen());
            break;
          case '/profile':
            builder = const AuthGuard(child: ProfileScreen());
            break;
          case '/benefit':
          case '/benefits':
          case '/negocios-aliados':
          case '/aliados':
            // Role Guard: Business validator cannot access global administration benefits table
            if (currentRoleCode == 'business_validator' || currentRoleCode == 'negocio') {
              builder = const AuthGuard(child: MyCompanyBenefitsScreen());
            } else {
              builder = const AuthGuard(child: BenefitListScreen());
            }
            break;
          case '/company-benefits':
          case '/mis-beneficios':
            builder = const AuthGuard(child: MyCompanyBenefitsScreen());
            break;
          case '/redemptions':
          case '/validar-redencion':
            // Role Guard: Only business_validator or admins can access redemption validator screen
            if (currentRoleCode == 'business_validator' || currentRoleCode == 'negocio') {
              builder = const AuthGuard(child: RedemptionValidatorScreen());
            } else if (currentRoleCode == 'superadmin' || currentRoleCode == 'admin' || currentRoleCode == 'operador') {
              builder = const AuthGuard(child: AdminRedemptionsScreen());
            } else {
              builder = const AuthGuard(child: BenefitListScreen());
            }
            break;
          case '/admin/redemptions':
            if (currentRoleCode == 'superadmin' || currentRoleCode == 'admin' || currentRoleCode == 'operador') {
              builder = const AuthGuard(child: AdminRedemptionsScreen());
            } else {
              builder = const AuthGuard(child: BenefitListScreen());
            }
            break;
          case '/referidos':
          case '/mis-referidos':
            final isAdmin = currentRoleCode == 'superadmin' || currentRoleCode == 'admin' || currentRoleCode == 'operador';
            builder = isAdmin
                ? const AuthGuard(child: ReferidoAdminScreen())
                : const AuthGuard(child: MisReferidosScreen());
            break;
          case '/rifas':
          case '/rifa':
          case '/mis-rifas':
            final isAdmin = currentRoleCode == 'superadmin' || currentRoleCode == 'admin' || currentRoleCode == 'operador';
            builder = isAdmin
                ? const AuthGuard(child: RifaAdminScreen())
                : const AuthGuard(child: RifaUserScreen());
            break;
          case '/membresia':
          case '/mi-membresia':
            builder = const AuthGuard(child: MembresiaScreen());
            break;
          default:
            final isUser =
                currentRoleCode == 'user' || currentRoleCode == 'user_member';
            builder = currentIsLoggedIn
                ? AuthGuard(child: isUser ? const MisReferidosScreen() : const UserListScreen())
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


