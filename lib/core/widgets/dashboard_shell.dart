import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../localization/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../utils/icon_library.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/menu/models/menu_model.dart';
import '../../features/menu/providers/menu_provider.dart';
import '../../features/referidos/providers/referido_provider.dart';
import '../../features/rifas/providers/rifa_provider.dart';
import '../../features/notificaciones/providers/notificacion_provider.dart';
import '../../features/notificaciones/widgets/notificacion_bell.dart';

/// Premium layout wrapper providing dynamic left sidebar (desktop) or Drawer (mobile),
/// an active company switcher, a language switcher (ES/EN), and dynamic menu loading.
class DashboardShell extends StatefulWidget {
  final Widget child;
  final String title;

  const DashboardShell({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuProvider = context.read<MenuProvider>();
      menuProvider.loadMyMenus();
      final authProvider = context.read<AuthProvider>();
      if (authProvider.roleCode == 'superadmin') {
        context.read<NotificacionProvider>().startPolling();
      }
    });
  }

  IconData _getIconData(String iconName) {
    return IconLibrary.getIcon(iconName);
  }

  Widget _buildDefaultCompanyIcon() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.business_rounded, color: Colors.white, size: 20),
    );
  }

  Widget _buildMenuItem(AllowedMenu item, String? currentRoute, String langCode, AppThemeColors themeColors) {
    final label = langCode == 'es' ? item.label : (langCode == 'fr' ? item.labelFr : item.labelEn);

    if (item.submenus.isNotEmpty) {
      final isAnySubSelected = item.submenus.any((sub) => currentRoute == sub.route);

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isAnySubSelected ? themeColors.textPrimary.withValues(alpha: 0.02) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAnySubSelected ? themeColors.borderColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              unselectedWidgetColor: themeColors.textSecondary,
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.accent,
              ),
            ),
            child: ExpansionTile(
              initiallyExpanded: isAnySubSelected,
              leading: Icon(
                _getIconData(item.icon),
                color: isAnySubSelected ? AppColors.accent : themeColors.textSecondary,
                size: 20,
              ),
              title: Text(
                label,
                style: GoogleFonts.inter(
                  color: isAnySubSelected ? themeColors.textPrimary : themeColors.textSecondary,
                  fontWeight: isAnySubSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              childrenPadding: const EdgeInsets.only(left: 12, bottom: 8),
              children: item.submenus.map((sub) => _buildSubMenuItem(sub, currentRoute, langCode, themeColors)).toList(),
            ),
          ),
        ),
      );
    } else {
      final isSelected = currentRoute == item.route;
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          onTap: () {
            if (isSelected) return;
            Navigator.of(context).pushReplacementNamed(item.route);
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getIconData(item.icon),
                  color: isSelected
                      ? AppColors.accent
                      : themeColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      color: isSelected ? themeColors.textPrimary : themeColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildSubMenuItem(AllowedMenu sub, String? currentRoute, String langCode, AppThemeColors themeColors) {
    final isSelected = currentRoute == sub.route;
    final label = langCode == 'es' ? sub.label : (langCode == 'fr' ? sub.labelFr : sub.labelEn);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: InkWell(
        onTap: () {
          if (isSelected) return;
          Navigator.of(context).pushReplacementNamed(sub.route);
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                _getIconData(sub.icon),
                color: isSelected
                    ? AppColors.accent
                    : themeColors.textSecondary.withValues(alpha: 0.8),
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: isSelected ? themeColors.textPrimary : themeColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 900;
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final menuProvider = context.watch<MenuProvider>();
    final authProvider = context.watch<AuthProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;
    final isMember = authProvider.roleCode == 'user' || authProvider.roleCode == 'user_member';
    final showUnifiedBranding = isMember ||
        authProvider.roleCode == 'business_validator' ||
        authProvider.roleCode == 'superadmin' ||
        authProvider.roleCode == 'operador';

    final rawMenus = menuProvider.myMenus;
    final menus = <AllowedMenu>[];
    bool hasReferidos = false;
    bool hasBeneficios = false;
    bool hasCompany = false;
    bool hasRifas = false;

    for (final m in rawMenus) {
      final isRef = m.route == '/referidos' ||
          m.route == '/mis-referidos' ||
          m.label.toLowerCase().contains('referid');
      final isBen = m.route == '/benefit' ||
          m.route == '/benefits' ||
          m.label.toLowerCase().contains('benefic');
      final isComp = m.route == '/companies' ||
          m.route == '/company' ||
          m.label.toLowerCase().contains('empresa') ||
          m.label.toLowerCase().contains('aliad');
      final isRifa = m.route == '/rifas' ||
          m.route == '/rifa' ||
          m.route == '/mis-rifas' ||
          m.label.toLowerCase().contains('rifa');

      if (isRef) {
        if (!hasReferidos) {
          hasReferidos = true;
          menus.add(
            AllowedMenu(
              id: m.id,
              label: m.label.isNotEmpty ? m.label : 'Referidos',
              labelEn: m.labelEn.isNotEmpty ? m.labelEn : 'Referrals',
              labelFr: m.labelFr.isNotEmpty ? m.labelFr : 'Parrainage',
              route: '/referidos',
              icon: m.icon.isNotEmpty ? m.icon : 'share_rounded',
              sortOrder: m.sortOrder,
              permissions: m.permissions,
              submenus: m.submenus,
            ),
          );
        }
      } else if (isBen) {
        if (!hasBeneficios) {
          hasBeneficios = true;
          menus.add(
            AllowedMenu(
              id: m.id,
              label: m.label.isNotEmpty ? m.label : 'Beneficios',
              labelEn: m.labelEn.isNotEmpty ? m.labelEn : 'Benefits',
              labelFr: m.labelFr.isNotEmpty ? m.labelFr : 'Avantages',
              route: '/benefit',
              icon: m.icon.isNotEmpty ? m.icon : 'card_giftcard_rounded',
              sortOrder: m.sortOrder,
              permissions: m.permissions,
              submenus: m.submenus,
            ),
          );
        }
      } else if (isComp) {
        if (!hasCompany) {
          hasCompany = true;
          menus.add(
            AllowedMenu(
              id: m.id,
              label: 'Negocios Aliados',
              labelEn: 'Allied Businesses',
              labelFr: 'Partenaires',
              route: '/companies',
              icon: 'store_rounded',
              sortOrder: m.sortOrder,
              permissions: m.permissions,
              submenus: m.submenus,
            ),
          );
        }
      } else if (isRifa) {
        if (!hasRifas) {
          hasRifas = true;
          menus.add(
            AllowedMenu(
              id: m.id,
              label: m.label.isNotEmpty ? m.label : 'Rifas',
              labelEn: m.labelEn.isNotEmpty ? m.labelEn : 'Raffles',
              labelFr: m.labelFr.isNotEmpty ? m.labelFr : 'Tombolas',
              route: '/rifas',
              icon: m.icon.isNotEmpty ? m.icon : 'confirmation_number_rounded',
              sortOrder: m.sortOrder,
              permissions: m.permissions,
              submenus: m.submenus,
            ),
          );
        }
      } else {
        menus.add(m);
      }
    }

    final isBusinessValidator = authProvider.roleCode == 'business_validator' || authProvider.roleCode == 'negocio';

    if (authProvider.isLoggedIn && isBusinessValidator) {
      menus.clear();
      menus.add(
        AllowedMenu(
          id: 997,
          label: 'Inicio',
          labelEn: 'Home',
          labelFr: 'Accueil',
          route: '/business-home',
          icon: 'home_rounded',
          sortOrder: 5,
          permissions: const ['VIEW'],
          submenus: const [],
        ),
      );
      menus.add(
        AllowedMenu(
          id: 996,
          label: 'Validar Redenciones',
          labelEn: 'Validate Redemptions',
          labelFr: 'Valider Redemptions',
          route: '/redemptions',
          icon: 'qr_code_scanner_rounded',
          sortOrder: 10,
          permissions: const ['VIEW', 'CREATE', 'EDIT', 'DELETE'],
          submenus: const [],
        ),
      );
      menus.add(
        AllowedMenu(
          id: 994,
          label: 'Gestionar Mis Beneficios',
          labelEn: 'Manage My Benefits',
          labelFr: 'Gérer Mes Avantages',
          route: '/company-benefits',
          icon: 'card_giftcard_rounded',
          sortOrder: 11,
          permissions: const ['VIEW', 'CREATE', 'EDIT', 'DELETE'],
          submenus: const [],
        ),
      );
      menus.add(
        AllowedMenu(
          id: 993,
          label: 'Mi Membresía',
          labelEn: 'My Membership',
          labelFr: 'Mon Adhésion',
          route: '/membresia',
          icon: 'workspace_premium_rounded',
          sortOrder: 12,
          permissions: const ['VIEW', 'CREATE', 'EDIT', 'DELETE'],
          submenus: const [],
        ),
      );
    }

    if (authProvider.isLoggedIn &&
        (authProvider.roleCode == 'superadmin' ||
            authProvider.roleCode == 'admin')) {
      menus.add(
        AllowedMenu(
          id: 995,
          label: 'Redenciones Globales',
          labelEn: 'Global Redemptions',
          labelFr: 'Redemptions Globales',
          route: '/redemptions',
          icon: 'assignment_turned_in_rounded',
          sortOrder: 85,
          permissions: const ['VIEW', 'CREATE', 'EDIT', 'DELETE'],
          submenus: const [],
        ),
      );
    }

    if (authProvider.isLoggedIn && isMember && !hasRifas) {
      menus.add(
        AllowedMenu(
          id: 997,
          label: 'Rifas',
          labelEn: 'Raffles',
          labelFr: 'Tombolas',
          route: '/rifas',
          icon: 'confirmation_number_rounded',
          sortOrder: 90,
          permissions: const ['VIEW', 'CREATE', 'EDIT', 'DELETE'],
          submenus: const [],
        ),
      );
    }

    if (authProvider.isLoggedIn && isMember && !hasBeneficios) {
      menus.add(
        AllowedMenu(
          id: 998,
          label: 'Beneficios',
          labelEn: 'Benefits',
          labelFr: 'Avantages',
          route: '/benefit',
          icon: 'card_giftcard_rounded',
          sortOrder: 95,
          permissions: const ['VIEW', 'CREATE', 'EDIT', 'DELETE'],
          submenus: const [],
        ),
      );
    }

    if (authProvider.isLoggedIn && isMember && !hasReferidos) {
      menus.add(
        AllowedMenu(
          id: 999,
          label: 'Referidos',
          labelEn: 'Referrals',
          labelFr: 'Parrainage',
          route: '/referidos',
          icon: 'share_rounded',
          sortOrder: 100,
          permissions: const ['VIEW', 'CREATE', 'EDIT', 'DELETE'],
          submenus: const [],
        ),
      );
    }

    if (authProvider.isLoggedIn && isMember) {
      menus.add(
        AllowedMenu(
          id: 992,
          label: 'Mi Membresía',
          labelEn: 'My Membership',
          labelFr: 'Mon Adhésion',
          route: '/membresia',
          icon: 'workspace_premium_rounded',
          sortOrder: 105,
          permissions: const ['VIEW', 'CREATE', 'EDIT', 'DELETE'],
          submenus: const [],
        ),
      );
    } else if (authProvider.isLoggedIn && authProvider.isAdminOrSuperAdmin) {
      menus.add(
        AllowedMenu(
          id: 992,
          label: 'Membresías',
          labelEn: 'Memberships',
          labelFr: 'Adhésions',
          route: '/membresia',
          icon: 'workspace_premium_rounded',
          sortOrder: 105,
          permissions: const ['VIEW', 'CREATE', 'EDIT', 'DELETE'],
          submenus: const [],
        ),
      );
    }

    Widget buildSidebarContent() {
      return Container(
        width: 300,
        decoration: BoxDecoration(
          color: themeColors.sidebarBg,
          border: Border(
            right: BorderSide(color: themeColors.borderColor, width: 1.5),
          ),
        ),
        child: Column(
          children: [
            // Brand Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                children: [
                  if (!showUnifiedBranding &&
                      authProvider.activeCompany != null &&
                      authProvider.activeCompany!.photoUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        '${ApiConfig.serverUrl}${authProvider.activeCompany!.photoUrl}',
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDefaultCompanyIcon(),
                      ),
                    )
                  else if (showUnifiedBranding)
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.stars_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    )
                  else
                    _buildDefaultCompanyIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          showUnifiedBranding
                              ? 'Conexiate'
                              : (authProvider.activeCompany?.name ?? 'PLATAFORMA'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: themeColors.textPrimary,
                          ),
                        ),
                        Text(
                          showUnifiedBranding
                              ? 'Red de Beneficios'
                              : (authProvider.activeCompany != null
                                  ? 'Empresa Activa'
                                  : 'Multicliente Base'),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: themeColors.textSecondary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: themeColors.borderColor, height: 1),
            const SizedBox(height: 16),

            // Navigation Items (Hierarchical mapping)
            Expanded(
              child: menuProvider.isLoading && menus.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: menus.map((item) => _buildMenuItem(item, currentRoute, languageProvider.currentLanguageCode, themeColors)).toList(),
                      ),
                    ),
            ),

            // Profile info at bottom
            Divider(color: themeColors.borderColor, height: 1),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pushNamed('/profile');
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      if (authProvider.currentUser != null && authProvider.currentUser!.photoUrl.isNotEmpty)
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(
                            '${ApiConfig.serverUrl}${authProvider.currentUser!.photoUrl}',
                          ),
                          backgroundColor: Colors.transparent,
                        )
                      else
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          child: Text(
                            authProvider.userName.isNotEmpty ? authProvider.userName[0].toUpperCase() : 'U',
                            style: GoogleFonts.outfit(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              authProvider.userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: themeColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              authProvider.roleDisplayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: AppColors.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: themeColors.textSecondary.withValues(alpha: 0.5), size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: themeColors.gradientBg.first,
      drawer: isMobile ? Drawer(child: buildSidebarContent()) : null,
      appBar: AppBar(
        backgroundColor: themeColors.sidebarBg.withValues(alpha: 0.8),
        elevation: 0,
        toolbarHeight: 74.0,
        leading: isMobile
            ? Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu_rounded, color: themeColors.textPrimary),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : IconButton(
                icon: Icon(themeProvider.isSidebarCollapsed ? Icons.menu_rounded : Icons.menu_open_rounded, color: themeColors.textPrimary),
                onPressed: () => themeProvider.toggleSidebar(),
              ),
        title: Text(
          widget.title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeColors.textPrimary,
          ),
        ),
        actions: [
          // Active Company Selector Dropdown (Hidden for regular members/users)
          if (!showUnifiedBranding && authProvider.userCompanies.isNotEmpty) ...[
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: themeColors.textPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeColors.borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: authProvider.activeCompany?.id,
                    dropdownColor: themeColors.cardBackground,
                    icon: Icon(Icons.arrow_drop_down, color: themeColors.textSecondary, size: 18),
                    style: GoogleFonts.inter(color: themeColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    isDense: true,
                    borderRadius: BorderRadius.circular(12),
                    onChanged: (val) async {
                      if (val != null) {
                        final nextComp = authProvider.userCompanies.firstWhere((c) => c.id == val);
                        await authProvider.setActiveCompany(nextComp);
                        if (mounted) {
                          // Reload dynamic menus
                          context.read<MenuProvider>().loadMyMenus();
                          // Force pushReplacement of current route to reload data matching new company context
                          final currentRouteName = ModalRoute.of(context)?.settings.name;
                          if (currentRouteName != null) {
                            Navigator.of(context).pushReplacementNamed(currentRouteName);
                          }
                        }
                      }
                    },
                    items: authProvider.userCompanies.map((c) {
                      return DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(c.name, style: GoogleFonts.inter(color: themeColors.textPrimary)),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],

          // Superadmin & admin payment notifications bell
          if (authProvider.roleCode == 'superadmin' || authProvider.roleCode == 'admin') ...[
            const NotificacionBell(),
            const SizedBox(width: 8),
          ],

          // Language switcher
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: themeColors.textPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: themeColors.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureButton(
                    label: 'ES',
                    isSelected: languageProvider.currentLanguageCode == 'es',
                    onTap: () => languageProvider.setLanguage('es'),
                  ),
                  GestureButton(
                    label: 'EN',
                    isSelected: languageProvider.currentLanguageCode == 'en',
                    onTap: () => languageProvider.setLanguage('en'),
                  ),
                  GestureButton(
                    label: 'FR',
                    isSelected: languageProvider.currentLanguageCode == 'fr',
                    onTap: () => languageProvider.setLanguage('fr'),
                  ),
                ],
              ),
            ),
          ),

          // Theme mode switcher
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: themeProvider.isDarkMode ? Colors.amberAccent : Colors.amber,
            ),
            tooltip: themeProvider.isDarkMode ? 'Modo Claro' : 'Modo Oscuro',
            onPressed: () => themeProvider.toggleTheme(),
          ),

          // Logout button
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: context.tr('logout'),
            onPressed: () async {
              menuProvider.clearMyMenus();
              context.read<NotificacionProvider>().stopPolling();
              context.read<ReferidoProvider>().resetSilent();
              context.read<RifaProvider>().resetSilent();
              await authProvider.logout();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (!isMobile)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: themeProvider.isSidebarCollapsed ? 0 : 300,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  width: 300,
                  child: buildSidebarContent(),
                ),
              ),
            ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: themeColors.gradientBg,
                ),
              ),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper button for the language switcher bar.
class GestureButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const GestureButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : themeColors.textPrimary.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
