import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/widgets/stat_card.dart';
import '../../users/providers/user_provider.dart';
import '../../company/providers/company_provider.dart';
import '../../role/providers/role_provider.dart';
import '../../inventory/providers/category_provider.dart';
import '../../inventory/providers/article_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUsers();
      context.read<CompanyProvider>().loadCompanies();
      context.read<RoleProvider>().loadRoles();
      context.read<CategoryProvider>().loadCategories();
      context.read<ArticleProvider>().loadArticles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final companyProvider = context.watch<CompanyProvider>();
    final roleProvider = context.watch<RoleProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final articleProvider = context.watch<ArticleProvider>();

    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;
    final lang = Localizations.localeOf(context).languageCode;

    final totalUsers = userProvider.users.length;
    final totalCompanies = companyProvider.companies.length;
    final totalRoles = roleProvider.roles.length;
    final totalCategories = categoryProvider.categories.length;
    final totalArticles = articleProvider.articles.length;

    final activeUsers = userProvider.users.where((u) => u.isActive).length;
    final activeCompanies = companyProvider.companies.where((c) => c.isActive).length;
    final activeCategories = categoryProvider.categories.where((c) => c.isActive).length;

    return DashboardShell(
      title: context.tr('statistics_dashboard_title'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            Row(
              children: [
                Text(
                  context.tr('statistics'),
                  style: GoogleFonts.inter(
                    color: themeColors.textSecondary.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: themeColors.textSecondary.withOpacity(0.5),
                  size: 14,
                ),
                Text(
                  context.tr('dashboard'),
                  style: GoogleFonts.inter(
                    color: themeColors.textPrimary.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Header Section
            Text(
              context.tr('statistics_dashboard_title'),
              style: GoogleFonts.outfit(
                color: themeColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('statistics_dashboard_subtitle'),
              style: GoogleFonts.inter(
                color: themeColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Quick Metrics Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final crossAxisCount = isMobile ? 2 : 5;
                final childAspectRatio = isMobile ? 1.3 : 1.5;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: childAspectRatio,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StatCard(
                      label: context.tr('users'),
                      value: totalUsers.toString(),
                      icon: Icons.people_rounded,
                    ),
                    StatCard(
                      label: context.tr('companies'),
                      value: totalCompanies.toString(),
                      icon: Icons.business_rounded,
                    ),
                    StatCard(
                      label: context.tr('roles'),
                      value: totalRoles.toString(),
                      icon: Icons.admin_panel_settings_rounded,
                    ),
                    StatCard(
                      label: context.tr('categories'),
                      value: totalCategories.toString(),
                      icon: Icons.category_rounded,
                    ),
                    StatCard(
                      label: context.tr('articles'),
                      value: totalArticles.toString(),
                      icon: Icons.inventory_rounded,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Visual Status Analytics Cards
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: themeColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: themeColors.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang == 'es'
                              ? 'Distribución Operativa'
                              : (lang == 'fr' ? 'Distribution Opérationnelle' : 'Operational Distribution'),
                          style: GoogleFonts.outfit(
                            color: themeColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildDistributionRow(
                          title: context.tr('users'),
                          active: activeUsers,
                          total: totalUsers,
                          color: const Color(0xFF6C63FF),
                          themeColors: themeColors,
                        ),
                        const SizedBox(height: 16),
                        _buildDistributionRow(
                          title: context.tr('companies'),
                          active: activeCompanies,
                          total: totalCompanies,
                          color: const Color(0xFF4ECDC4),
                          themeColors: themeColors,
                        ),
                        const SizedBox(height: 16),
                        _buildDistributionRow(
                          title: context.tr('categories'),
                          active: activeCategories,
                          total: totalCategories,
                          color: const Color(0xFFFFD166),
                          themeColors: themeColors,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: themeColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: themeColors.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang == 'es'
                              ? 'Resumen del Sistema'
                              : (lang == 'fr' ? 'Résumé du Système' : 'System Overview'),
                          style: GoogleFonts.outfit(
                            color: themeColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(
                          label: lang == 'es'
                              ? 'Relación Artículo/Categoría'
                              : (lang == 'fr' ? 'Ratio Article/Catégorie' : 'Item/Category Ratio'),
                          value: totalCategories > 0
                              ? (totalArticles / totalCategories).toStringAsFixed(1)
                              : '0.0',
                          themeColors: themeColors,
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          label: lang == 'es'
                              ? 'Usuarios por Empresa'
                              : (lang == 'fr' ? 'Utilisateurs par Entreprise' : 'Users per Company'),
                          value: totalCompanies > 0
                              ? (totalUsers / totalCompanies).toStringAsFixed(1)
                              : '0.0',
                          themeColors: themeColors,
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          label: lang == 'es'
                              ? 'Roles Activos'
                              : (lang == 'fr' ? 'Rôles Actifs' : 'Active Roles'),
                          value: totalRoles.toString(),
                          themeColors: themeColors,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionRow({
    required String title,
    required int active,
    required int total,
    required Color color,
    required AppThemeColors themeColors,
  }) {
    final pct = total > 0 ? (active / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                color: themeColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            Text(
              '$active / $total (${(pct * 100).toStringAsFixed(0)}%)',
              style: GoogleFonts.inter(
                color: themeColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: themeColors.borderColor,
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required AppThemeColors themeColors,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: themeColors.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: themeColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
