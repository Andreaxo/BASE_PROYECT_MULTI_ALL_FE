import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
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

  Widget _buildMenuItem(AllowedMenu item, String? currentRoute, String langCode) {
    final label = langCode == 'es' ? item.label : item.labelEn;

    if (item.submenus.isNotEmpty) {
      final isAnySubSelected = item.submenus.any((sub) => currentRoute == sub.route);

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isAnySubSelected ? Colors.white.withOpacity(0.02) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAnySubSelected ? Colors.white.withOpacity(0.05) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            unselectedWidgetColor: Colors.white30,
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4ECDC4),
            ),
          ),
          child: ExpansionTile(
            initiallyExpanded: isAnySubSelected,
            leading: Icon(
              _getIconData(item.icon),
              color: isAnySubSelected ? const Color(0xFF4ECDC4) : Colors.white.withOpacity(0.5),
              size: 20,
            ),
            title: Text(
              label,
              style: GoogleFonts.inter(
                color: isAnySubSelected ? Colors.white : Colors.white.withOpacity(0.7),
                fontWeight: isAnySubSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            childrenPadding: const EdgeInsets.only(left: 12, bottom: 8),
            children: item.submenus.map((sub) => _buildSubMenuItem(sub, currentRoute, langCode)).toList(),
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
                  ? const Color(0xFF6C63FF).withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF6C63FF).withOpacity(0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getIconData(item.icon),
                  color: isSelected
                      ? const Color(0xFF4ECDC4)
                      : Colors.white.withOpacity(0.5),
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
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
                      color: Color(0xFF4ECDC4),
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

  Widget _buildSubMenuItem(AllowedMenu sub, String? currentRoute, String langCode) {
    final isSelected = currentRoute == sub.route;
    final label = langCode == 'es' ? sub.label : sub.labelEn;

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
                ? const Color(0xFF6C63FF).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                _getIconData(sub.icon),
                color: isSelected
                    ? const Color(0xFF4ECDC4)
                    : Colors.white.withOpacity(0.4),
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
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
                    color: Color(0xFF4ECDC4),
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

    final menus = menuProvider.myMenus;

    Widget buildSidebarContent() {
      return Container(
        width: 260,
        decoration: BoxDecoration(
          color: const Color(0xFF131129),
          border: Border(
            right: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.5),
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
                        colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
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
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Multicliente Base',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 16),

            // Navigation Items (Hierarchical mapping)
            Expanded(
              child: menuProvider.isLoading && menus.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6C63FF),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: menus.map((item) => _buildMenuItem(item, currentRoute, languageProvider.currentLanguageCode)).toList(),
                      ),
                    ),
            ),

            // Profile info at bottom
            const Divider(color: Colors.white10, height: 1),
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
                    child: Text(
                      authProvider.userName.isNotEmpty ? authProvider.userName[0].toUpperCase() : 'U',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF4ECDC4),
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
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          authProvider.roleCode.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF4ECDC4),
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
      backgroundColor: const Color(0xFF0F0C29),
      drawer: isMobile ? Drawer(child: buildSidebarContent()) : null,
      appBar: AppBar(
        backgroundColor: const Color(0xFF131129).withOpacity(0.8),
        elevation: 0,
        leading: isMobile
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        title: Text(
          widget.title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: authProvider.activeCompany?.id,
                    dropdownColor: const Color(0xFF1E1E2E),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
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
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
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
          
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B)),
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F0C29),
                    Color(0xFF1A1A2E),
                  ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
