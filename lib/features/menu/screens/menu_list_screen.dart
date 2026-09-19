import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_alert.dart';
import '../models/menu_model.dart';
import '../providers/menu_provider.dart';
import '../../../core/utils/export_helper.dart';
import 'package:multicliente_app/core/widgets/header_filter.dart';
import '../../../core/widgets/custom_pagination_footer.dart';
import '../../../core/utils/icon_library.dart';
import 'menu_form_screen.dart';

class MenuListScreen extends StatefulWidget {
  const MenuListScreen({super.key});

  @override
  State<MenuListScreen> createState() => _MenuListScreenState();
}

class _MenuListScreenState extends State<MenuListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Column Filters
  String _idFilter = '';
  String _labelFilter = '';
  String _routeFilter = '';
  String _sortOrderFilter = '';
  String _statusFilter = '';

  // Pagination State
  int _currentPage = 1;
  int _rowsPerPage = 8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().loadMenus();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
      _currentPage = 1;
    });
  }

  void _showDeleteDialog(MenuModel menu) {
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppTheme.darkThemeColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('delete_menu'),
          style: GoogleFonts.outfit(
            color: themeColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          context
              .tr('delete_menu_confirm')
              .replaceAll('{name}', menu.label)
              .replaceAll('{id}', menu.id.toString()),
          style: GoogleFonts.inter(color: themeColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.tr('cancel'),
              style: GoogleFonts.inter(color: themeColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<MenuProvider>();
              final success = await provider.deleteMenu(menu.id);
              if (mounted) {
                if (success) {
                  CustomAlert.show(
                    context,
                    message: 'Menú eliminado correctamente',
                    isSuccess: true,
                  );
                } else {
                  CustomAlert.show(
                    context,
                    message: provider.errorMessage ?? 'Error al eliminar menú',
                    isSuccess: false,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              context.tr('delete'),
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToForm({MenuModel? menu}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MenuFormScreen(menu: menu)),
    );
    if (result == true && mounted) {
      context.read<MenuProvider>().loadMenus();
      CustomAlert.show(
        context,
        message: 'Menú guardado correctamente',
        isSuccess: true,
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppTheme.darkThemeColors;

    final allowedMenu = menuProvider.findAllowedMenu('/menus');
    final canEdit = allowedMenu?.permissions.contains('EDIT') ?? false;
    final canCreate = allowedMenu?.permissions.contains('CREATE') ?? false;

    // 1. Filter menus
    final filteredMenus = menuProvider.menus.where((m) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesGlobal =
            m.id.toString() == query ||
            m.label.toLowerCase().contains(query) ||
            m.labelEn.toLowerCase().contains(query) ||
            m.route.toLowerCase().contains(query);
        if (!matchesGlobal) return false;
      }

      if (_idFilter.isNotEmpty && !m.id.toString().contains(_idFilter))
        return false;
      if (_labelFilter.isNotEmpty &&
          !m.label.toLowerCase().contains(_labelFilter.toLowerCase()))
        return false;
      if (_routeFilter.isNotEmpty &&
          !m.route.toLowerCase().contains(_routeFilter.toLowerCase()))
        return false;
      if (_sortOrderFilter.isNotEmpty &&
          !m.sortOrder.toString().contains(_sortOrderFilter))
        return false;
      if (_statusFilter.isNotEmpty) {
        final statusText = m.isActive ? 'activo' : 'inactivo';
        if (!statusText.contains(_statusFilter.toLowerCase())) return false;
      }

      return true;
    }).toList();

    // 2. Paginate
    final totalMenus = filteredMenus.length;
    final totalPages = (totalMenus / _rowsPerPage).ceil();
    final safeTotalPages = totalPages == 0 ? 1 : totalPages;

    if (_currentPage > safeTotalPages) {
      _currentPage = safeTotalPages;
    }

    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    final paginatedMenus = filteredMenus.sublist(
      startIndex,
      endIndex > totalMenus ? totalMenus : endIndex,
    );

    // Calculate metrics
    final activeMenusCount = menuProvider.menus.where((m) => m.isActive).length;
    final totalMenusCount = menuProvider.menus.length;

    return DashboardShell(
      title: 'Menús',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            Row(
              children: [
                Text(
                  'Admin',
                  style: GoogleFonts.inter(
                    color: themeColors.textSecondary.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: themeColors.textSecondary.withValues(alpha: 0.5),
                  size: 14,
                ),
                Text(
                  'Menús',
                  style: GoogleFonts.inter(
                    color: themeColors.textPrimary.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gestión de Menús',
                  style: GoogleFonts.outfit(
                    color: themeColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (canCreate)
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToForm(),
                      icon: const Icon(
                        Icons.add_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      label: Text(
                        context.tr('new_button'),
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Stat Cards Row
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: context.tr('active_menus'),
                    value: activeMenusCount.toString(),
                    icon: Icons.menu_open_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    label: context.tr('total_menus'),
                    value: totalMenusCount.toString(),
                    icon: Icons.list_alt_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    label: context.tr('sync'),
                    value: context.tr('sync_complete'),
                    icon: Icons.sync_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Content Card
            Card(
              color: themeColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: themeColors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Actions Bar (Search + Exports)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: themeColors.textPrimary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: themeColors.borderColor,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: GoogleFonts.inter(
                                color: themeColors.textPrimary,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: context.tr('search_menu_hint'),
                                hintStyle: GoogleFonts.inter(
                                  color: themeColors.textSecondary.withValues(alpha: 
                                    0.5,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: themeColors.textSecondary.withValues(alpha: 
                                    0.5,
                                  ),
                                  size: 20,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.close_rounded,
                                          color: themeColors.textSecondary
                                              .withValues(alpha: 0.5),
                                          size: 18,
                                        ),
                                        onPressed: () =>
                                            _searchController.clear(),
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildExportButton(
                          label: 'Excel',
                          icon: Icons.table_chart_rounded,
                          color: const Color(0xFF107C41),
                          onPressed: () =>
                              _exportData(format: 'excel', data: filteredMenus),
                        ),
                        const SizedBox(width: 8),
                        _buildExportButton(
                          label: 'PDF',
                          icon: Icons.picture_as_pdf_rounded,
                          color: const Color(0xFFE02424),
                          onPressed: () =>
                              _exportData(format: 'pdf', data: filteredMenus),
                        ),
                        const SizedBox(width: 8),
                        _buildExportButton(
                          label: 'Imprimir',
                          icon: Icons.print_rounded,
                          color: AppColors.primary,
                          onPressed: () =>
                              _exportData(format: 'print', data: filteredMenus),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),

                  menuProvider.isLoading && menuProvider.menus.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : menuProvider.errorMessage != null &&
                            menuProvider.menus.isEmpty
                      ? _buildErrorWidget(menuProvider)
                      : filteredMenus.isEmpty
                      ? _buildEmptyWidget()
                      : Column(
                          children: [
                             LayoutBuilder(
                               builder: (context, constraints) {
                                 final minTableWidth = 800.0;
                                 final tableWidth = constraints.maxWidth > minTableWidth
                                     ? constraints.maxWidth - 2
                                     : minTableWidth;

                                 return Container(
                                   decoration: BoxDecoration(
                                     color: themeColors.cardBackground,
                                     borderRadius: BorderRadius.circular(16),
                                     border: Border.all(color: themeColors.borderColor),
                                   ),
                                   clipBehavior: Clip.antiAlias,
                                   child: SingleChildScrollView(
                                     scrollDirection: Axis.horizontal,
                                     child: SizedBox(
                                       width: tableWidth,
                                       child: Column(
                                         crossAxisAlignment: CrossAxisAlignment.stretch,
                                         children: [
                                           // Custom Header
                                           Container(
                                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                             decoration: const BoxDecoration(
                                               color: AppColors.tableHeaderBg,
                                               borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                             ),
                                             child: DefaultTextStyle.merge(
                                               style: GoogleFonts.inter(
                                                 color: Colors.white,
                                                 fontWeight: FontWeight.bold,
                                                 fontSize: 13,
                                               ),
                                               child: Row(
                                                 children: [
                                                   Expanded(flex: 1, child: _buildHeaderFilter(context.tr('id'), (val) => setState(() => _idFilter = val))),
                                                   Expanded(flex: 3, child: _buildHeaderFilter(context.tr('menu_label'), (val) => setState(() => _labelFilter = val))),
                                                   Expanded(flex: 3, child: _buildHeaderFilter(context.tr('route_path'), (val) => setState(() => _routeFilter = val))),
                                                   Expanded(flex: 1, child: Align(alignment: Alignment.center, child: Text(context.tr('icon')))),
                                                   Expanded(flex: 1, child: _buildHeaderFilter(context.tr('sort_order'), (val) => setState(() => _sortOrderFilter = val))),
                                                   Expanded(flex: 2, child: _buildHeaderFilter(context.tr('status'), (val) => setState(() => _statusFilter = val))),
                                                   if (canEdit) SizedBox(width: 100, child: Align(alignment: Alignment.centerRight, child: Text(context.tr('actions')))),
                                                 ],
                                               ),
                                             ),
                                           ),
                                           // Custom Rows
                                           ...paginatedMenus.map((menu) {
                                             return _MenuRow(
                                               menu: menu,
                                               themeColors: themeColors,
                                               actionsWidget: _buildActionsCell(menu),
                                               canEdit: canEdit,
                                             );
                                           }).toList(),
                                         ],
                                       ),
                                     ),
                                   ),
                                 );
                               },
                             ),
                            CustomPaginationFooter(
                              totalItems: totalMenus,
                              currentPage: _currentPage,
                              rowsPerPage: _rowsPerPage,
                              onPageChanged: (newPage) =>
                                  setState(() => _currentPage = newPage),
                              onRowsPerPageChanged: (newSize) => setState(() {
                                _rowsPerPage = newSize;
                                _currentPage = 1;
                              }),
                            ),
                          ],
                        ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bottom informational cards row
            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: 'Navegación Dinámica',
                    content:
                        'El menú lateral se construye en tiempo real a partir del árbol de menús permitidos según el rol asignado al usuario. Esto permite restringir accesos desde la interfaz.',
                    icon: Icons.alt_route_rounded,
                    iconColor: const Color(0xFF4ECDC4),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InfoCard(
                    title: 'Asociación de Jerarquías',
                    content:
                        'Los menús que poseen un parent ID actúan como submódulos o carpetas colapsables (como Inventario). Al definir un rol, se asocian permisos específicos por módulo.',
                    icon: Icons.account_tree_outlined,
                    iconColor: const Color(0xFF6C63FF),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCell(MenuModel menu) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(
            Icons.edit_outlined,
            color: AppColors.accent,
            size: 18,
          ),
          tooltip: 'Editar',
          onPressed: () => _navigateToForm(menu: menu),
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.error,
            size: 18,
          ),
          tooltip: 'Eliminar',
          onPressed: () => _showDeleteDialog(menu),
        ),
      ],
    );
  }


  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 14),
            Text(
              'No se encontraron menús',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(MenuProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.7),
          ),
          const SizedBox(height: 14),
          Text(
            provider.errorMessage!,
            style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => provider.loadMenus(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Reintentar',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        elevation: 0,
      ),
    );
  }

  Widget _buildHeaderFilter(String title, ValueChanged<String> onChanged) {
    return HeaderFilter(
      title: title,
      onChanged: (val) {
        onChanged(val);
        setState(() {
          _currentPage = 1;
        });
      },
    );
  }

  String _getTranslatedLabel(BuildContext context, MenuModel menu) {
    final languageCode = Localizations.localeOf(context).languageCode.toLowerCase();
    switch (languageCode) {
      case 'en':
        return menu.labelEn.isNotEmpty ? menu.labelEn : menu.label;
      case 'fr':
        return menu.labelFr.isNotEmpty ? menu.labelFr : menu.label;
      default:
        return menu.label;
    }
  }

  void _exportData({
    required String format,
    required List<MenuModel> data,
  }) async {
    final headers = [
      'ID',
      context.tr('menu_label'),
      context.tr('route_path'),
      context.tr('icon'),
      context.tr('sort_order'),
      context.tr('status'),
    ];
    final rows = data
        .map(
          (m) => [
            m.id.toString().padLeft(3, '0'),
            _getTranslatedLabel(context, m),
            m.route,
            m.icon,
            m.sortOrder.toString(),
            m.isActive ? 'Activo' : 'Inactivo',
          ],
        )
        .toList();

    try {
      if (format == 'excel') {
        await ExportHelper.exportToExcel(
          headers: headers,
          rows: rows,
          filename: 'reporte_menus_${DateTime.now().millisecondsSinceEpoch}',
        );
        CustomAlert.show(
          context,
          message: context.tr('export_excel_success'),
          isSuccess: true,
        );
      } else {
        final now = DateTime.now();
        final dateStr =
            '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
        await ExportHelper.exportToPdfAndPrint(
          title: 'Reporte de Menús - $dateStr',
          headers: headers,
          rows: rows,
        );
      }
    } catch (e) {
      CustomAlert.show(
        context,
        message: '${context.tr('error_occurred')}: $e',
        isSuccess: false,
      );
    }
  }
}

// ── Custom full-width responsive menu row with hover animations ──
class _MenuRow extends StatefulWidget {
  final MenuModel menu;
  final AppThemeColors themeColors;
  final Widget actionsWidget;
  final bool canEdit;

  const _MenuRow({
    required this.menu,
    required this.themeColors,
    required this.actionsWidget,
    required this.canEdit,
  });

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _isHovered = false;

  String _getTranslatedLabel(BuildContext context, MenuModel menu) {
    final languageCode = Localizations.localeOf(context).languageCode.toLowerCase();
    switch (languageCode) {
      case 'en':
        return menu.labelEn.isNotEmpty ? menu.labelEn : menu.label;
      case 'fr':
        return menu.labelFr.isNotEmpty ? menu.labelFr : menu.label;
      default:
        return menu.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = widget.menu;
    final themeColors = widget.themeColors;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isHovered 
              ? themeColors.cardBackground.withRed(30).withGreen(30).withBlue(50).withValues(alpha: 0.4)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: _isHovered 
                  ? AppColors.primary.withValues(alpha: 0.4) 
                  : themeColors.borderColor,
              width: _isHovered ? 1.2 : 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                menu.id.toString().padLeft(3, '0'),
                style: GoogleFonts.inter(
                  color: themeColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                _getTranslatedLabel(context, menu),
                style: GoogleFonts.inter(
                  color: themeColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                menu.route,
                style: GoogleFonts.inter(
                  color: themeColors.textPrimary.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.center,
                child: Icon(
                  IconLibrary.getIcon(menu.icon),
                  size: 18,
                  color: themeColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                menu.sortOrder.toString(),
                style: GoogleFonts.inter(
                  color: themeColors.textPrimary.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  label: menu.isActive ? 'Activo' : 'Inactivo',
                  isActive: menu.isActive,
                ),
              ),
            ),
            if (widget.canEdit)
              SizedBox(
                width: 100,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: widget.actionsWidget,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
