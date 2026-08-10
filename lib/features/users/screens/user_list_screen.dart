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
import '../../auth/providers/auth_provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../../../core/utils/export_helper.dart';
import 'package:multicliente_app/core/widgets/header_filter.dart';
import 'user_form_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Column Filters
  String _idFilter = '';
  String _nameFilter = '';
  String _emailFilter = '';
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
      final authProvider = context.read<AuthProvider>();
      final role = authProvider.roleCode;
      if (role == 'user' || role == 'user_member') {
        Navigator.of(context).pushReplacementNamed('/benefit');
        return;
      }
      context.read<UserProvider>().loadUsers();
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

  void _showDeleteDialog(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('delete_user'),
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '${context.tr('delete_user_confirm')} (${user.fullName})',
          style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.tr('cancel'),
              style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<UserProvider>();
              final success = await provider.deleteUser(user.id);
              if (mounted) {
                if (success) {
                  CustomAlert.show(
                    context,
                    message: 'Usuario eliminado correctamente',
                    isSuccess: true,
                  );
                } else {
                  CustomAlert.show(
                    context,
                    message:
                        provider.errorMessage ?? 'Error al eliminar usuario',
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

  void _navigateToForm({User? user}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserFormScreen(user: user)),
    );
    if (result == true && mounted) {
      context.read<UserProvider>().loadUsers();
      CustomAlert.show(
        context,
        message: 'Usuario guardado correctamente',
        isSuccess: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppTheme.darkThemeColors;

    // 1. Filter users based on query and column filters
    final filteredUsers = userProvider.users.where((user) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesGlobal =
            user.id.toString() == query ||
            user.firstName.toLowerCase().contains(query) ||
            user.lastName.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query);
        if (!matchesGlobal) return false;
      }

      if (_idFilter.isNotEmpty && !user.id.toString().contains(_idFilter))
        return false;
      if (_nameFilter.isNotEmpty &&
          !user.fullName.toLowerCase().contains(_nameFilter.toLowerCase()))
        return false;
      if (_emailFilter.isNotEmpty &&
          !user.email.toLowerCase().contains(_emailFilter.toLowerCase()))
        return false;
      if (_statusFilter.isNotEmpty) {
        final statusText = user.isActive ? 'activo' : 'inactivo';
        if (!statusText.contains(_statusFilter.toLowerCase())) return false;
      }
      if (_createByFilter.isNotEmpty) {
        final creator = (user.createByName ?? user.createBy?.toString() ?? '-')
            .toLowerCase();
        if (!creator.contains(_createByFilter.toLowerCase())) return false;
      }
      if (_createAtFilter.isNotEmpty) {
        final dateStr = _formatDate(user.createAt).toLowerCase();
        if (!dateStr.contains(_createAtFilter.toLowerCase())) return false;
      }

      return true;
    }).toList();

    // 2. Paginate filtered users
    final totalUsers = filteredUsers.length;
    final totalPages = (totalUsers / _rowsPerPage).ceil();
    final safeTotalPages = totalPages == 0 ? 1 : totalPages;

    if (_currentPage > safeTotalPages) {
      _currentPage = safeTotalPages;
    }

    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    final paginatedUsers = filteredUsers.sublist(
      startIndex,
      endIndex > totalUsers ? totalUsers : endIndex,
    );

    // Calculate metrics
    final activeUsersCount = userProvider.users.where((u) => u.isActive).length;
    final totalUsersCount = userProvider.users.length;

    return DashboardShell(
      title: context.tr('users_directory'),
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
                  'Usuarios',
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
                  context.tr('users_directory'),
                  style: GoogleFonts.outfit(
                    color: themeColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                    label: 'Usuarios Activos',
                    value: activeUsersCount.toString(),
                    icon: Icons.shield_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    label: 'Usuarios Totales',
                    value: totalUsersCount.toString(),
                    icon: Icons.people_outline_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    label: 'Estado de Servidor',
                    value: 'Online',
                    icon: Icons.cloud_done_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Table Matrix Card
            Card(
              color: themeColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: themeColors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search bar header inside card
                  Padding(
                    padding: const EdgeInsets.all(16.0),
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
                                hintText: context.tr('search_hint'),
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
                              _exportData(format: 'excel', data: filteredUsers),
                        ),
                        const SizedBox(width: 8),
                        _buildExportButton(
                          label: 'PDF',
                          icon: Icons.picture_as_pdf_rounded,
                          color: const Color(0xFFE02424),
                          onPressed: () =>
                              _exportData(format: 'pdf', data: filteredUsers),
                        ),
                        const SizedBox(width: 8),
                        _buildExportButton(
                          label: context.tr('print'),
                          icon: Icons.print_rounded,
                          color: AppColors.primary,
                          onPressed: () =>
                              _exportData(format: 'print', data: filteredUsers),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),

                  userProvider.isLoading && userProvider.users.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : userProvider.errorMessage != null &&
                            userProvider.users.isEmpty
                      ? _buildErrorWidget(userProvider)
                      : filteredUsers.isEmpty
                      ? _buildEmptyWidget()
                      : Column(
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final minTableWidth = 950.0;
                                final tableWidth =
                                    constraints.maxWidth > minTableWidth
                                    ? constraints.maxWidth - 2
                                    : minTableWidth;

                                return Container(
                                  decoration: BoxDecoration(
                                    color: themeColors.cardBackground,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: themeColors.borderColor,
                                    ),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      width: tableWidth,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Custom Header
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                            decoration: const BoxDecoration(
                                              color: AppColors.tableHeaderBg,
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(16),
                                                  ),
                                            ),
                                            child: DefaultTextStyle.merge(
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    flex: 1,
                                                    child: _buildHeaderFilter(
                                                      context.tr('id'),
                                                      (val) => setState(
                                                        () => _idFilter = val,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 3,
                                                    child: _buildHeaderFilter(
                                                      context.tr('full_name'),
                                                      (val) => setState(
                                                        () => _nameFilter = val,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 3,
                                                    child: _buildHeaderFilter(
                                                      context.tr('email'),
                                                      (val) => setState(
                                                        () =>
                                                            _emailFilter = val,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: _buildHeaderFilter(
                                                      context.tr('status'),
                                                      (val) => setState(
                                                        () =>
                                                            _statusFilter = val,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: _buildHeaderFilter(
                                                      context.tr('created_by'),
                                                      (val) => setState(
                                                        () => _createByFilter =
                                                            val,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 2,
                                                    child: _buildHeaderFilter(
                                                      context.tr('created_at'),
                                                      (val) => setState(
                                                        () => _createAtFilter =
                                                            val,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 100,
                                                    child: Align(
                                                      alignment:
                                                          Alignment.centerRight,
                                                      child: Text('Acciones'),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Custom Rows
                                          ...paginatedUsers.map((user) {
                                            return _UserRow(
                                              user: user,
                                              themeColors: themeColors,
                                              actionsWidget: _buildActionsCell(
                                                user,
                                              ),
                                              formattedDate: _formatDate(
                                                user.createAt,
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildPaginationFooter(
                              totalItems: totalUsers,
                              totalPages: safeTotalPages,
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
                    title: 'Directorio de Usuarios',
                    content:
                        'Visualice y administre las cuentas de los usuarios asignados al sistema base multicliente. Habilite o deshabilite perfiles de manera instantánea.',
                    icon: Icons.assignment_ind_outlined,
                    iconColor: const Color(0xFF4ECDC4),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InfoCard(
                    title: 'Control de Seguridad',
                    content:
                        'Los usuarios deben poseer roles válidos con permisos asignados para acceder a los módulos de negocio. Los cambios de rol se aplican en la siguiente sesión.',
                    icon: Icons.admin_panel_settings_outlined,
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

  Widget _buildActionsCell(User user) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(
            Icons.edit_outlined,
            color: AppColors.accent,
            size: 18,
          ),
          tooltip: context.tr('edit'),
          onPressed: () => _navigateToForm(user: user),
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.error,
            size: 18,
          ),
          tooltip: context.tr('delete'),
          onPressed: () => _showDeleteDialog(user),
        ),
      ],
    );
  }

  Widget _buildPaginationFooter({
    required int totalItems,
    required int totalPages,
  }) {
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppTheme.darkThemeColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: themeColors.textPrimary.withValues(alpha: 0.01),
        border: Border(top: BorderSide(color: themeColors.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${context.tr('total')}: $totalItems ${context.tr('users_found')}',
            style: GoogleFonts.inter(
              color: themeColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
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
                style: GoogleFonts.inter(
                  color: themeColors.textPrimary,
                  fontSize: 12,
                ),
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
                disabledColor: themeColors.textSecondary.withValues(alpha: 0.3),
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
                disabledColor: themeColors.textSecondary.withValues(alpha: 0.3),
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

  Widget _buildErrorWidget(UserProvider provider) {
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
            onPressed: () => provider.loadUsers(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              context.tr('retry'),
              style: GoogleFonts.inter(color: Colors.white),
            ),
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

  void _exportData({required String format, required List<User> data}) async {
    final headers = [
      'ID',
      'Nombre',
      'Correo',
      'Estado',
      'Creado por',
      'Creado en',
    ];
    final rows = data
        .map(
          (u) => [
            u.id.toString().padLeft(3, '0'),
            u.fullName,
            u.email,
            u.isActive ? 'Activo' : 'Inactivo',
            _getCreatorName(u.createByName, u.createBy),
            _formatDate(u.createAt),
          ],
        )
        .toList();

    try {
      if (format == 'excel') {
        await ExportHelper.exportToExcel(
          headers: headers,
          rows: rows,
          filename: 'reporte_usuarios_${DateTime.now().millisecondsSinceEpoch}',
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
          title: 'Reporte de Usuarios - $dateStr',
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

// ── Custom full-width responsive user row with hover animations ──
class _UserRow extends StatefulWidget {
  final User user;
  final AppThemeColors themeColors;
  final Widget actionsWidget;
  final String formattedDate;

  const _UserRow({
    required this.user,
    required this.themeColors,
    required this.actionsWidget,
    required this.formattedDate,
  });

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
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
    final user = widget.user;
    final themeColors = widget.themeColors;
    final initials = (user.firstName.isNotEmpty ? user.firstName[0] : '')
        .toUpperCase();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isHovered
              ? themeColors.cardBackground
                    .withRed(30)
                    .withGreen(30)
                    .withBlue(50)
                    .withValues(alpha: 0.4)
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
                user.id.toString().padLeft(3, '0'),
                style: GoogleFonts.inter(
                  color: themeColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: user.isActive
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.1),
                    child: Text(
                      initials,
                      style: GoogleFonts.outfit(
                        color: user.isActive
                            ? AppColors.accent
                            : Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      user.fullName,
                      style: GoogleFonts.inter(
                        color: themeColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                user.email,
                style: GoogleFonts.inter(
                  color: themeColors.textPrimary.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  label: user.isActive ? 'Activo' : 'Inactivo',
                  isActive: user.isActive,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _getCreatorName(user.createByName, user.createBy),
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
