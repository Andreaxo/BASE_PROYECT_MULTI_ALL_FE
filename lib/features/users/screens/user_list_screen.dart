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
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import 'user_form_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Pagination State
  int _currentPage = 1;
  int _rowsPerPage = 8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.tr('cancel'),
              style: GoogleFonts.inter(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<UserProvider>().deleteUser(user.id);
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
      MaterialPageRoute(
        builder: (_) => UserFormScreen(user: user),
      ),
    );
    if (result == true && mounted) {
      context.read<UserProvider>().loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;

    // 1. Filter users based on query
    final filteredUsers = userProvider.users.where((user) {
      if (_searchQuery.isEmpty) return true;
      return user.id.toString() == _searchQuery ||
          user.firstName.toLowerCase().contains(_searchQuery) ||
          user.lastName.toLowerCase().contains(_searchQuery) ||
          user.email.toLowerCase().contains(_searchQuery);
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
                Text('Admin', style: GoogleFonts.inter(color: themeColors.textSecondary.withOpacity(0.5), fontSize: 13)),
                Icon(Icons.chevron_right_rounded, color: themeColors.textSecondary.withOpacity(0.5), size: 14),
                Text('Usuarios', style: GoogleFonts.inter(color: themeColors.textPrimary.withOpacity(0.8), fontSize: 13)),
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
                  // Search bar header inside card
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
                          hintText: context.tr('search_hint'),
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

                  userProvider.isLoading && userProvider.users.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : userProvider.errorMessage != null && userProvider.users.isEmpty
                          ? _buildErrorWidget(userProvider)
                          : filteredUsers.isEmpty
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
                                                columnSpacing: 35,
                                                columns: [
                                                  const DataColumn(label: Text('ID')),
                                                  DataColumn(label: Text(context.tr('full_name'))),
                                                  DataColumn(label: Text(context.tr('email'))),
                                                  DataColumn(label: Text(context.tr('status'))),
                                                  DataColumn(label: Text(context.tr('created_by'))),
                                                  DataColumn(label: Text(context.tr('created_at'))),
                                                  DataColumn(label: Text(context.tr('actions'))),
                                                ],
                                                rows: paginatedUsers.map((user) {
                                                  return DataRow(
                                                    cells: [
                                                      DataCell(Text(user.id.toString().padLeft(3, '0'))),
                                                      DataCell(Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          CircleAvatar(
                                                            radius: 12,
                                                            backgroundColor: user.isActive
                                                                ? AppColors.primary.withOpacity(0.2)
                                                                : Colors.white.withOpacity(0.1),
                                                            child: Text(
                                                              user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '',
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
                                                          Text(user.fullName),
                                                        ],
                                                      )),
                                                      DataCell(Text(user.email)),
                                                      DataCell(StatusBadge(label: user.isActive ? 'Activo' : 'Inactivo', isActive: user.isActive)),
                                                      DataCell(Text(user.createByName ?? user.createBy?.toString() ?? '-')),
                                                      DataCell(Text(_formatDate(user.createAt))),
                                                      DataCell(_buildActionsCell(user)),
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
                    content: 'Visualice y administre las cuentas de los usuarios asignados al sistema base multicliente. Habilite o deshabilite perfiles de manera instantánea.',
                    icon: Icons.assignment_ind_outlined,
                    iconColor: const Color(0xFF4ECDC4),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InfoCard(
                    title: 'Control de Seguridad',
                    content: 'Los usuarios deben poseer roles válidos con permisos asignados para acceder a los módulos de negocio. Los cambios de rol se aplican en la siguiente sesión.',
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
          icon: const Icon(Icons.edit_outlined, color: AppColors.accent, size: 18),
          tooltip: context.tr('edit'),
          onPressed: () => _navigateToForm(user: user),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
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
            '${context.tr('total')}: $totalItems ${context.tr('users_found')}',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          Row(
            children: [
              Text(
                '${context.tr('rows_per_page')}: ',
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
                '${context.tr('page')} $_currentPage ${context.tr('of')} $totalPages',
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
              context.tr('no_results'),
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

  Widget _buildErrorWidget(UserProvider provider) {
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
            onPressed: () => provider.loadUsers(),
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
