import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../menu/models/menu_model.dart';
import '../../menu/providers/menu_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../models/company_model.dart';
import '../providers/company_provider.dart';
import 'company_form_screen.dart';

class CompanyListScreen extends StatefulWidget {
  const CompanyListScreen({super.key});

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Pagination State
  int _currentPage = 1;
  int _rowsPerPage = 8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompanyProvider>().loadCompanies();
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

  void _showDeleteDialog(Company company) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar empresa',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar la empresa ${company.name} (ID: ${company.id})?',
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
              await context.read<CompanyProvider>().deleteCompany(company.id);
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

  void _navigateToForm({Company? company}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyFormScreen(company: company),
      ),
    );
    if (result == true && mounted) {
      context.read<CompanyProvider>().loadCompanies();
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyProvider = context.watch<CompanyProvider>();
    final menuProvider = context.read<MenuProvider>();
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;

    // Check permissions
    final allowedMenu = menuProvider.myMenus.firstWhere(
      (m) => m.route == '/companies',
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

    // 1. Filter companies
    final filteredCompanies = companyProvider.companies.where((company) {
      if (_searchQuery.isEmpty) return true;
      return company.id.toString() == _searchQuery ||
          company.name.toLowerCase().contains(_searchQuery);
    }).toList();

    // 2. Paginate
    final totalCompanies = filteredCompanies.length;
    final totalPages = (totalCompanies / _rowsPerPage).ceil();
    final safeTotalPages = totalPages == 0 ? 1 : totalPages;

    if (_currentPage > safeTotalPages) {
      _currentPage = safeTotalPages;
    }

    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    final paginatedCompanies = filteredCompanies.sublist(
      startIndex,
      endIndex > totalCompanies ? totalCompanies : endIndex,
    );

    // Calculate metrics
    final activeCompaniesCount = companyProvider.companies.where((c) => c.isActive).length;
    final totalCompaniesCount = companyProvider.companies.length;

    return DashboardShell(
      title: 'Empresas',
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
                Text('Empresas', style: GoogleFonts.inter(color: themeColors.textPrimary.withOpacity(0.8), fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gestión de Empresas',
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
                    label: 'Empresas Activas',
                    value: activeCompaniesCount.toString(),
                    icon: Icons.business_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    label: 'Empresas Totales',
                    value: totalCompaniesCount.toString(),
                    icon: Icons.corporate_fare_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    label: 'Estado General',
                    value: 'Activo',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Table Matrix Container
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
                  // Search Header inside card
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
                          hintText: 'Buscar por ID o nombre...',
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

                  companyProvider.isLoading && companyProvider.companies.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : companyProvider.errorMessage != null && companyProvider.companies.isEmpty
                          ? _buildErrorWidget(companyProvider)
                          : filteredCompanies.isEmpty
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
                                                  const DataColumn(label: Text('Nombre de la Empresa')),
                                                  const DataColumn(label: Text('Estado')),
                                                  DataColumn(label: Text(context.tr('created_by'))),
                                                  DataColumn(label: Text(context.tr('created_at'))),
                                                  if (canEdit) const DataColumn(label: Text('Acciones')),
                                                ],
                                                rows: paginatedCompanies.map((company) {
                                                  return DataRow(
                                                    cells: [
                                                      DataCell(Text(company.id.toString().padLeft(3, '0'))),
                                                      DataCell(Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          CircleAvatar(
                                                            radius: 12,
                                                            backgroundColor: company.isActive
                                                                ? const Color(0xFF6C63FF).withOpacity(0.2)
                                                                : Colors.white.withOpacity(0.1),
                                                            child: Text(
                                                              company.name.isNotEmpty ? company.name[0].toUpperCase() : '',
                                                              style: GoogleFonts.outfit(
                                                                color: company.isActive
                                                                    ? const Color(0xFF4ECDC4)
                                                                    : Colors.white60,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 11,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 10),
                                                          Text(company.name),
                                                        ],
                                                      )),
                                                      DataCell(StatusBadge(label: company.isActive ? 'Activo' : 'Inactivo', isActive: company.isActive)),
                                                      DataCell(Text(company.createByName ?? company.createBy?.toString() ?? '-')),
                                                      DataCell(Text(_formatDate(company.createAt))),
                                                      if (canEdit) DataCell(_buildActionsCell(company)),
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
                                      totalItems: totalCompanies,
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
                    title: 'Sobre las Empresas',
                    content: 'Las empresas estructuran el acceso multicliente en la base de datos. Cada usuario puede estar asociado a una o más empresas para delimitar su espacio de trabajo y visualización.',
                    icon: Icons.corporate_fare_rounded,
                    iconColor: const Color(0xFF4ECDC4),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InfoCard(
                    title: 'Aislamiento de Datos',
                    content: 'Cualquier catálogo u operación realizada en el inventario o configuración general está estrictamente filtrada por el identificador de la empresa activa del usuario.',
                    icon: Icons.lock_outline_rounded,
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

  Widget _buildActionsCell(Company company) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.accent, size: 18),
          tooltip: 'Editar',
          onPressed: () => _navigateToForm(company: company),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
          tooltip: 'Eliminar',
          onPressed: () => _showDeleteDialog(company),
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
            'Total: $totalItems empresas encontradas',
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
              'No se encontraron empresas',
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

  Widget _buildErrorWidget(CompanyProvider provider) {
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
            onPressed: () => provider.loadCompanies(),
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
