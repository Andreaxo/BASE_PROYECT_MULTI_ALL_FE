import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/auth_storage.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/company/providers/company_provider.dart';
import 'features/inventory/providers/article_provider.dart';
import 'features/inventory/providers/category_provider.dart';
import 'features/menu/providers/menu_provider.dart';
import 'features/role/providers/role_provider.dart';
import 'features/users/providers/user_provider.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Check initial login status
  final isLoggedIn = await AuthStorage.isLoggedIn();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CompanyProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => RoleProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => MenuProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ArticleProvider(),
        ),
      ],
      child: MulticlienteApp(isLoggedIn: isLoggedIn),
    ),
  );
}
