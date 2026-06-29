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
import '../../menu/models/menu_model.dart';
import '../../menu/providers/menu_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../models/role_model.dart';
import '../providers/role_provider.dart';
import 'role_form_screen.dart';

class RoleListScreen extends StatefulWidget {
  const RoleListScreen({super.key});

  @override
  State<RoleListScreen> createState() => _RoleListScreenState();
}

class _RoleListScreenState extends State<RoleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar rol',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar el rol ${role.name} (ID: ${role.id})?',
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<RoleProvider>().deleteRole(role.id);
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

  void _navigateToForm({Role? role}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoleFormScreen(role: role),
      ),
    );
    if (result == true && mounted) {
      context.read<RoleProvider>().loadRoles();
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

    // Check permissions
    final allowedMenu = menuProvider.myMenus.firstWhere(
      (m) => m.route == '/roles',
      orElse: () => AllowedMenu(
        id: 0,
        label: '',
        labelEn: '',
        route: '',
        icon: '',
        sortOrder: 0,
        permissions: [],
      ),
    );
    final canEdit = allowedMenu.permissions.contains('EDIT');

    // 1. Filter roles
    final filteredRoles = roleProvider.roles.where((role) {
      if (_searchQuery.isEmpty) return true;
      return role.id.toString() == _searchQuery ||
          role.name.toLowerCase().contains(_searchQuery) ||
          role.code.toLowerCase().contains(_searchQuery);
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
                Text('Admin', style: GoogleFonts.inter(color: themeColors.textSecondary.withOpacity(0.5), fontSize: 13)),
                Icon(Icons.chevron_right_rounded, color: themeColors.textSecondary.withOpacity(0.5), size: 14),
                Text('Gestión de Roles', style: GoogleFonts.inter(color: themeColors.textPrimary.withOpacity(0.8), fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gestión de Roles',
                  style: GoogleFonts.outfit(
                    color: themeColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (canEdit)
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
                        'Nuevo Rol',
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
                    label: 'Roles Activos',
                    value: activeRolesCount.toString(),
                    icon: Icons.shield_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    label: 'Permisos Totales',
                    value: totalPermissionsCount.toString(),
                    icon: Icons.lock_open_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    label: 'Última Modificación',
                    value: lastModText,
                    icon: Icons.history_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Bar & Table Container
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search header inside the card
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Buscar por ID, nombre o código...',
                          hintStyle: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.35),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Colors.white.withOpacity(0.4),
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close_rounded,
                                      color: Colors.white.withOpacity(0.5), size: 18),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  Divider(color: Colors.white.withOpacity(0.05), height: 1),

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
                                                columns: [
                                                  const DataColumn(label: Text('ID')),
                                                  const DataColumn(label: Text('Nombre de Rol')),
                                                  const DataColumn(label: Text('Código único')),
                                                  const DataColumn(label: Text('Permisos asignados')),
                                                  const DataColumn(label: Text('Estado')),
                                                  const DataColumn(label: Text('Creado por')),
                                                  const DataColumn(label: Text('Creado el')),
                                                  if (canEdit) const DataColumn(label: Text('Acciones')),
                                                ],
                                                rows: paginatedRoles.map((role) {
                                                  return DataRow(
                                                    cells: [
                                                      DataCell(Text(role.id.toString().padLeft(3, '0'))),
                                                      DataCell(Text(role.name)),
                                                      DataCell(Text(role.code)),
                                                      DataCell(CustomBadge(label: '${role.permissions.length} reglas')),
                                                      DataCell(StatusBadge(label: role.isActive ? 'Activo' : 'Inactivo', isActive: role.isActive)),
                                                      DataCell(
                                                        Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            CircleAvatar(
                                                              radius: 10,
                                                              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
                                                              child: Text(
                                                                (role.createByName ?? 'SY').substring(0, 1).toUpperCase(),
                                                                style: GoogleFonts.inter(color: const Color(0xFF4ECDC4), fontSize: 9, fontWeight: FontWeight.bold),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Text(role.createByName ?? 'System'),
                                                          ],
                                                        ),
                                                      ),
                                                      DataCell(Text(_formatDate(role.createAt))),
                                                      if (canEdit) DataCell(_buildActionsCell(role)),
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
                                      totalItems: totalRoles,
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

  Widget _buildPaginationFooter({
    required int totalItems,
    required int totalPages,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.015),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: $totalItems roles encontrados',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          Row(
            children: [
              Text(
                'Filas por página: ',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
              DropdownButton<int>(
                value: _rowsPerPage,
                dropdownColor: const Color(0xFF1E1E2E),
                underline: const SizedBox.shrink(),
                iconEnabledColor: Colors.white38,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
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
                color: Colors.white70,
                disabledColor: Colors.white.withOpacity(0.15),
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              Text(
                'Pág. $_currentPage de $totalPages',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                color: Colors.white70,
                disabledColor: Colors.white.withOpacity(0.15),
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
              'No se encontraron roles',
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

  Widget _buildErrorWidget(RoleProvider provider) {
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
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.7),
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

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (_) {
      return dateStr.split('T')[0];
    }
  }
}
