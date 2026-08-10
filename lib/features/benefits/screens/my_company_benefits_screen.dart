import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_alert.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/status_badge.dart';

import '../models/benefit_model.dart';
import '../providers/benefit_provider.dart';
import 'benefit_form_screen.dart';

class MyCompanyBenefitsScreen extends StatefulWidget {
  const MyCompanyBenefitsScreen({super.key});

  @override
  State<MyCompanyBenefitsScreen> createState() => _MyCompanyBenefitsScreenState();
}

class _MyCompanyBenefitsScreenState extends State<MyCompanyBenefitsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBenefits();
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
    });
  }

  Future<void> _loadBenefits() async {
    final benefitProvider = context.read<BenefitProvider>();
    await benefitProvider.loadMyCompanyBenefits();
  }

  void _showDeleteDialog(Benefit benefit) {
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar Beneficio',
          style: GoogleFonts.outfit(
            color: themeColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar el beneficio "${benefit.name}"?',
          style: GoogleFonts.inter(color: themeColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: themeColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
                  _loadBenefits();
                } else {
                  CustomAlert.show(
                    context,
                    message: provider.errorMessage ?? 'No se pudo eliminar el beneficio',
                    isSuccess: false,
                  );
                }
              }
            },
            child: Text('Eliminar', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final benefitProvider = context.watch<BenefitProvider>();
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;

    // Benefits are already filtered by the backend endpoint /my-company
    final companyBenefits = benefitProvider.benefits;

    final filteredBenefits = companyBenefits.where((b) {
      if (_searchQuery.isEmpty) return true;
      return b.name.toLowerCase().contains(_searchQuery) ||
          b.description.toLowerCase().contains(_searchQuery);
    }).toList();

    return DashboardShell(
      title: 'Gestionar Mis Beneficios',
      child: RefreshIndicator(
        onRefresh: _loadBenefits,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.accent.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.card_giftcard_rounded, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Beneficios de Tu Empresa',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: themeColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Publica, modifica y gestiona las promociones para la red de usuarios.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: themeColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GradientButton(
                      label: 'Nuevo Beneficio',
                      icon: Icons.add_rounded,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BenefitFormScreen(),
                          ),
                        ).then((_) => _loadBenefits());
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: themeColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: themeColors.borderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: themeColors.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        cursorColor: const Color(0xFF6C63FF),
                        cursorWidth: 2.0,
                        cursorRadius: const Radius.circular(2),
                        showCursor: true,
                        style: GoogleFonts.inter(color: themeColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Buscar beneficio por nombre o descripción...',
                          hintStyle: GoogleFonts.inter(color: themeColors.textSecondary),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear_rounded, color: themeColors.textSecondary, size: 18),
                        onPressed: () => _searchController.clear(),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Loading & Benefits Grid/List
              if (benefitProvider.isLoading && companyBenefits.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (filteredBenefits.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: themeColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: themeColors.borderColor),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.card_giftcard_outlined, size: 54, color: themeColors.textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No se encontraron beneficios con esa búsqueda'
                            : 'Tu empresa aún no ha publicado beneficios',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Publica promociones para atraer nuevos usuarios y fidelizar clientes.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: themeColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GradientButton(
                        label: 'Crear Mi Primer Beneficio',
                        icon: Icons.add_rounded,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BenefitFormScreen(),
                            ),
                          ).then((_) => _loadBenefits());
                        },
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredBenefits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (ctx, index) {
                    final benefit = filteredBenefits[index];
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: themeColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: themeColors.borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isSmall = constraints.maxWidth < 550;
                          if (isSmall) {
                            // Compact mobile layout
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                      ),
                                      child: const Icon(Icons.card_giftcard_rounded, color: AppColors.primary, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        benefit.name,
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: themeColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    StatusBadge(
                                      label: benefit.isActive ? 'Activo' : 'Inactivo',
                                      isActive: benefit.isActive,
                                    ),
                                  ],
                                ),
                                if (benefit.description.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    benefit.description,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: themeColors.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.accent),
                                      label: Text('Editar', style: GoogleFonts.inter(fontSize: 12, color: AppColors.accent)),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.4)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BenefitFormScreen(benefit: benefit),
                                          ),
                                        ).then((_) => _loadBenefits());
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                      label: Text('Eliminar', style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent)),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => _showDeleteDialog(benefit),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }

                          // Wide desktop/tablet layout with perfectly aligned columns
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                ),
                                child: const Icon(Icons.card_giftcard_rounded, color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      benefit.name,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: themeColors.textPrimary,
                                      ),
                                    ),
                                    if (benefit.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        benefit.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: themeColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  StatusBadge(
                                    label: benefit.isActive ? 'Activo' : 'Inactivo',
                                    isActive: benefit.isActive,
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: themeColors.textPrimary.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: themeColors.borderColor),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_rounded, color: AppColors.accent, size: 18),
                                          tooltip: 'Editar beneficio',
                                          padding: const EdgeInsets.all(10),
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => BenefitFormScreen(benefit: benefit),
                                              ),
                                            ).then((_) => _loadBenefits());
                                          },
                                        ),
                                        Container(width: 1, height: 20, color: themeColors.borderColor),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                          tooltip: 'Eliminar beneficio',
                                          padding: const EdgeInsets.all(10),
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _showDeleteDialog(benefit),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
