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
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;
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
          context.tr('delete_menu_confirm')
              .replaceAll('{name}', menu.label)
              .replaceAll('{id}', menu.id.toString()),
          style: GoogleFonts.inter(
            color: themeColors.textSecondary,
          ),
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
      MaterialPageRoute(
        builder: (_) => MenuFormScreen(menu: menu),
      ),
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

  IconData _getIconData(String iconName) {
    return IconLibrary.getIcon(iconName);
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;

    final allowedMenu = menuProvider.findAllowedMenu('/menus');
    final canEdit = allowedMenu?.permissions.contains('EDIT') ?? false;
    final canCreate = allowedMenu?.permissions.contains('CREATE') ?? false;

    // 1. Filter menus
    final filteredMenus = menuProvider.menus.where((m) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesGlobal = m.id.toString() == query ||
            m.label.toLowerCase().contains(query) ||
            m.labelEn.toLowerCase().contains(query) ||
            m.route.toLowerCase().contains(query);
        if (!matchesGlobal) return false;
      }
      
      if (_idFilter.isNotEmpty && !m.id.toString().contains(_idFilter)) return false;
      if (_labelFilter.isNotEmpty && !m.label.toLowerCase().contains(_labelFilter.toLowerCase())) return false;
      if (_routeFilter.isNotEmpty && !m.route.toLowerCase().contains(_routeFilter.toLowerCase())) return false;
      if (_sortOrderFilter.isNotEmpty && !m.sortOrder.toString().contains(_sortOrderFilter)) return false;
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
                Text('Admin', style: GoogleFonts.inter(color: themeColors.textSecondary.withOpacity(0.5), fontSize: 13)),
                Icon(Icons.chevron_right_rounded, color: themeColors.textSecondary.withOpacity(0.5), size: 14),
                Text('Menús', style: GoogleFonts.inter(color: themeColors.textPrimary.withOpacity(0.8), fontSize: 13)),
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
                      icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                      label: Text(
                        context.tr('new_button'),
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                              color: themeColors.textPrimary.withOpacity(0.05),
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
                                  color: themeColors.textSecondary.withOpacity(0.5),
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: themeColors.textSecondary.withOpacity(0.5),
                                  size: 20,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.close_rounded,
                                          color: themeColors.textSecondary.withOpacity(0.5),
                                          size: 18,
                                        ),
                                        onPressed: () => _searchController.clear(),
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
                          onPressed: () => _exportData(format: 'excel', data: filteredMenus),
                        ),
                        const SizedBox(width: 8),
                        _buildExportButton(
                          label: 'PDF',
                          icon: Icons.picture_as_pdf_rounded,
                          color: const Color(0xFFE02424),
                          onPressed: () => _exportData(format: 'pdf', data: filteredMenus),
                        ),
                        const SizedBox(width: 8),
                        _buildExportButton(
                          label: 'Imprimir',
                          icon: Icons.print_rounded,
                          color: AppColors.primary,
                          onPressed: () => _exportData(format: 'print', data: filteredMenus),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white.withOpacity(0.05), height: 1),

                  menuProvider.isLoading && menuProvider.menus.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : menuProvider.errorMessage != null && menuProvider.menus.isEmpty
                          ? _buildErrorWidget(menuProvider)
                          : filteredMenus.isEmpty
                              ? _buildEmptyWidget()
                              : Column(
                                  children: [
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        return SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minWidth: constraints.maxWidth,
                                            ),
                                            child: Theme(
                                              data: Theme.of(context).copyWith(
                                                dividerColor: themeColors.borderColor,
                                              ),
                                              child: DataTable(
                                                headingRowColor: WidgetStateProperty.all(
                                                  themeColors.textPrimary.withOpacity(0.03),
                                                ),
                                                headingTextStyle: GoogleFonts.inter(
                                                  color: themeColors.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                                dataTextStyle: GoogleFonts.inter(
                                                  color: themeColors.textPrimary.withOpacity(0.85),
                                                  fontSize: 13,
                                                ),
                                                horizontalMargin: 20,
                                                columnSpacing: 40,
                                                headingRowHeight: 64.0,
                                                columns: [
                                                  DataColumn(label: SizedBox(height: 32, child: Align(alignment: Alignment.centerLeft, child: _buildHeaderFilter(context.tr('id'), (val) => setState(() => _idFilter = val))))),
                                                  DataColumn(label: SizedBox(height: 32, child: Align(alignment: Alignment.centerLeft, child: _buildHeaderFilter(context.tr('label_es'), (val) => setState(() => _labelFilter = val))))),
                                                  DataColumn(label: SizedBox(height: 32, child: Align(alignment: Alignment.centerLeft, child: Text(context.tr('label_en'))))),
                                                  DataColumn(label: SizedBox(height: 32, child: Align(alignment: Alignment.centerLeft, child: Text(context.tr('label_fr'))))),
                                                  DataColumn(label: SizedBox(height: 32, child: Align(alignment: Alignment.centerLeft, child: _buildHeaderFilter(context.tr('route_path'), (val) => setState(() => _routeFilter = val))))),
                                                  DataColumn(label: SizedBox(height: 32, child: Align(alignment: Alignment.centerLeft, child: Text(context.tr('icon'))))),
                                                  DataColumn(label: SizedBox(height: 32, child: Align(alignment: Alignment.centerLeft, child: _buildHeaderFilter(context.tr('sort_order'), (val) => setState(() => _sortOrderFilter = val))))),
                                                  DataColumn(label: SizedBox(height: 32, child: Align(alignment: Alignment.centerLeft, child: _buildHeaderFilter(context.tr('status'), (val) => setState(() => _statusFilter = val))))),
                                                  if (canEdit)
                                                    DataColumn(label: SizedBox(height: 32, child: Align(alignment: Alignment.centerLeft, child: Text(context.tr('actions'))))),
                                                ],
                                                rows: paginatedMenus.map((menu) {
                                                  return DataRow(
                                                    cells: [
                                                      DataCell(Text(menu.id.toString().padLeft(3, '0'))),
                                                      DataCell(Text(menu.label)),
                                                      DataCell(Text(menu.labelEn)),
                                                      DataCell(Text(menu.labelFr)),
                                                      DataCell(Text(menu.route)),
                                                      DataCell(Icon(_getIconData(menu.icon), color: const Color(0xFF4ECDC4), size: 18)),
                                                      DataCell(Text(menu.sortOrder.toString())),
                                                      DataCell(StatusBadge(label: menu.isActive ? 'Activo' : 'Inactivo', isActive: menu.isActive)),
                                                      if (canEdit) DataCell(_buildActionsCell(menu)),
                                                    ],
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    _buildPaginationFooter(
                                      totalItems: totalMenus,
                                      totalPages: safeTotalPages,
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
                    content: 'El menú lateral se construye en tiempo real a partir del árbol de menús permitidos según el rol asignado al usuario. Esto permite restringir accesos desde la interfaz.',
                    icon: Icons.alt_route_rounded,
                    iconColor: const Color(0xFF4ECDC4),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InfoCard(
                    title: 'Asociación de Jerarquías',
                    content: 'Los menús que poseen un parent ID actúan como submódulos o carpetas colapsables (como Inventario). Al definir un rol, se asocian permisos específicos por módulo.',
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
          icon: const Icon(Icons.edit_outlined, color: AppColors.accent, size: 18),
          tooltip: 'Editar',
          onPressed: () => _navigateToForm(menu: menu),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
          tooltip: 'Eliminar',
          onPressed: () => _showDeleteDialog(menu),
        ),
      ],
    );
  }

  Widget _buildPaginationFooter({
    required int totalItems,
    required int totalPages,
  }) {
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: themeColors.textPrimary.withOpacity(0.01),
        border: Border(
          top: BorderSide(color: themeColors.borderColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${context.tr('total') ?? 'Total'}: $totalItems',
            style: GoogleFonts.inter(
              color: themeColors.textSecondary,
              fontSize: 12,
            ),
          ),
          Row(
            children: [
              Text(
                context.tr('rows_per_page'),
                style: GoogleFonts.inter(
                  color: themeColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              DropdownButton<int>(
                value: _rowsPerPage,
                dropdownColor: themeColors.cardBackground,
                underline: const SizedBox.shrink(),
                iconEnabledColor: themeColors.textSecondary,
                style: GoogleFonts.inter(color: themeColors.textPrimary, fontSize: 12),
                items: [5, 8, 10, 15].map((size) {
                  return DropdownMenuItem<int>(
                    value: size,
                    child: Text('  $size  '),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _rowsPerPage = val;
                      _currentPage = 1;
                    });
                  }
                },
              ),
              const SizedBox(width: 14),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                color: themeColors.textPrimary,
                disabledColor: themeColors.textSecondary.withOpacity(0.3),
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              Text(
                '${context.tr('page')} $_currentPage ${context.tr('of')} $totalPages',
                style: GoogleFonts.inter(
                  color: themeColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                color: themeColors.textPrimary,
                disabledColor: themeColors.textSecondary.withOpacity(0.3),
                onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          ),
        ],
      ),
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
              color: Colors.white.withOpacity(0.15),
            ),
            const SizedBox(height: 14),
            Text(
              'No se encontraron menús',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.4),
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
            color: const Color(0xFFFF6B6B).withOpacity(0.7),
          ),
          const SizedBox(height: 14),
          Text(
            provider.errorMessage!,
            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7)),
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
      label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.4)),
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

  void _exportData({required String format, required List<MenuModel> data}) async {
    final headers = ['ID', 'Etiqueta (ES)', 'Etiqueta (EN)', 'Etiqueta (FR)', 'Ruta de Acceso', 'Ícono', 'Orden', 'Estado'];
    final rows = data.map((m) => [
      m.id.toString().padLeft(3, '0'),
      m.label,
      m.labelEn,
      m.labelFr,
      m.route,
      m.icon,
      m.sortOrder.toString(),
      m.isActive ? 'Activo' : 'Inactivo',
    ]).toList();

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
        final dateStr = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
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
