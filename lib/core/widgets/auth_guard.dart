import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/menu/providers/menu_provider.dart';
import '../security/route_access.dart';

/// AuthGuard wraps a protected screen and enforces both authentication and
/// role-based authorization for the current route.
///
/// - Unauthenticated users are redirected to `/login`.
/// - Authenticated users opening a route their role does not grant (e.g. typing
///   `#/business-home` manually) are redirected to their own home route.
///
/// The route is read from the enclosing [ModalRoute] settings, so every route
/// built in `onGenerateRoute` is protected without extra parameters.
///
/// Usage:
///   builder = const AuthGuard(child: UserListScreen());
class AuthGuard extends StatefulWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _redirecting = false;
  bool _menusRequested = false;

  void _redirect(String route, {bool removeAll = false, bool showDenied = false}) {
    if (_redirecting) return;
    _redirecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (removeAll) {
        navigator.pushNamedAndRemoveUntil(route, (r) => false);
      } else {
        navigator.pushReplacementNamed(route);
      }
      if (showDenied) {
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('No tienes permisos para acceder a esa sección.'),
            backgroundColor: Color(0xFFEF4444),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  Widget _loading() {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final menuProvider = context.watch<MenuProvider>();

    if (!authProvider.isLoggedIn) {
      _redirect('/login', removeAll: true);
      return _loading();
    }

    final roleCode = authProvider.roleCode;
    if (roleCode.isEmpty) return _loading();

    // Custom roles (and operador) are authorized by their backend menus.
    if (RouteAccess.requiresMenus(roleCode) && !menuProvider.myMenusLoaded) {
      if (!_menusRequested) {
        _menusRequested = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.read<MenuProvider>().loadMyMenus();
        });
      }
      return _loading();
    }

    final routeName = ModalRoute.of(context)?.settings.name ?? '';
    final path = Uri.parse(routeName).path;

    final allowed = RouteAccess.canAccess(
      path: path,
      roleCode: roleCode,
      menus: menuProvider.myMenus,
    );

    if (!allowed) {
      final home = RouteAccess.homeFor(
        roleCode: roleCode,
        menus: menuProvider.myMenus,
      );
      // Never redirect to the same route (avoids loops); fall back to profile.
      final target = home == path ? '/profile' : home;
      _redirect(target, showDenied: true);
      return _loading();
    }

    return widget.child;
  }
}
