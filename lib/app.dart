import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/company/screens/company_list_screen.dart';
import 'features/inventory/screens/article_list_screen.dart';
import 'features/inventory/screens/category_list_screen.dart';
import 'features/menu/screens/menu_list_screen.dart';
import 'features/role/screens/role_list_screen.dart';
import 'features/users/screens/user_list_screen.dart';
import 'features/users/screens/profile_screen.dart';
import 'features/statistics/screens/dashboard_screen.dart';

class MulticlienteApp extends StatelessWidget {
  final bool isLoggedIn;

  const MulticlienteApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final themeProvider = context.watch<ThemeProvider>();

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
      title: 'Multicliente App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: isLoggedIn ? '/users' : '/login',
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
          case '/categories':
          case '/inventory':
            builder = const CategoryListScreen();
            break;
          case '/items':
            builder = const ArticleListScreen();
            break;
          case '/profile':
            builder = const ProfileScreen();
            break;
          case '/statistics/dashboard':
            builder = const DashboardScreen();
            break;
          default:
            builder = isLoggedIn ? const UserListScreen() : const LoginScreen();
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
