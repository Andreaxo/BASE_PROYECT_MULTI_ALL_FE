import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/localization/app_localizations.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/company/screens/company_list_screen.dart';
import 'features/inventory/screens/article_list_screen.dart';
import 'features/inventory/screens/category_list_screen.dart';
import 'features/menu/screens/menu_list_screen.dart';
import 'features/role/screens/role_list_screen.dart';
import 'features/users/screens/user_list_screen.dart';

class MulticlienteApp extends StatelessWidget {
  final bool isLoggedIn;

  const MulticlienteApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();

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
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6C63FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF4ECDC4),
          surface: Color(0xFF1E1E2E),
          background: Color(0xFF0F0C29),
          error: Color(0xFFFF6B6B),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0C29),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      initialRoute: isLoggedIn ? '/users' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/users': (context) => const UserListScreen(),
        '/companies': (context) => const CompanyListScreen(),
        '/roles': (context) => const RoleListScreen(),
        '/menus': (context) => const MenuListScreen(),
        '/categories': (context) => const CategoryListScreen(),
        '/items': (context) => const ArticleListScreen(),
        '/inventory': (context) => const CategoryListScreen(),
      },
    );
  }
}
