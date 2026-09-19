import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../menu/providers/menu_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_alert.dart';
import '../models/category_model.dart';
import '../providers/category_provider.dart';
import '../../../core/utils/export_helper.dart';
import 'package:multicliente_app/core/widgets/header_filter.dart';
import '../../../core/widgets/custom_pagination_footer.dart';
import 'category_form_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Column Filters
  String _idFilter = '';
  String _nameFilter = '';
  String _statusFilter = '';
  String _createByFilter = '';
  String _createAtFilter = '';

  // Pagination State
  int _currentPage = 1;
  int _rowsPerPage = 8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
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

  void _showDeleteDialog(Category category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('delete_category_title'),
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          context.tr('delete_category_confirm')
              .replaceAll('{name}', category.name)
              .replaceAll('{id}', category.id.toString()),
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<CategoryProvider>();
              final success = await provider.deleteCategory(category.id);
              if (mounted) {
                if (success) {
                  CustomAlert.show(
                    context,
                    message: 'Categoría eliminada correctamente',
                    isSuccess: true,
                  );
                } else {
                  CustomAlert.show(
                    context,
                    message: provider.errorMessage ?? 'Error al eliminar categoría',
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
              'Eliminar',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToForm({Category? category}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryFormScreen(category: category),
      ),
    );

    if (result == true && mounted) {
      context.read<CategoryProvider>().loadCategories();
      CustomAlert.show(
        context,
        message: 'Categoría guardada correctamente',
        isSuccess: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final menuProvider = context.watch<MenuProvider>();
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;

    final allowedMenu = menuProvider.findAllowedMenu('/categories');
    final canView = allowedMenu != null;
    final canCreate = allowedMenu?.permissions.contains('CREATE') ?? false;
    final canEdit = allowedMenu?.permissions.contains('EDIT') ?? false;
    final canDelete = allowedMenu?.permissions.contains('DELETE') ?? false;

    // Filter categories based on search and column filters
    final filteredCategories = categoryProvider.categories.where((cat) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch = cat.name.toLowerCase().contains(query) ||
            cat.id.toString().contains(query);
        if (!matchesSearch) return false;
      }
      
      if (_idFilter.isNotEmpty && !cat.id.toString().contains(_idFilter)) return false;
      if (_nameFilter.isNotEmpty && !cat.name.toLowerCase().contains(_nameFilter.toLowerCase())) return false;
      if (_statusFilter.isNotEmpty) {
        final statusText = cat.isActive ? 'activo' : 'inactivo';
        if (!statusText.contains(_statusFilter.toLowerCase())) return false;
      }
      if (_createByFilter.isNotEmpty) {
        final creator = (cat.createByName ?? cat.createBy?.toString() ?? '-').toLowerCase();
        if (!creator.contains(_createByFilter.toLowerCase())) return false;
      }
      if (_createAtFilter.isNotEmpty) {
        final dateStr = _formatDate(cat.createAt).toLowerCase();
        if (!dateStr.contains(_createAtFilter.toLowerCase())) return false;
      }
      
      return true;
    }).toList();

    // Pagination calculations
    final totalRows = filteredCategories.length;
    final totalPages = (totalRows / _rowsPerPage).ceil();
    final safeTotalPages = totalPages == 0 ? 1 : totalPages;
    if (_currentPage > safeTotalPages) {
      _currentPage = safeTotalPages;
    }
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    final paginatedCategories = filteredCategories.sublist(
      startIndex,
      endIndex > totalRows ? totalRows : endIndex,
    );

    // Calculate metrics
    final activeCount = categoryProvider.categories.where((c) => c.isActive).length;
    final totalCount = categoryProvider.categories.length;

    return DashboardShell(
      title: context.tr('category_list_title'),
      child: !canView
          ? _buildAccessDeniedWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumbs
                  Row(
                    children: [
                      Text('Inventario', style: GoogleFonts.inter(color: themeColors.textSecondary.withValues(alpha: 0.5), fontSize: 13)),
                      Icon(Icons.chevron_right_rounded, color: themeColors.textSecondary.withValues(alpha: 0.5), size: 14),
                      Text('Categorías', style: GoogleFonts.inter(color: themeColors.textPrimary.withValues(alpha: 0.8), fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('category_list_title'),
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
                              context.tr('add_category'),
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

                  // Stat cards
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Categorías Activas',
                          value: activeCount.toString(),
                          icon: Icons.category_rounded,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          label: 'Categorías Totales',
                          value: totalCount.toString(),
                          icon: Icons.folder_open_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Table matrix card
                  Card(
                    color: themeColors.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: themeColors.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Search field header
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: themeColors.textPrimary.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: themeColors.borderColor),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    style: GoogleFonts.inter(color: themeColors.textPrimary, fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: context.tr('category_search_hint'),
                                      hintStyle: GoogleFonts.inter(
                                        color: themeColors.textSecondary.withValues(alpha: 0.5),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        color: themeColors.textSecondary.withValues(alpha: 0.5),
                                        size: 20,
                                      ),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(Icons.close_rounded,
                                                  color: themeColors.textSecondary.withValues(alpha: 0.5), size: 18),
                                              onPressed: () => _searchController.clear(),
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildExportButton(
                                label: 'Excel',
                                icon: Icons.table_chart_rounded,
                                color: const Color(0xFF107C41),
                                onPressed: () => _exportData(format: 'excel', data: filteredCategories),
                              ),
                              const SizedBox(width: 8),
                              _buildExportButton(
                                label: 'PDF',
                                icon: Icons.picture_as_pdf_rounded,
                                color: const Color(0xFFE02424),
                                onPressed: () => _exportData(format: 'pdf', data: filteredCategories),
                              ),
                              const SizedBox(width: 8),
                              _buildExportButton(
                                label: context.tr('print'),
                                icon: Icons.print_rounded,
                                color: AppColors.primary,
                                onPressed: () => _exportData(format: 'print', data: filteredCategories),
                              ),
                            ],
                          ),
                        ),
                        Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),

                        categoryProvider.isLoading && categoryProvider.categories.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40.0),
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : categoryProvider.errorMessage != null && categoryProvider.categories.isEmpty
                                ? _buildErrorWidget(categoryProvider)
                                : filteredCategories.isEmpty
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
                                                        themeColors.textPrimary.withValues(alpha: 0.03),
                                                      ),
                                                      headingTextStyle: GoogleFonts.inter(
                                                        color: themeColors.textPrimary,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                      dataTextStyle: GoogleFonts.inter(
                                                        color: themeColors.textPrimary.withValues(alpha: 0.85),
                                                        fontSize: 13,
                                                      ),
                                                      horizontalMargin: 20,
                                                      columnSpacing: 40,
                                                      headingRowHeight: 64.0,
                                                      columns: [
                                                        DataColumn(label: SizedBox(height: 32, child: Align(alignment: Alignment.centerLeft, child: _buildHeaderFilter(context.tr('id'), (val) => setState(() => _idFilter = val))))),
                                                        DataColumn(label: SizedBox(height: 32, child: Align(alignment: Alignment.centerLeft, child: _buildHeaderFilter(context.tr('name'), (val) => setState(() => _nameFilter = val))))),
                                                        DataColumn(label: SizedBox(height: 32, child: Align(alignment: Alignment.centerLeft, child: _buildHeaderFilter(context.tr('status'), (val) => setState(() => _statusFilter = val))))),
                                                        DataColumn(label: SizedBox(height: 32, child: Align(alignment: Alignment.centerLeft, child: _buildHeaderFilter(context.tr('created_by'), (val) => setState(() => _createByFilter = val))))),
                                                        DataColumn(label: SizedBox(height: 32, child: Align(alignment: Alignment.centerLeft, child: _buildHeaderFilter(context.tr('created_at'), (val) => setState(() => _createAtFilter = val))))),
                                                        if (canEdit || canDelete) DataColumn(label: SizedBox(height: 32, child: Align(alignment: Alignment.centerLeft, child: Text(context.tr('actions'))))),
                                                      ],
                                                      rows: paginatedCategories.map((category) {
                                                        return DataRow(
                                                          cells: [
                                                            DataCell(Text(category.id.toString().padLeft(3, '0'))),
                                                            DataCell(Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                CircleAvatar(
                                                                  radius: 12,
                                                                  backgroundColor: category.isActive
                                                                      ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                                                                      : Colors.white.withValues(alpha: 0.1),
                                                                  child: Text(
                                                                    category.name.isNotEmpty ? category.name[0].toUpperCase() : '',
                                                                    style: GoogleFonts.outfit(
                                                                      color: category.isActive
                                                                          ? const Color(0xFF4ECDC4)
                                                                          : Colors.white60,
                                                                      fontWeight: FontWeight.bold,
                                                                      fontSize: 11,
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 10),
                                                                Text(category.name),
                                                              ],
                                                            )),
                                                            DataCell(StatusBadge(label: category.isActive ? 'Activo' : 'Inactivo', isActive: category.isActive)),
                                                            DataCell(Text(category.createByName ?? category.createBy?.toString() ?? '-')),
                                                            DataCell(Text(_formatDate(category.createAt))),
                                                            if (canEdit || canDelete) DataCell(_buildActionsCell(category, canEdit, canDelete)),
                                                          ],
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          CustomPaginationFooter(
                                            totalItems: totalRows,
                                            currentPage: _currentPage,
                                            rowsPerPage: _rowsPerPage,
                                            onPageChanged: (newPage) =>
                                                setState(() => _currentPage = newPage),
                                            onRowsPerPageChanged: (newSize) =>
                                                setState(() {
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

                  // Bottom Info Cards
                  Row(
                    children: [
                      Expanded(
                        child: InfoCard(
                          title: 'Gestión de Categorías',
                          content: 'Defina agrupaciones lógicas para organizar los artículos del catálogo de inventario de su empresa.',
                          icon: Icons.folder_special_outlined,
                          iconColor: const Color(0xFF4ECDC4),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InfoCard(
                          title: 'Aislamiento por Empresa',
                          content: 'Las categorías creadas se asocian de manera exclusiva a la empresa activa actual y no interferirán con otras entidades del sistema.',
                          icon: Icons.business_outlined,
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

  Widget _buildActionsCell(Category category, bool canEdit, bool canDelete) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canEdit)
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.accent, size: 18),
            tooltip: 'Editar',
            onPressed: () => _navigateToForm(category: category),
          ),
        if (canDelete)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
            tooltip: 'Eliminar',
            onPressed: () => _showDeleteDialog(category),
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
              context.tr('no_results'),
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

  Widget _buildErrorWidget(CategoryProvider provider) {
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
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => provider.loadCategories(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(context.tr('retry'), style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDeniedWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_person_rounded, size: 64, color: Color(0xFFFF6B6B)),
          const SizedBox(height: 16),
          Text(
            'Acceso Denegado',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'No tienes permisos para visualizar este catálogo.',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (_) {
      return dateStr.split('T')[0];
    }
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

  void _exportData({required String format, required List<Category> data}) async {
    final headers = ['ID', 'Nombre de la Categoría', 'Estado', 'Creado por', 'Creado el'];
    final rows = data.map((c) => [
      c.id.toString().padLeft(3, '0'),
      c.name,
      c.isActive ? 'Activo' : 'Inactivo',
      c.createByName ?? c.createBy?.toString() ?? '-',
      _formatDate(c.createAt),
    ]).toList();

    try {
      if (format == 'excel') {
        await ExportHelper.exportToExcel(
          headers: headers,
          rows: rows,
          filename: 'reporte_categorias_${DateTime.now().millisecondsSinceEpoch}',
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
          title: 'Reporte de Categorías - $dateStr',
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
