import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../menu/models/menu_model.dart';
import '../../menu/providers/menu_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final roleProvider = context.watch<RoleProvider>();
    final menuProvider = context.read<MenuProvider>();

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

    return DashboardShell(
      title: 'Gestión de Roles',
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search & Add Bar
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
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
                if (canEdit) ...[
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToForm(),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      'Nuevo Rol',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Main Table Container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                clipBehavior: Clip.antiAlias,
                child: roleProvider.isLoading && roleProvider.roles.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF),
                        ),
                      )
                    : roleProvider.errorMessage != null && roleProvider.roles.isEmpty
                        ? _buildErrorWidget(roleProvider)
                        : filteredRoles.isEmpty
                            ? _buildEmptyWidget()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        return SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                minWidth: constraints.maxWidth,
                                              ),
                                              child: Theme(
                                                data: Theme.of(context).copyWith(
                                                  dividerColor: Colors.white.withOpacity(0.05),
                                                ),
                                                child: DataTable(
                                                  headingRowColor: MaterialStateProperty.all(
                                                    Colors.white.withOpacity(0.03),
                                                  ),
                                                  headingTextStyle: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                  dataTextStyle: GoogleFonts.inter(
                                                    color: Colors.white.withOpacity(0.85),
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
                                                    if (canEdit) const DataColumn(label: Text('Acciones')),
                                                  ],
                                                  rows: paginatedRoles.map((role) {
                                                    return DataRow(
                                                      cells: [
                                                        DataCell(Text(role.id.toString())),
                                                        DataCell(Text(role.name)),
                                                        DataCell(Text(role.code)),
                                                        DataCell(Text('${role.permissions.length} reglas')),
                                                        DataCell(_buildStatusBadge(role.isActive)),
                                                        if (canEdit) DataCell(_buildActionsCell(role)),
                                                      ],
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  _buildPaginationFooter(
                                    totalItems: totalRoles,
                                    totalPages: safeTotalPages,
                                  ),
                                ],
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? const Color(0xFF4ECDC4) : const Color(0xFFFF6B6B))
            .withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (isActive ? const Color(0xFF4ECDC4) : const Color(0xFFFF6B6B))
              .withOpacity(0.3),
        ),
      ),
      child: Text(
        isActive ? 'Activo' : 'Inactivo',
        style: GoogleFonts.inter(
          color: isActive ? const Color(0xFF4ECDC4) : const Color(0xFFFF6B6B),
          fontSize: 11,
          fontWeight: FontWeight.w600,
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
          icon: const Icon(Icons.edit_outlined, color: Color(0xFF6C63FF), size: 18),
          tooltip: 'Editar',
          onPressed: () => _navigateToForm(role: role),
        ),
        IconButton(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: isSystemRole ? Colors.white24 : const Color(0xFFFF6B6B),
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
}
