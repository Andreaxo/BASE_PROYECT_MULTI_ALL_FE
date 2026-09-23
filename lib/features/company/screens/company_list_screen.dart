import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/status_badge.dart';
import 'company_form_screen.dart';
import '../models/company_model.dart';
import '../../menu/providers/menu_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_alert.dart';
import '../providers/company_provider.dart';
import '../../../core/utils/export_helper.dart';
import 'package:multicliente_app/core/widgets/header_filter.dart';
import '../../../core/widgets/custom_pagination_footer.dart';

class CompanyListScreen extends StatefulWidget {
  const CompanyListScreen({super.key});

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Column Filters
  String _idFilter = '';
  String _nitFilter = '';
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
          '¿Estás seguro de que deseas eliminar la empresa ${company.name}?',
          style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7)),
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
              final provider = context.read<CompanyProvider>();
              final success = await provider.deleteCompany(company.id);
              if (mounted) {
                if (success) {
                  CustomAlert.show(
                    context,
                    message: 'Empresa eliminada correctamente.',
                    isSuccess: true,
                  );
                } else {
                  CustomAlert.show(
                    context,
                    message:
                        provider.errorMessage ?? 'No fue posible eliminar la empresa.',
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

  void _navigateToForm({Company? company}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CompanyFormScreen(company: company)),
    );
    if (result == true && mounted) {
      context.read<CompanyProvider>().loadCompanies();
      CustomAlert.show(
        context,
        message: 'Empresa guardada correctamente',
        isSuccess: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyProvider = context.watch<CompanyProvider>();
    final menuProvider = context.read<MenuProvider>();
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppTheme.darkThemeColors;

    // Check permissions
    final allowedMenu = menuProvider.findAllowedMenu('/companies');
    final canEdit = allowedMenu?.permissions.contains('EDIT') ?? false;

    // 1. Filter companies
    final filteredCompanies = companyProvider.companies.where((company) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesGlobal =
            company.id.toString() == query ||
            company.name.toLowerCase().contains(query) ||
            company.nit.toString() == (query);
        if (!matchesGlobal) return false;
      }

      if (_idFilter.isNotEmpty && !company.id.toString().contains(_idFilter))
        return false;
      if (_nameFilter.isNotEmpty &&
          !company.name.toLowerCase().contains(_nameFilter.toLowerCase()))
        return false;

      if (_nitFilter.isNotEmpty && !company.nit.toString().contains(_nitFilter))
        return false;

      if (_statusFilter.isNotEmpty) {
        final statusText = company.isActive ? 'activo' : 'inactivo';
        if (!statusText.contains(_statusFilter.toLowerCase())) return false;
      }
      if (_createByFilter.isNotEmpty) {
        final creator =
            (company.createByName ?? company.createBy?.toString() ?? '-')
                .toLowerCase();
        if (!creator.contains(_createByFilter.toLowerCase())) return false;
      }
      if (_createAtFilter.isNotEmpty) {
        final dateStr = _formatDate(company.createAt).toLowerCase();
        if (!dateStr.contains(_createAtFilter.toLowerCase())) return false;
      }

      return true;
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
    final activeCompaniesCount = companyProvider.companies
        .where((c) => c.isActive)
        .length;
    final totalCompaniesCount = companyProvider.companies.length;

    return DashboardShell(
      title: 'Negocios Aliados',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            Row(
              children: [
                Text(
                  'Administración',
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
                  'Negocios Aliados',
                  style: GoogleFonts.inter(
                    color: themeColors.textPrimary.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Header Row
            LayoutBuilder(
              builder: (context, headerConstraints) {
                final isMobile = headerConstraints.maxWidth < 650;
                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Gestión de Negocios Aliados',
                        style: GoogleFonts.outfit(
                          color: themeColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (canEdit) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
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
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Gestión de Negocios Aliados',
                        style: GoogleFonts.outfit(
                          color: themeColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
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
                );
              },
            ),
            const SizedBox(height: 24),

            // Stat Cards Row
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                final cards = [
                  StatCard(
                    label: context.tr('active_companies'),
                    value: activeCompaniesCount.toString(),
                    icon: Icons.business_outlined,
                  ),
                  StatCard(
                    label: context.tr('total_companies'),
                    value: totalCompaniesCount.toString(),
                    icon: Icons.corporate_fare_outlined,
                  ),
                  StatCard(
                    label: context.tr('status'),
                    value: context.tr('active'),
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: cards
                        .map(
                          (c) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: c,
                            ),
                          ),
                        )
                        .toList(),
                  );
                } else {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: cards
                        .map(
                          (c) => SizedBox(
                            width: constraints.maxWidth > 400
                                ? (constraints.maxWidth - 12) / 2
                                : constraints.maxWidth,
                            child: c,
                          ),
                        )
                        .toList(),
                  );
                }
              },
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
                  // Search Header inside card
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LayoutBuilder(
                      builder: (context, searchConstraints) {
                        final isCompact = searchConstraints.maxWidth < 700;
                        final searchField = Container(
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
                              hintText: context.tr('search_company_hint'),
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
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: themeColors.textSecondary.withValues(alpha: 0.5),
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
                        );

                        final exportRow = SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: isCompact ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              _buildExportButton(
                                label: 'Excel',
                                icon: Icons.table_chart_rounded,
                                color: const Color(0xFF107C41),
                                onPressed: () => _exportData(
                                  format: 'excel',
                                  data: filteredCompanies,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildExportButton(
                                label: 'PDF',
                                icon: Icons.picture_as_pdf_rounded,
                                color: const Color(0xFFE02424),
                                onPressed: () => _exportData(
                                  format: 'pdf',
                                  data: filteredCompanies,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildExportButton(
                                label: context.tr('print'),
                                icon: Icons.print_rounded,
                                color: AppColors.primary,
                                onPressed: () => _exportData(
                                  format: 'print',
                                  data: filteredCompanies,
                                ),
                              ),
                            ],
                          ),
                        );

                        if (isCompact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              searchField,
                              const SizedBox(height: 12),
                              exportRow,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: searchField),
                            const SizedBox(width: 12),
                            exportRow,
                          ],
                        );
                      },
                    ),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),

                  companyProvider.isLoading && companyProvider.companies.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : companyProvider.errorMessage != null &&
                            companyProvider.companies.isEmpty
                      ? _buildErrorWidget(companyProvider)
                      : companyProvider.companies.isEmpty
                      ? _buildEmptyWidget()
                      : Column(
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final minTableWidth = 1100.0;
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
                                                  Expanded(flex: 2, child: _buildHeaderFilter(context.tr('nit'), (val) => setState(() => _nitFilter = val))),
                                                  Expanded(flex: 3, child: _buildHeaderFilter(context.tr('company_name'), (val) => setState(() => _nameFilter = val))),
                                                  Expanded(flex: 2, child: Text(context.tr('unique_code'))),
                                                  Expanded(flex: 2, child: Text(context.tr('membership'))),
                                                  Expanded(flex: 2, child: _buildHeaderFilter(context.tr('status'), (val) => setState(() => _statusFilter = val))),
                                                  Expanded(flex: 2, child: _buildHeaderFilter(context.tr('created_at'), (val) => setState(() => _createAtFilter = val))),
                                                  if (canEdit) SizedBox(width: 100, child: Align(alignment: Alignment.centerRight, child: Text(context.tr('actions')))),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Custom Rows
                                          if (filteredCompanies.isEmpty)
                                            Container(
                                              padding: const EdgeInsets.all(48),
                                              alignment: Alignment.center,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.search_off_rounded,
                                                    size: 40,
                                                    color: themeColors.textSecondary.withValues(alpha: 0.4),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    'No se encontraron coincidencias para los filtros aplicados.',
                                                    style: GoogleFonts.inter(
                                                      color: themeColors.textSecondary,
                                                      fontSize: 13,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                            )
                                          else
                                            ...paginatedCompanies.map((company) {
                                              return _CompanyRow(
                                                company: company,
                                                themeColors: themeColors,
                                                actionsWidget: _buildActionsCell(company),
                                                formattedDate: _formatDate(company.createAt),
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
                              totalItems: totalCompanies,
                              currentPage: _currentPage,
                              rowsPerPage: _rowsPerPage,
                              onPageChanged: (newPage) =>
                                  setState(() => _currentPage = newPage),
                              onRowsPerPageChanged: (newSize) => setState(() {
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
                    title: 'Sobre las Empresas',
                    content:
                        'Las empresas estructuran el acceso multicliente en la base de datos. Cada usuario puede estar asociado a una o más empresas para delimitar su espacio de trabajo y visualización.',
                    icon: Icons.corporate_fare_rounded,
                    iconColor: const Color(0xFF4ECDC4),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InfoCard(
                    title: 'Aislamiento de Datos',
                    content:
                        'Cualquier catálogo u operación realizada en el inventario o configuración general está estrictamente filtrada por el identificador de la empresa activa del usuario.',
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
          icon: const Icon(
            Icons.edit_outlined,
            color: AppColors.accent,
            size: 18,
          ),
          tooltip: 'Editar',
          onPressed: () => _navigateToForm(company: company),
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.error,
            size: 18,
          ),
          tooltip: 'Eliminar',
          onPressed: () => _showDeleteDialog(company),
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
              'No se encontraron empresas',
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

  Widget _buildErrorWidget(CompanyProvider provider) {
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
            onPressed: () => provider.loadCompanies(),
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

  void _exportData({
    required String format,
    required List<Company> data,
  }) async {
    final headers = [
      'ID',
      'NIT',
      'Nombre de la Empresa',
      'Estado',
      'Creado por',
      'Creado en',
    ];
    final rows = data
        .map(
          (c) => [
            c.id.toString().padLeft(3, '0'),
            c.nit.toString(),
            c.name,
            c.isActive ? 'Activo' : 'Inactivo',
            _getCreatorName(c.createByName, c.createBy),
            _formatDate(c.createAt),
          ],
        )
        .toList();

    try {
      if (format == 'excel') {
        await ExportHelper.exportToExcel(
          headers: headers,
          rows: rows,
          filename: 'reporte_empresas_${DateTime.now().millisecondsSinceEpoch}',
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
          title: 'Reporte de Empresas - $dateStr',
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

// ── Custom full-width responsive company row with hover animations ──
class _CompanyRow extends StatefulWidget {
  final Company company;
  final AppThemeColors themeColors;
  final Widget actionsWidget;
  final String formattedDate;
  final bool canEdit;

  const _CompanyRow({
    required this.company,
    required this.themeColors,
    required this.actionsWidget,
    required this.formattedDate,
    required this.canEdit,
  });

  @override
  State<_CompanyRow> createState() => _CompanyRowState();
}

class _CompanyRowState extends State<_CompanyRow> {
  bool _isHovered = false;

  Widget _buildSubscriptionBadge(String status, String? fechaFin) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'activa':
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.15);
        textColor = const Color(0xFF10B981);
        label = 'Activa';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'vencida':
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
        textColor = const Color(0xFFEF4444);
        label = 'Vencida';
        icon = Icons.error_outline_rounded;
        break;
      case 'suspendida':
        bgColor = const Color(0xFF6B7280).withValues(alpha: 0.15);
        textColor = const Color(0xFF9CA3AF);
        label = 'Suspendida';
        icon = Icons.pause_circle_outline_rounded;
        break;
      case 'prueba':
      default:
        bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        textColor = const Color(0xFFF59E0B);
        label = 'Prueba';
        icon = Icons.timer_outlined;
        break;
    }

    String tooltip = 'Suscripción: $label';
    if (fechaFin != null && fechaFin.isNotEmpty) {
      try {
        final dt = DateTime.parse(fechaFin);
        tooltip += ' (Vence: ${DateFormat('dd/MM/yyyy').format(dt)})';
      } catch (_) {}
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: textColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyCodeBadge(BuildContext context, String? code, AppThemeColors themeColors) {
    if (code == null || code.isEmpty) {
      return Text(
        '—',
        style: GoogleFonts.inter(
          color: themeColors.textSecondary.withValues(alpha: 0.5),
          fontSize: 13,
        ),
      );
    }

    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        CustomAlert.show(
          context,
          message: 'Código de empresa "$code" copiado al portapapeles',
          isSuccess: true,
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: GoogleFonts.sourceCodePro(
                color: const Color(0xFF60A5FA),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.copy_rounded,
              size: 13,
              color: Color(0xFF60A5FA),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final company = widget.company;
    final themeColors = widget.themeColors;
    final initials = (company.name.isNotEmpty ? company.name[0] : '').toUpperCase();

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
                company.id.toString().padLeft(3, '0'),
                style: GoogleFonts.inter(
                  color: themeColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                company.nit.toString(),
                style: GoogleFonts.inter(
                  color: themeColors.textPrimary.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: company.isActive
                        ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.1),
                    child: Text(
                      initials,
                      style: GoogleFonts.outfit(
                        color: company.isActive ? const Color(0xFF4ECDC4) : Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      company.name,
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
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildCompanyCodeBadge(context, company.codigoEmpresa, themeColors),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildSubscriptionBadge(company.suscripcionEstado, company.fechaFinPrueba),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  label: company.isActive ? 'Activo' : 'Inactivo',
                  isActive: company.isActive,
                ),
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
