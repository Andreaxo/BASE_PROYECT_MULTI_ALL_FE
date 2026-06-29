import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../models/menu_model.dart';
import '../providers/menu_provider.dart';
import 'menu_form_screen.dart';

class MenuListScreen extends StatefulWidget {
  const MenuListScreen({super.key});

  @override
  State<MenuListScreen> createState() => _MenuListScreenState();
}

class _MenuListScreenState extends State<MenuListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar menú',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar el menú "${menu.label}" (ID: ${menu.id})?',
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
              await context.read<MenuProvider>().deleteMenu(menu.id);
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

  void _navigateToForm({MenuModel? menu}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenuFormScreen(menu: menu),
      ),
    );
    if (result == true && mounted) {
      context.read<MenuProvider>().loadMenus();
    }
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
      default:
        return Icons.grid_view_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();

    // Check permissions
    final allowedMenu = menuProvider.myMenus.firstWhere(
      (m) => m.route == '/menus',
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

    // 1. Filter menus
    final filteredMenus = menuProvider.menus.where((m) {
      if (_searchQuery.isEmpty) return true;
      return m.id.toString() == _searchQuery ||
          m.label.toLowerCase().contains(_searchQuery) ||
          m.labelEn.toLowerCase().contains(_searchQuery) ||
          m.route.toLowerCase().contains(_searchQuery);
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

    return DashboardShell(
      title: 'Gestión de Menús',
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
                        hintText: 'Buscar por ID, label, inglés o ruta...',
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
                      'Nuevo Menú',
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
                child: menuProvider.isLoading && menuProvider.menus.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF),
                        ),
                      )
                    : menuProvider.errorMessage != null && menuProvider.menus.isEmpty
                        ? _buildErrorWidget(menuProvider)
                        : filteredMenus.isEmpty
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
                                                    const DataColumn(label: Text('Ícono')),
                                                    const DataColumn(label: Text('Etiqueta (ES)')),
                                                    const DataColumn(label: Text('Etiqueta (EN)')),
                                                    const DataColumn(label: Text('Ruta de Enlace')),
                                                    const DataColumn(label: Text('Orden')),
                                                    const DataColumn(label: Text('Estado')),
                                                    if (canEdit) const DataColumn(label: Text('Acciones')),
                                                  ],
                                                  rows: paginatedMenus.map((menu) {
                                                    return DataRow(
                                                      cells: [
                                                        DataCell(Text(menu.id.toString())),
                                                        DataCell(Icon(
                                                          _getIconData(menu.icon),
                                                          color: const Color(0xFF4ECDC4),
                                                          size: 18,
                                                        )),
                                                        DataCell(Text(menu.label)),
                                                        DataCell(Text(menu.labelEn)),
                                                        DataCell(Text(
                                                          menu.route,
                                                          style: GoogleFonts.inter(color: const Color(0xFF6C63FF)),
                                                        )),
                                                        DataCell(Text(menu.sortOrder.toString())),
                                                        DataCell(_buildStatusBadge(menu.isActive)),
                                                        if (canEdit) DataCell(_buildActionsCell(menu)),
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
                                    totalItems: totalMenus,
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

  Widget _buildActionsCell(MenuModel menu) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Color(0xFF6C63FF), size: 18),
          tooltip: 'Editar',
          onPressed: () => _navigateToForm(menu: menu),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF6B6B), size: 18),
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
            'Total: $totalItems menús encontrados',
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
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => provider.loadMenus(),
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
