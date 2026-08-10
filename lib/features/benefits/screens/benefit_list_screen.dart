import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/export_helper.dart';
import '../../../core/widgets/custom_alert.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/widgets/header_filter.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';
import 'package:flutter/services.dart';
import '../../company/models/company_model.dart';
import '../../company/providers/company_provider.dart';
import '../../menu/providers/menu_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/benefit_model.dart';
import '../models/redemption_model.dart';
import '../providers/benefit_provider.dart';
import '../providers/redemption_provider.dart';
import 'benefit_form_screen.dart';

class BenefitListScreen extends StatefulWidget {
  const BenefitListScreen({super.key});

  @override
  State<BenefitListScreen> createState() => _BenefitListScreenState();
}

class _BenefitListScreenState extends State<BenefitListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _memberTab = 0; // 0: Disponibles, 1: Mis Redenciones

  // Filtros de columna
  String _idFilter = '';
  String _nameFilter = '';
  String _companyFilter = '';
  String _statusFilter = '';

  // Paginación
  int _currentPage = 1;
  int _rowsPerPage = 8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BenefitProvider>().loadBenefits();
      context.read<RedemptionProvider>().loadMyRedemptions();
      // Asegurar que las empresas estén cargadas para resolución de nombres
      final companyProvider = context.read<CompanyProvider>();
      if (companyProvider.companies.isEmpty) {
        companyProvider.loadCompanies();
      }
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

  // ── Resolución del nombre de empresa ──────────────────────────────────────

  /// Devuelve razón social si existe, si no el nombre de la empresa.
  /// Si no se encuentra la empresa, devuelve el ID como string.
  String _resolveCompanyName(int companyId, List<Company> companies, [List<Company>? userCompanies]) {
    try {
      final matchInGlobal = companies.where((c) => c.id == companyId);
      if (matchInGlobal.isNotEmpty) {
        final c = matchInGlobal.first;
        final razon = c.razonSocial?.trim();
        if (razon != null && razon.isNotEmpty) return razon;
        return c.name;
      }
      if (userCompanies != null) {
        final matchInUser = userCompanies.where((c) => c.id == companyId);
        if (matchInUser.isNotEmpty) {
          final c = matchInUser.first;
          final razon = c.razonSocial?.trim();
          if (razon != null && razon.isNotEmpty) return razon;
          return c.name;
        }
      }
      return 'Negocio Aliado #$companyId';
    } catch (_) {
      return 'Negocio Aliado #$companyId';
    }
  }

  // ── Diálogo de eliminación ────────────────────────────────────────────────

  void _showDeleteDialog(Benefit benefit, List<Company> companies) {
    final companyName = _resolveCompanyName(benefit.companyBenefits, companies);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar beneficio',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14,
            ),
            children: [
              const TextSpan(
                text: '¿Estás seguro de que deseas eliminar el beneficio ',
              ),
              TextSpan(
                text: benefit.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: ' de la empresa '),
              TextSpan(
                text: companyName,
                style: const TextStyle(
                  color: Color(0xFF4ECDC4),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: '?'),
            ],
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
              final provider = context.read<BenefitProvider>();
              final success = await provider.deleteBenefit(benefit.id);
              if (mounted) {
                if (success) {
                  CustomAlert.show(
                    context,
                    message: 'Beneficio eliminado correctamente',
                    isSuccess: true,
                  );
                } else {
                  CustomAlert.show(
                    context,
                    message:
                        provider.errorMessage ?? 'Error al eliminar beneficio',
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

  void _navigateToForm({Benefit? benefit}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BenefitFormScreen(benefit: benefit)),
    );
    if (result == true && mounted) {
      context.read<BenefitProvider>().loadBenefits();
      CustomAlert.show(
        context,
        message: 'Beneficio guardado correctamente',
        isSuccess: true,
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final benefitProvider = context.watch<BenefitProvider>();
    final companyProvider = context.watch<CompanyProvider>();
    final menuProvider = context.read<MenuProvider>();
    final authProvider = context.watch<AuthProvider>();
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppTheme.darkThemeColors;
    final companies = companyProvider.companies;

    // Verificar si es un rol de tipo miembro / usuario normal
    final isMember = authProvider.roleCode == 'user' || authProvider.roleCode == 'user_member';

    // Verificar permisos
    final allowedMenu = menuProvider.findAllowedMenu('/benefit');
    final canEdit = allowedMenu?.permissions.contains('EDIT') ?? false;

    // 1. Filtrar beneficios
    final filteredBenefits = benefitProvider.benefits.where((benefit) {
      final companyName = _resolveCompanyName(
        benefit.companyBenefits,
        companies,
      ).toLowerCase();

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        final matchesGlobal =
            benefit.id.toString() == q ||
            benefit.name.toLowerCase().contains(q) ||
            companyName.contains(q);
        if (!matchesGlobal) return false;
      }
      if (_idFilter.isNotEmpty && !benefit.id.toString().contains(_idFilter)) {
        return false;
      }
      if (_nameFilter.isNotEmpty &&
          !benefit.name.toLowerCase().contains(_nameFilter.toLowerCase())) {
        return false;
      }
      if (_companyFilter.isNotEmpty &&
          !companyName.contains(_companyFilter.toLowerCase())) {
        return false;
      }
      if (_statusFilter.isNotEmpty) {
        final statusText = benefit.isActive ? 'activo' : 'inactivo';
        if (!statusText.contains(_statusFilter.toLowerCase())) return false;
      }
      return true;
    }).toList();

    // 2. Paginación
    final totalBenefits = filteredBenefits.length;
    final totalPages = (totalBenefits / _rowsPerPage).ceil();
    final safeTotalPages = totalPages == 0 ? 1 : totalPages;
    if (_currentPage > safeTotalPages) _currentPage = safeTotalPages;
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    final paginatedBenefits = filteredBenefits.sublist(
      startIndex,
      endIndex > totalBenefits ? totalBenefits : endIndex,
    );

    // Métricas
    final activeBenefits = benefitProvider.benefits
        .where((b) => b.isActive)
        .length;
    final uniqueCompanies = benefitProvider.benefits
        .map((b) => b.companyBenefits)
        .toSet()
        .length;

    return DashboardShell(
      title: 'Beneficios',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: isMember
            ? _buildMemberView(
                benefitProvider: benefitProvider,
                themeColors: themeColors,
                filteredBenefits: filteredBenefits,
                companies: companies,
                userName: authProvider.userName,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // ── Breadcrumb ──────────────────────────────────────────
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
                  'Beneficios',
                  style: GoogleFonts.inter(
                    color: themeColors.textPrimary.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Encabezado ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gestión de Beneficios',
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

            // ── Tarjetas de métricas ────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Beneficios Activos',
                    value: activeBenefits.toString(),
                    icon: Icons.card_giftcard_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    label: 'Total Beneficios',
                    value: benefitProvider.benefits.length.toString(),
                    icon: Icons.list_alt_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    label: 'Empresas con Beneficios',
                    value: uniqueCompanies.toString(),
                    icon: Icons.business_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Tabla + búsqueda ────────────────────────────────────
            Card(
              color: themeColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: themeColors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Barra de búsqueda y exportación
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
                                hintText: 'Buscar por nombre, empresa o ID...',
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
                          onPressed: () => _exportData(
                            format: 'excel',
                            data: filteredBenefits,
                            companies: companies,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildExportButton(
                          label: 'PDF',
                          icon: Icons.picture_as_pdf_rounded,
                          color: const Color(0xFFE02424),
                          onPressed: () => _exportData(
                            format: 'pdf',
                            data: filteredBenefits,
                            companies: companies,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildExportButton(
                          label: context.tr('print'),
                          icon: Icons.print_rounded,
                          color: AppColors.primary,
                          onPressed: () => _exportData(
                            format: 'print',
                            data: filteredBenefits,
                            companies: companies,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),

                  // Contenido de la tabla
                  _buildTableContent(
                    benefitProvider: benefitProvider,
                    themeColors: themeColors,
                    paginatedBenefits: paginatedBenefits,
                    filteredBenefits: filteredBenefits,
                    companies: companies,
                    canEdit: canEdit,
                    totalBenefits: totalBenefits,
                    safeTotalPages: safeTotalPages,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Tarjetas informativas ───────────────────────────────
            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: 'Sobre los Beneficios',
                    content:
                        'Los beneficios son ventajas o incentivos que se ofrecen '
                        'a través de cada empresa registrada. Pueden incluir descuentos, '
                        'bonos, seguros u otros tipos de prestaciones adicionales.',
                    icon: Icons.card_giftcard_rounded,
                    iconColor: const Color(0xFF4ECDC4),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InfoCard(
                    title: 'Vinculación con Empresas',
                    content:
                        'Cada beneficio está estrictamente asociado a una empresa. '
                        'El nombre o razón social de la empresa se muestra automáticamente '
                        'a partir del identificador interno registrado.',
                    icon: Icons.business_center_rounded,
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

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildTableContent({
    required BenefitProvider benefitProvider,
    required AppThemeColors themeColors,
    required List<Benefit> paginatedBenefits,
    required List<Benefit> filteredBenefits,
    required List<Company> companies,
    required bool canEdit,
    required int totalBenefits,
    required int safeTotalPages,
  }) {
    if (benefitProvider.isLoading && benefitProvider.benefits.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (benefitProvider.errorMessage != null &&
        benefitProvider.benefits.isEmpty) {
      return _buildErrorWidget(benefitProvider);
    }
    if (filteredBenefits.isEmpty) {
      return _buildEmptyWidget();
    }

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final minTableWidth = 900.0;
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
                              Expanded(flex: 1, child: HeaderFilter(title: context.tr('id'), onChanged: (v) => setState(() { _idFilter = v; _currentPage = 1; }))),
                              Expanded(flex: 3, child: HeaderFilter(title: 'Nombre del Beneficio', onChanged: (v) => setState(() { _nameFilter = v; _currentPage = 1; }))),
                              Expanded(flex: 3, child: HeaderFilter(title: 'Empresa', onChanged: (v) => setState(() { _companyFilter = v; _currentPage = 1; }))),
                              Expanded(flex: 2, child: HeaderFilter(title: context.tr('status'), onChanged: (v) => setState(() { _statusFilter = v; _currentPage = 1; }))),
                              if (canEdit) const SizedBox(width: 100, child: Align(alignment: Alignment.centerRight, child: Text('Acciones'))),
                            ],
                          ),
                        ),
                      ),
                      // Custom Rows
                      ...paginatedBenefits.map((benefit) {
                        final companyName = _resolveCompanyName(benefit.companyBenefits, companies);
                        return _BenefitRow(
                          benefit: benefit,
                          themeColors: themeColors,
                          companyName: companyName,
                          actionsWidget: _buildActionsCell(benefit, companies),
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
        _buildPaginationFooter(
          totalItems: totalBenefits,
          totalPages: safeTotalPages,
        ),
      ],
    );
  }


  Widget _buildActionsCell(Benefit benefit, List<Company> companies) {
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
          onPressed: () => _navigateToForm(benefit: benefit),
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.error,
            size: 18,
          ),
          tooltip: 'Eliminar',
          onPressed: () => _showDeleteDialog(benefit, companies),
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
            '${context.tr('total')}: $totalItems ${context.tr('benefits').toLowerCase()}',
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
              'No se encontraron beneficios',
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

  Widget _buildErrorWidget(BenefitProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => provider.loadBenefits(),
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
      ),
    );
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

  // ── Utilidades ────────────────────────────────────────────────────────────

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      return '${dateTime.day.toString().padLeft(2, '0')}/'
          '${dateTime.month.toString().padLeft(2, '0')}/'
          '${dateTime.year}';
    } catch (_) {
      return dateStr.split('T')[0];
    }
  }

  void _exportData({
    required String format,
    required List<Benefit> data,
    required List<Company> companies,
  }) async {
    final headers = [
      'ID',
      'Nombre del Beneficio',
      'Empresa',
      'Estado',
      'Creado por',
      'Creado en',
    ];
    final rows = data.map((b) {
      final companyName = _resolveCompanyName(b.companyBenefits, companies);
      return [
        b.id.toString().padLeft(3, '0'),
        b.name,
        companyName,
        b.isActive ? 'Activo' : 'Inactivo',
        b.createByName ?? b.createBy?.toString() ?? '-',
        _formatDate(b.createAt),
      ];
    }).toList();

    try {
      if (format == 'excel') {
        await ExportHelper.exportToExcel(
          headers: headers,
          rows: rows,
          filename:
              'reporte_beneficios_${DateTime.now().millisecondsSinceEpoch}',
        );
        if (!mounted) return;
        CustomAlert.show(
          context,
          message: context.tr('export_excel_success'),
          isSuccess: true,
        );
      } else {
        final now = DateTime.now();
        final dateStr =
            '${now.day.toString().padLeft(2, '0')}-'
            '${now.month.toString().padLeft(2, '0')}-'
            '${now.year}';
        await ExportHelper.exportToPdfAndPrint(
          title: 'Reporte de Beneficios - $dateStr',
          headers: headers,
          rows: rows,
        );
      }
    } catch (e) {
      if (!mounted) return;
      CustomAlert.show(
        context,
        message: '${context.tr('error_occurred')}: $e',
        isSuccess: false,
      );
    }
  }

  // ── Vista de Miembro (Cuadritos / Tarjetas) ────────────────────────────────

  Widget _buildMemberView({
    required BenefitProvider benefitProvider,
    required AppThemeColors themeColors,
    required List<Benefit> filteredBenefits,
    required List<Company> companies,
    required String userName,
  }) {
    final redemptionProvider = context.watch<RedemptionProvider>();

    if (benefitProvider.isLoading && benefitProvider.benefits.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (benefitProvider.errorMessage != null && benefitProvider.benefits.isEmpty) {
      return _buildErrorWidget(benefitProvider);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner de Bienvenida
        _buildWelcomingBanner(themeColors, userName),
        const SizedBox(height: 24),

        // Pestañas (Tabs): Beneficios Disponibles / Mis Redenciones
        Row(
          children: [
            _buildTabButton(
              label: 'Beneficios Disponibles',
              icon: Icons.card_giftcard_rounded,
              index: 0,
              themeColors: themeColors,
            ),
            const SizedBox(width: 12),
            _buildTabButton(
              label: 'Mis Redenciones (${redemptionProvider.myRedemptions.length})',
              icon: Icons.confirmation_number_rounded,
              index: 1,
              themeColors: themeColors,
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (_memberTab == 0) ...[
          // Barra de Búsqueda
          Container(
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
                hintText: 'Buscar beneficio o empresa...',
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
          ),
          const SizedBox(height: 24),

          // Rejilla de beneficios disponibles
          _buildMemberGrid(filteredBenefits, companies, themeColors, redemptionProvider),
        ] else ...[
          // Pestaña Mis Redenciones
          _buildMyRedemptionsTab(redemptionProvider, themeColors),
        ],
      ],
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required int index,
    required AppThemeColors themeColors,
  }) {
    final isSelected = _memberTab == index;
    return InkWell(
      onTap: () => setState(() => _memberTab = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : themeColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : themeColors.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.accent : themeColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? themeColors.textPrimary : themeColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomingBanner(AppThemeColors themeColors, String userName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, $userName!',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Redime tus beneficios exclusivos y muéstralos en los negocios aliados.',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Icon(
            Icons.card_giftcard_rounded,
            color: Colors.white.withValues(alpha: 0.9),
            size: 64,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberGrid(
    List<Benefit> benefits,
    List<Company> companies,
    AppThemeColors themeColors,
    RedemptionProvider redemptionProvider,
  ) {
    if (benefits.isEmpty) {
      return _buildEmptyWidget();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 360,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            mainAxisExtent: 250,
          ),
          itemCount: benefits.length,
          itemBuilder: (context, index) {
            final benefit = benefits[index];
            final companyName = _resolveCompanyName(benefit.companyBenefits, companies);
            final existingRedemption = redemptionProvider.getRedemptionForBenefit(benefit.id);

            return Card(
              color: themeColors.cardBackground,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: themeColors.borderColor),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showBenefitDetailDialog(
                  benefit,
                  companyName,
                  themeColors,
                  existingRedemption,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header de la Tarjeta
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                                  child: Text(
                                    companyName.isNotEmpty ? companyName[0].toUpperCase() : '?',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF4ECDC4),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    companyName,
                                    style: GoogleFonts.inter(
                                      color: themeColors.textPrimary.withValues(alpha: 0.7),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(
                            label: benefit.isActive ? 'Activo' : 'Inactivo',
                            isActive: benefit.isActive,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Título del beneficio
                      Text(
                        benefit.name,
                        style: GoogleFonts.outfit(
                          color: themeColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Descripción
                      Expanded(
                        child: Text(
                          benefit.description.isNotEmpty
                              ? benefit.description
                              : 'Sin descripción disponible.',
                          style: GoogleFonts.inter(
                            color: themeColors.textSecondary,
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Botón dinámico según el estado real de la redención
                      _buildRedeemActionButton(
                        benefit: benefit,
                        companyName: companyName,
                        themeColors: themeColors,
                        redemption: existingRedemption,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Construye el botón de acción según el estado real de la redención (no redimido, generado, usado, vencido).
  Widget _buildRedeemActionButton({
    required Benefit benefit,
    required String companyName,
    required AppThemeColors themeColors,
    required BenefitRedemption? redemption,
  }) {
    if (redemption == null) {
      // Caso 1: No redimido -> Botón principal "Redimir Beneficio"
      return SizedBox(
        width: double.infinity,
        height: 38,
        child: ElevatedButton.icon(
          onPressed: () => _handleRedeemBenefit(benefit, companyName),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.zero,
          ),
          icon: const Icon(Icons.confirmation_number_outlined, size: 16, color: Colors.white),
          label: Text(
            'Redimir Beneficio',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      );
    } else if (redemption.estado == 'generado') {
      // Caso 2: Redimido y Pendiente ('generado') -> Botón verde/teal "Ver Mi Código"
      return SizedBox(
        width: double.infinity,
        height: 38,
        child: ElevatedButton.icon(
          onPressed: () => _showRedemptionCodeModal(redemption, benefit.name, companyName),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4ECDC4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.zero,
          ),
          icon: const Icon(Icons.qr_code_rounded, size: 16, color: Color(0xFF191924)),
          label: Text(
            'Ver Mi Código',
            style: GoogleFonts.inter(
              color: const Color(0xFF191924),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      );
    } else if (redemption.estado == 'usado') {
      // Caso 3: Ya utilizado -> Botón informativo tenue "Beneficio Usado"
      return SizedBox(
        width: double.infinity,
        height: 38,
        child: OutlinedButton.icon(
          onPressed: () => _showRedemptionDetailModal(redemption, benefit.name, companyName),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: const Color(0xFF6C63FF).withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.zero,
          ),
          icon: const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF6C63FF)),
          label: Text(
            'Beneficio Usado',
            style: GoogleFonts.inter(
              color: const Color(0xFF6C63FF),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
    } else {
      // Caso 4: Vencido -> Botón rojo tenue
      return SizedBox(
        width: double.infinity,
        height: 38,
        child: OutlinedButton.icon(
          onPressed: () => _showRedemptionDetailModal(redemption, benefit.name, companyName),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.zero,
          ),
          icon: Icon(Icons.timer_off_rounded, size: 16, color: Colors.red.withValues(alpha: 0.7)),
          label: Text(
            'Código Vencido',
            style: GoogleFonts.inter(
              color: Colors.red.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
    }
  }

  void _handleRedeemBenefit(Benefit benefit, String companyName) async {
    final provider = context.read<RedemptionProvider>();
    final redemption = await provider.redeemBenefit(benefit.id);

    if (!mounted) return;

    if (redemption != null) {
      _showRedemptionCodeModal(redemption, benefit.name, companyName);
    } else if (provider.errorMessage != null) {
      CustomAlert.show(
        context,
        message: provider.errorMessage!,
        isSuccess: false,
      );
    }
  }

  void _showRedemptionCodeModal(
    BenefitRedemption redemption,
    String benefitName,
    String companyName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Color(0xFF4ECDC4),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                benefitName,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Establecimiento: $companyName',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Contenedor Destacado del Código
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'CÓDIGO DE REDENCIÓN',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF4ECDC4),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      redemption.codigoValidacion,
                      style: GoogleFonts.spaceMono(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Botón Copiar al Portapapeles
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: redemption.codigoValidacion));
                  CustomAlert.show(
                    context,
                    message: '¡Código copiado al portapapeles!',
                    isSuccess: true,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                label: Text(
                  'Copiar Código',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Muestra o dicta este código de 8 caracteres al encargado del comercio para aplicar tu beneficio.',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Cerrar',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF191924),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRedemptionDetailModal(
    BenefitRedemption redemption,
    String benefitName,
    String companyName,
  ) {
    final isUsed = redemption.estado == 'usado';
    final dateStr = redemption.fechaUso != null
        ? '${redemption.fechaUso!.day.toString().padLeft(2, '0')}/${redemption.fechaUso!.month.toString().padLeft(2, '0')}/${redemption.fechaUso!.year} ${redemption.fechaUso!.hour.toString().padLeft(2, '0')}:${redemption.fechaUso!.minute.toString().padLeft(2, '0')}'
        : '-';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUsed ? Icons.check_circle_outline : Icons.timer_off_rounded,
                color: isUsed ? const Color(0xFF6C63FF) : Colors.red.withValues(alpha: 0.8),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                isUsed ? 'Beneficio Ya Canjeado' : 'Código Vencido',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                benefitName,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 8),
              Text(
                'Código: ${redemption.codigoValidacion}',
                style: GoogleFonts.spaceMono(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isUsed
                    ? 'Canjeado el: $dateStr'
                    : 'Este beneficio finalizó antes de ser utilizado.',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Entendido',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyRedemptionsTab(
    RedemptionProvider provider,
    AppThemeColors themeColors,
  ) {
    if (provider.isLoading && provider.myRedemptions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (provider.myRedemptions.isEmpty) {
      // Empty State para Empleado sin redenciones
      return Card(
        color: themeColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: themeColors.borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            children: [
              Icon(
                Icons.card_giftcard_rounded,
                size: 64,
                color: themeColors.textSecondary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Aún no has redimido ningún beneficio',
                style: GoogleFonts.outfit(
                  color: themeColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Explora la lista de beneficios disponibles y genera tu primer código de descuento.',
                style: GoogleFonts.inter(
                  color: themeColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => setState(() => _memberTab = 0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.explore_rounded, size: 18, color: Colors.white),
                label: Text(
                  'Explorar Beneficios',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: themeColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: themeColors.borderColor),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: provider.myRedemptions.length,
        separatorBuilder: (_, __) =>
            Divider(color: themeColors.borderColor, height: 1),
        itemBuilder: (context, index) {
          final item = provider.myRedemptions[index];
          final dateStr = item.fechaRedencion != null
              ? '${item.fechaRedencion!.day.toString().padLeft(2, '0')}/${item.fechaRedencion!.month.toString().padLeft(2, '0')}/${item.fechaRedencion!.year}'
              : '-';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              child: const Icon(
                Icons.confirmation_number_rounded,
                color: Color(0xFF6C63FF),
                size: 20,
              ),
            ),
            title: Text(
              item.benefitName.isNotEmpty
                  ? item.benefitName
                  : 'Beneficio #${item.benefitId}',
              style: GoogleFonts.inter(
                color: themeColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              'Código: ${item.codigoValidacion} • Redimido el: $dateStr',
              style: GoogleFonts.inter(
                color: themeColors.textSecondary,
                fontSize: 13,
              ),
            ),
            trailing: StatusBadge(
              label: item.estado.toUpperCase(),
              isActive: item.estado == 'generado' || item.estado == 'usado',
            ),
            onTap: () {
              if (item.estado == 'generado') {
                _showRedemptionCodeModal(item, item.benefitName, 'Aliado');
              } else {
                _showRedemptionDetailModal(item, item.benefitName, 'Aliado');
              }
            },
          );
        },
      ),
    );
  }

  void _showBenefitDetailDialog(
    Benefit benefit,
    String companyName,
    AppThemeColors themeColors, [
    BenefitRedemption? redemption,
  ]) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: Color(0xFF4ECDC4),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                benefit.name,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Detalles de empresa
              Row(
                children: [
                  Icon(Icons.business_rounded, color: Colors.white.withValues(alpha: 0.5), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Empresa: ',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      companyName,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Estado
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white.withValues(alpha: 0.5), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Estado: ',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  StatusBadge(
                    label: benefit.isActive ? 'Activo' : 'Inactivo',
                    isActive: benefit.isActive,
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 24),
              Text(
                'Descripción del Beneficio:',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                benefit.description.isNotEmpty
                    ? benefit.description
                    : 'Sin descripción disponible.',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cerrar',
              style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom full-width responsive benefit row with hover animations ──
class _BenefitRow extends StatefulWidget {
  final Benefit benefit;
  final AppThemeColors themeColors;
  final String companyName;
  final Widget actionsWidget;
  final bool canEdit;

  const _BenefitRow({
    required this.benefit,
    required this.themeColors,
    required this.companyName,
    required this.actionsWidget,
    required this.canEdit,
  });

  @override
  State<_BenefitRow> createState() => _BenefitRowState();
}

class _BenefitRowState extends State<_BenefitRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final benefit = widget.benefit;
    final themeColors = widget.themeColors;
    final companyName = widget.companyName;

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
                benefit.id.toString().padLeft(3, '0'),
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
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: benefit.isActive
                          ? const Color(0xFF6C63FF).withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.card_giftcard_rounded,
                      size: 15,
                      color: benefit.isActive ? const Color(0xFF4ECDC4) : Colors.white30,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      benefit.name,
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    child: Text(
                      companyName.isNotEmpty ? companyName[0].toUpperCase() : '?',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF4ECDC4),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      companyName,
                      style: GoogleFonts.inter(
                        color: themeColors.textPrimary.withValues(alpha: 0.85),
                        fontSize: 13,
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
                child: StatusBadge(
                  label: benefit.isActive ? 'Activo' : 'Inactivo',
                  isActive: benefit.isActive,
                ),
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
