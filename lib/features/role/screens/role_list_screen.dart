import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/custom_badge.dart';
import '../../../core/widgets/custom_alert.dart';
import '../../menu/providers/menu_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../models/role_model.dart';
import '../providers/role_provider.dart';
import '../../../core/utils/export_helper.dart';
import 'package:multicliente_app/core/widgets/header_filter.dart';
import '../../../core/widgets/custom_pagination_footer.dart';
import 'role_form_screen.dart';

class RoleListScreen extends StatefulWidget {
  const RoleListScreen({super.key});

  @override
  State<RoleListScreen> createState() => _RoleListScreenState();
}

class _RoleListScreenState extends State<RoleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Column Filters
  String _idFilter = '';
  String _nameFilter = '';
  String _codeFilter = '';
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
      context.read<RoleProvider>().loadRoles();
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

  void _showDeleteDialog(Role role) {
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('delete_role'),
          style: GoogleFonts.outfit(
            color: themeColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          context.tr('delete_role_confirm')
              .replaceAll('{name}', role.name)
              .replaceAll('{id}', role.id.toString()),
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
              final provider = context.read<RoleProvider>();
              final success = await provider.deleteRole(role.id);
              if (mounted) {
                if (success) {
                  CustomAlert.show(
                    context,
                    message: 'Rol eliminado correctamente',
                    isSuccess: true,
                  );
                } else {
                  CustomAlert.show(
                    context,
                    message: provider.errorMessage ?? 'Error al eliminar rol',
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

  void _navigateToForm({Role? role}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoleFormScreen(role: role),
      ),
    );
    if (result == true && mounted) {
      context.read<RoleProvider>().loadRoles();
      context.read<MenuProvider>().loadMyMenus();
      CustomAlert.show(
        context,
        message: 'Rol guardado correctamente',
        isSuccess: true,
      );
    }
  }

  String _getLastModifiedText(List<Role> roles) {
    if (roles.isEmpty) return 'Hace 2 horas';
    DateTime? latest;
    for (var r in roles) {
      try {
        if (r.updateAt != null) {
          final dt = DateTime.parse(r.updateAt!);
          if (latest == null || dt.isAfter(latest)) {
            latest = dt;
          }
        }
      } catch (_) {}
    }
    if (latest == null) return 'Hace 2 horas';
    final diff = DateTime.now().difference(latest);
    if (diff.inMinutes < 1) return 'Hace segundos';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} mins';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} horas';
    return 'Hace ${diff.inDays} días';
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = context.watch<RoleProvider>();
    final menuProvider = context.read<MenuProvider>();
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;

    final allowedMenu = menuProvider.findAllowedMenu('/roles');
    final canEdit = allowedMenu?.permissions.contains('EDIT') ?? false;
    final canCreate = allowedMenu?.permissions.contains('CREATE') ?? false;

    // 1. Filter roles
    final filteredRoles = roleProvider.roles.where((role) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesGlobal = role.id.toString() == query ||
            role.name.toLowerCase().contains(query) ||
            role.code.toLowerCase().contains(query);
        if (!matchesGlobal) return false;
      }
      
      if (_idFilter.isNotEmpty && !role.id.toString().contains(_idFilter)) return false;
      if (_nameFilter.isNotEmpty && !role.name.toLowerCase().contains(_nameFilter.toLowerCase())) return false;
      if (_codeFilter.isNotEmpty && !role.code.toLowerCase().contains(_codeFilter.toLowerCase())) return false;
      if (_statusFilter.isNotEmpty) {
        final statusText = role.isActive ? 'activo' : 'inactivo';
        if (!statusText.contains(_statusFilter.toLowerCase())) return false;
      }
      if (_createByFilter.isNotEmpty) {
        final creator = (role.createByName ?? 'System').toLowerCase();
        if (!creator.contains(_createByFilter.toLowerCase())) return false;
      }
      if (_createAtFilter.isNotEmpty) {
        final dateStr = _formatDate(role.createAt).toLowerCase();
        if (!dateStr.contains(_createAtFilter.toLowerCase())) return false;
      }
      
      return true;
    }).toList();

    // 2. Paginate
    final totalRoles = filteredRoles.length;
    final totalPages = (totalRoles / _rowsPerPage).ceil();
    final safeTotalPages = totalPages == 0 ? 1 : totalPages;

    if (_currentPage > safeTotalPages) {
      _currentPage = safeTotalPages;
    }

    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    final paginatedRoles = filteredRoles.sublist(
      startIndex,
      endIndex > totalRoles ? totalRoles : endIndex,
    );

    // Stats calculations
    final activeRolesCount = roleProvider.roles.where((r) => r.isActive).length;
    final totalPermissionsCount = roleProvider.roles.fold<int>(0, (sum, r) => sum + r.permissions.length);
    final lastModText = _getLastModifiedText(roleProvider.roles);

    return DashboardShell(
      title: 'Gestión de Roles',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            Row(
              children: [
                Text('Admin', style: GoogleFonts.inter(color: themeColors.textSecondary.withValues(alpha: 0.5), fontSize: 13)),
                Icon(Icons.chevron_right_rounded, color: themeColors.textSecondary.withValues(alpha: 0.5), size: 14),
                Text('Gestión de Roles', style: GoogleFonts.inter(color: themeColors.textPrimary.withValues(alpha: 0.8), fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('role_management'),
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
                        context.tr('add_role'),
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
                    label: context.tr('active_roles'),
                    value: activeRolesCount.toString(),
                    icon: Icons.shield_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    label: context.tr('assigned_permissions'),
                    value: totalPermissionsCount.toString(),
                    icon: Icons.lock_open_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    label: context.tr('last_modification'),
                    value: lastModText,
                    icon: Icons.history_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Bar & Table Card
            Card(
              color: themeColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: themeColors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search header inside the card
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
                                hintText: context.tr('search_role_hint'),
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
                          onPressed: () => _exportData(format: 'excel', data: filteredRoles),
                        ),
                        const SizedBox(width: 8),
                        _buildExportButton(
                          label: 'PDF',
                          icon: Icons.picture_as_pdf_rounded,
                          color: const Color(0xFFE02424),
                          onPressed: () => _exportData(format: 'pdf', data: filteredRoles),
                        ),
                        const SizedBox(width: 8),
                        _buildExportButton(
                          label: context.tr('print'),
                          icon: Icons.print_rounded,
                          color: AppColors.primary,
                          onPressed: () => _exportData(format: 'print', data: filteredRoles),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),

                  roleProvider.isLoading && roleProvider.roles.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : roleProvider.errorMessage != null && roleProvider.roles.isEmpty
                          ? _buildErrorWidget(roleProvider)
                          : filteredRoles.isEmpty
                              ? _buildEmptyWidget()
                              : Column(
                                  children: [
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final minTableWidth = 1000.0;
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
                                                          Expanded(flex: 2, child: _buildHeaderFilter(context.tr('role_name'), (val) => setState(() => _nameFilter = val))),
                                                          Expanded(flex: 2, child: _buildHeaderFilter(context.tr('unique_code'), (val) => setState(() => _codeFilter = val))),
                                                          Expanded(flex: 3, child: Align(alignment: Alignment.centerLeft, child: Text(context.tr('assigned_permissions')))),
                                                          Expanded(flex: 2, child: _buildHeaderFilter(context.tr('status'), (val) => setState(() => _statusFilter = val))),
                                                          Expanded(flex: 2, child: _buildHeaderFilter(context.tr('created_by'), (val) => setState(() => _createByFilter = val))),
                                                          Expanded(flex: 2, child: _buildHeaderFilter(context.tr('created_at'), (val) => setState(() => _createAtFilter = val))),
                                                           if (canEdit) SizedBox(width: 100, child: Align(alignment: Alignment.centerRight, child: Text(context.tr('actions')))),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  // Custom Rows
                                                  ...paginatedRoles.map((role) {
                                                    return _RoleRow(
                                                      role: role,
                                                      themeColors: themeColors,
                                                      actionsWidget: _buildActionsCell(role),
                                                      formattedDate: _formatDate(role.createAt),
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
                                       totalItems: totalRoles,
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

            // Bottom informational cards row
            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: 'Sobre los Roles',
                    content: 'Los roles definen el conjunto de permisos que un usuario tiene dentro del sistema. El rol de Super Administrador tiene acceso total y no puede ser eliminado por seguridad de la instancia.',
                    icon: Icons.info_outline_rounded,
                    iconColor: const Color(0xFF4ECDC4),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InfoCard(
                    title: 'Seguridad y Auditoría',
                    content: 'Cada cambio en la estructura de roles es registrado para auditoría. Los cambios en el Super Administrador requieren aprobación de clave de seguridad secundaria.',
                    icon: Icons.security_rounded,
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

  Widget _buildActionsCell(Role role) {
    // Prevent deleting superadmin system role
    final isSystemRole = role.code == 'superadmin';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.accent, size: 18),
          tooltip: 'Editar',
          onPressed: () => _navigateToForm(role: role),
        ),
        IconButton(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: isSystemRole ? Colors.white24 : AppColors.error,
            size: 18,
          ),
          tooltip: isSystemRole ? 'Rol de sistema (protegido)' : 'Eliminar',
          onPressed: isSystemRole ? null : () => _showDeleteDialog(role),
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
              'No se encontraron roles',
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

  Widget _buildErrorWidget(RoleProvider provider) {
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
            onPressed: () => provider.loadRoles(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Reintentar', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getCreatorName(String? name, int? id) {
    if (name == null) {
      if (id != null && id != 0) return 'Usuario #$id';
      return 'System';
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      if (id != null && id != 0) return 'Usuario #$id';
      return 'System';
    }
    return trimmed;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    if (dateStr.startsWith('0001-01-01')) return '-';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      if (dateTime.year <= 1970) return '-';
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (_) {
      final cleanDate = dateStr.split('T')[0];
      if (cleanDate.startsWith('0001-01-01')) return '-';
      return cleanDate;
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

  void _exportData({required String format, required List<Role> data}) async {
    final headers = ['ID', 'Nombre de Rol', 'Código único', 'Permisos', 'Estado', 'Creado por', 'Creado el'];
    final rows = data.map((r) => [
      r.id.toString().padLeft(3, '0'),
      r.name,
      r.code,
      '${r.permissions.length} reglas',
      r.isActive ? 'Activo' : 'Inactivo',
      _getCreatorName(r.createByName, r.createBy),
      _formatDate(r.createAt),
    ]).toList();

    try {
      if (format == 'excel') {
        await ExportHelper.exportToExcel(
          headers: headers,
          rows: rows,
          filename: 'reporte_roles_${DateTime.now().millisecondsSinceEpoch}',
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
          title: 'Reporte de Roles - $dateStr',
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

// ── Custom full-width responsive role row with hover animations ──
class _RoleRow extends StatefulWidget {
  final Role role;
  final AppThemeColors themeColors;
  final Widget actionsWidget;
  final String formattedDate;
  final bool canEdit;

  const _RoleRow({
    required this.role,
    required this.themeColors,
    required this.actionsWidget,
    required this.formattedDate,
    required this.canEdit,
  });

  @override
  State<_RoleRow> createState() => _RoleRowState();
}

class _RoleRowState extends State<_RoleRow> {
  bool _isHovered = false;

  String _getCreatorName(String? name, int? id) {
    if (name == null) {
      if (id != null && id != 0) return 'Usuario #$id';
      return 'System';
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      if (id != null && id != 0) return 'Usuario #$id';
      return 'System';
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role;
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
                role.id.toString().padLeft(3, '0'),
                style: GoogleFonts.inter(
                  color: themeColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                role.name,
                style: GoogleFonts.inter(
                  color: themeColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                role.code,
                style: GoogleFonts.inter(
                  color: themeColors.textPrimary.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: CustomBadge(
                  label: '${role.permissions.length} reglas',
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  label: role.isActive ? 'Activo' : 'Inactivo',
                  isActive: role.isActive,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _getCreatorName(role.createByName, role.createBy),
                style: GoogleFonts.inter(
                  color: themeColors.textPrimary.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                widget.formattedDate,
                style: GoogleFonts.inter(
                  color: themeColors.textPrimary.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
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
