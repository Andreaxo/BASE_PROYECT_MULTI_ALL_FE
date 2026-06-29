import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/menu/models/menu_model.dart';
import '../../features/menu/providers/menu_provider.dart';

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
      if (menuProvider.myMenus.isEmpty) {
        menuProvider.loadMyMenus();
      }
    });
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'people_rounded':
        return Icons.people_rounded;
      case 'business_rounded':
        return Icons.business_rounded;
      case 'admin_panel_settings_rounded':
        return Icons.admin_panel_settings_rounded;
      case 'menu_rounded':
        return Icons.menu_rounded;
      case 'inventory_2_rounded':
        return Icons.inventory_2_rounded;
      case 'category_rounded':
        return Icons.category_rounded;
      case 'inventory_rounded':
        return Icons.inventory_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  Widget _buildMenuItem(AllowedMenu item, String? currentRoute, String langCode, AppThemeColors themeColors) {
    final label = langCode == 'es' ? item.label : (langCode == 'fr' ? item.labelFr : item.labelEn);

    if (item.submenus.isNotEmpty) {
      final isAnySubSelected = item.submenus.any((sub) => currentRoute == sub.route);

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isAnySubSelected ? themeColors.textPrimary.withOpacity(0.02) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAnySubSelected ? themeColors.borderColor : Colors.transparent,
            width: 1,
          ),
        ),
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
                  ? AppColors.primary.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.3)
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
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                _getIconData(sub.icon),
                color: isSelected
                    ? AppColors.accent
                    : themeColors.textSecondary.withOpacity(0.8),
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

    final menus = menuProvider.myMenus;

    Widget buildSidebarContent() {
      return Container(
        width: 260,
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
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.hub_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PLATAFORMA',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: themeColors.textPrimary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Multicliente Base',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: themeColors.textSecondary,
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
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
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
                          authProvider.roleCode.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
        backgroundColor: themeColors.sidebarBg.withOpacity(0.8),
        elevation: 0,
        leading: isMobile
            ? Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu_rounded, color: themeColors.textPrimary),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        title: Text(
          widget.title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeColors.textPrimary,
          ),
        ),
        actions: [
          // Active Company Selector Dropdown
          if (authProvider.userCompanies.isNotEmpty) ...[
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: themeColors.textPrimary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: themeColors.borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: authProvider.activeCompany?.id,
                    dropdownColor: themeColors.cardBackground,
                    icon: Icon(Icons.arrow_drop_down, color: themeColors.textSecondary, size: 18),
                    style: GoogleFonts.inter(color: themeColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
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
                        child: Text(c.name),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],

          // Language switcher
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: themeColors.textPrimary.withOpacity(0.05),
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
              await authProvider.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (!isMobile) buildSidebarContent(),
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
            color: isSelected ? Colors.white : themeColors.textPrimary.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
