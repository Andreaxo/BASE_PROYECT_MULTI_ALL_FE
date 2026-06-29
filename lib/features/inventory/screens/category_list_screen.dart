import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../menu/providers/menu_provider.dart';
import '../models/category_model.dart';
import '../providers/category_provider.dart';
import 'category_form_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
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
          'Eliminar Categoría',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar la categoría "${category.name}" (ID: ${category.id})?',
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
              await context.read<CategoryProvider>().deleteCategory(category.id);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final menuProvider = context.watch<MenuProvider>();

    final allowedMenu = menuProvider.findAllowedMenu('/categories');
    final canView = allowedMenu != null;
    final canEdit = allowedMenu?.permissions.contains('EDIT') ?? false;

    // Filter categories based on search
    final filteredCategories = categoryProvider.categories.where((cat) {
      final matchesSearch = cat.name.toLowerCase().contains(_searchQuery) ||
          cat.id.toString().contains(_searchQuery);
      return matchesSearch;
    }).toList();

    // Pagination calculations
    final totalRows = filteredCategories.length;
    final totalPages = (totalRows / _rowsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    final paginatedCategories = filteredCategories.sublist(
      startIndex,
      endIndex > totalRows ? totalRows : endIndex,
    );

    return DashboardShell(
      title: 'Categorías de Inventario',
      child: !canView
          ? _buildAccessDeniedWidget()
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Create Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Administración de Categorías',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Organiza los artículos de tu catálogo en categorías.',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (canEdit)
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToForm(),
                            icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                            label: Text(
                              'Nueva Categoría',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Search Field Card
                  Card(
                    color: const Color(0xFF131129),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: GoogleFonts.inter(color: Colors.white),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
                                  hintText: 'Buscar categoría por nombre o ID...',
                                  hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.3)),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Data Table Card (Stretched)
                  Expanded(
                    child: categoryProvider.isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
                        : totalRows == 0
                            ? _buildEmptyStateWidget()
                            : Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF131129),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.05),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          return SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.vertical,
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  minWidth: constraints.maxWidth,
                                                ),
                                                child: DataTable(
                                                  headingRowColor: WidgetStateProperty.all(
                                                    Colors.white.withOpacity(0.02),
                                                  ),
                                                  dataRowHeight: 65,
                                                  columns: [
                                                    DataColumn(
                                                      label: Text(
                                                        'ID',
                                                        style: GoogleFonts.inter(
                                                          color: const Color(0xFF4ECDC4),
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    DataColumn(
                                                      label: Text(
                                                        'Nombre',
                                                        style: GoogleFonts.inter(
                                                          color: const Color(0xFF4ECDC4),
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    DataColumn(
                                                      label: Text(
                                                        'Estado',
                                                        style: GoogleFonts.inter(
                                                          color: const Color(0xFF4ECDC4),
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    if (canEdit)
                                                      DataColumn(
                                                        label: Text(
                                                          'Acciones',
                                                          style: GoogleFonts.inter(
                                                            color: const Color(0xFF4ECDC4),
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                  rows: paginatedCategories.map((cat) {
                                                    return DataRow(
                                                      cells: [
                                                        DataCell(Text('#${cat.id}', style: GoogleFonts.inter(color: Colors.white54))),
                                                        DataCell(Text(
                                                          cat.name,
                                                          style: GoogleFonts.inter(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        )),
                                                        DataCell(
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: cat.isActive
                                                                  ? const Color(0xFF4ECDC4).withOpacity(0.1)
                                                                  : const Color(0xFFFF6B6B).withOpacity(0.1),
                                                              borderRadius: BorderRadius.circular(20),
                                                              border: Border.all(
                                                                color: cat.isActive
                                                                    ? const Color(0xFF4ECDC4).withOpacity(0.3)
                                                                    : const Color(0xFFFF6B6B).withOpacity(0.3),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              cat.isActive ? 'Activo' : 'Inactivo',
                                                              style: GoogleFonts.inter(
                                                                color: cat.isActive
                                                                    ? const Color(0xFF4ECDC4)
                                                                    : const Color(0xFFFF6B6B),
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        if (canEdit)
                                                          DataCell(
                                                            Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                IconButton(
                                                                  icon: const Icon(Icons.edit_rounded, color: Color(0xFF6C63FF), size: 20),
                                                                  tooltip: 'Editar',
                                                                  onPressed: () => _navigateToForm(category: cat),
                                                                ),
                                                                IconButton(
                                                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF6B6B), size: 20),
                                                                  tooltip: 'Eliminar',
                                                                  onPressed: () => _showDeleteDialog(cat),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                      ],
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    
                                    // Pagination Footer
                                    if (totalPages > 1) _buildPaginationFooter(totalPages),
                                  ],
                                ),
                              ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaginationFooter(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Página $_currentPage de $totalPages',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70, size: 16),
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'No se encontraron categorías',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Prueba modificando los filtros de búsqueda'
                : 'Empieza por crear una nueva categoría de inventario.',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
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
}
