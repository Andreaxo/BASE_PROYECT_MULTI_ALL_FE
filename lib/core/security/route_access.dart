import '../../features/menu/models/menu_model.dart';

/// Central role-based route authorization policy.
///
/// Every protected route is checked here by [AuthGuard]. Access is denied by
/// default (fail-closed): a route is only allowed if the user's role explicitly
/// grants it, or — for roles created from access control — if the backend
/// returned the route among the user's allowed menus.
class RouteAccess {
  RouteAccess._();

  static const _businessRoles = {'business_validator', 'negocio'};
  static const _memberRoles = {'user', 'user_member'};
  static const _adminRoles = {'superadmin', 'super_admin', 'admin'};

  /// Routes that exist exclusively for allied business validators.
  static const _businessOnlyRoutes = {
    '/business-home',
    '/negocio',
    '/company-benefits',
    '/mis-beneficios',
  };

  /// Routes available to any authenticated user.
  static const _sharedRoutes = {'/profile'};

  static const _businessAllowed = {
    ..._businessOnlyRoutes,
    '/redemptions',
    '/validar-redencion',
    '/benefit',
    '/benefits',
    '/negocios-aliados',
    '/aliados',
    '/membresia',
    '/mi-membresia',
    ..._sharedRoutes,
  };

  static const _memberAllowed = {
    '/referidos',
    '/mis-referidos',
    '/rifas',
    '/rifa',
    '/mis-rifas',
    '/benefit',
    '/benefits',
    '/negocios-aliados',
    '/aliados',
    '/membresia',
    '/mi-membresia',
    ..._sharedRoutes,
  };

  static String _role(String roleCode) => roleCode.toLowerCase().trim();

  static bool isBusiness(String roleCode) => _businessRoles.contains(_role(roleCode));
  static bool isMember(String roleCode) => _memberRoles.contains(_role(roleCode));
  static bool isAdmin(String roleCode) => _adminRoles.contains(_role(roleCode));

  /// Whether the role needs the backend menu list to decide access
  /// (operador and any custom role created from access control).
  static bool requiresMenus(String roleCode) =>
      !isBusiness(roleCode) && !isMember(roleCode) && !isAdmin(roleCode);

  /// Maps route aliases to the canonical route used by menus.
  static String canonical(String path) {
    switch (path) {
      case '/benefits':
      case '/negocios-aliados':
      case '/aliados':
        return '/benefit';
      case '/company':
        return '/companies';
      case '/mis-referidos':
        return '/referidos';
      case '/rifa':
      case '/mis-rifas':
        return '/rifas';
      case '/validar-redencion':
      case '/admin/redemptions':
        return '/redemptions';
      case '/mi-membresia':
      case '/membresias':
        return '/membresia';
      default:
        return path;
    }
  }

  /// Canonical routes granted by the backend menus, using the same
  /// normalization as the sidebar (route or label based).
  static Set<String> _menuRoutes(List<AllowedMenu> menus) {
    final result = <String>{};
    void walk(List<AllowedMenu> list) {
      for (final m in list) {
        final label = m.label.toLowerCase();
        if (label.contains('referid')) {
          result.add('/referidos');
        } else if (label.contains('benefic')) {
          result.add('/benefit');
        } else if (label.contains('empresa') || label.contains('aliad')) {
          result.add('/companies');
        } else if (label.contains('rifa')) {
          result.add('/rifas');
        }
        if (m.route.isNotEmpty) result.add(canonical(m.route));
        walk(m.submenus);
      }
    }

    walk(menus);
    return result;
  }

  /// Returns true if [roleCode] may open [path].
  static bool canAccess({
    required String path,
    required String roleCode,
    required List<AllowedMenu> menus,
  }) {
    if (isBusiness(roleCode)) return _businessAllowed.contains(path);
    if (isMember(roleCode)) return _memberAllowed.contains(path);

    // No other role may open the allied-business panel.
    if (_businessOnlyRoutes.contains(path)) return false;

    if (isAdmin(roleCode)) return true;
    if (_sharedRoutes.contains(path)) return true;

    return _menuRoutes(menus).contains(canonical(path));
  }

  /// Safe landing route for a role (always accessible by that role).
  static String homeFor({
    required String roleCode,
    required List<AllowedMenu> menus,
  }) {
    if (isBusiness(roleCode)) return '/business-home';
    if (isMember(roleCode)) return '/referidos';
    if (isAdmin(roleCode)) return '/users';

    final allowed = _menuRoutes(menus);
    if (allowed.contains('/users')) return '/users';
    if (allowed.contains('/benefit')) return '/benefit';
    for (final m in menus) {
      final route = canonical(m.route);
      if (route.isNotEmpty && !_businessOnlyRoutes.contains(route)) return route;
    }
    return '/profile';
  }
}
