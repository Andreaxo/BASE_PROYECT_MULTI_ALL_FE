import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/redemption_provider.dart';

class AdminRedemptionsScreen extends StatefulWidget {
  const AdminRedemptionsScreen({super.key});

  @override
  State<AdminRedemptionsScreen> createState() => _AdminRedemptionsScreenState();
}

class _AdminRedemptionsScreenState extends State<AdminRedemptionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RedemptionProvider>().loadAllRedemptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final redemptionProvider = context.watch<RedemptionProvider>();
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;

    return DashboardShell(
      title: 'Redenciones Globales',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historial Global de Redenciones',
                      style: GoogleFonts.outfit(
                        color: themeColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vista administrable de todas las redenciones en la plataforma.',
                      style: GoogleFonts.inter(
                        color: themeColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: themeColors.textSecondary),
                  onPressed: () => context.read<RedemptionProvider>().loadAllRedemptions(),
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildAdminRedemptionsContent(redemptionProvider, themeColors),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminRedemptionsContent(
    RedemptionProvider provider,
    AppThemeColors themeColors,
  ) {
    if (provider.isLoading && provider.allRedemptions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (provider.allRedemptions.isEmpty) {
      return Card(
        color: themeColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: themeColors.borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.card_giftcard_rounded,
                  size: 64,
                  color: themeColors.textSecondary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No existen redenciones registradas en el sistema',
                  style: GoogleFonts.outfit(
                    color: themeColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
        itemCount: provider.allRedemptions.length,
        separatorBuilder: (_, __) =>
            Divider(color: themeColors.borderColor, height: 1),
        itemBuilder: (context, index) {
          final item = provider.allRedemptions[index];
          final dateStr = item.fechaRedencion != null
              ? '${item.fechaRedencion!.day.toString().padLeft(2, '0')}/${item.fechaRedencion!.month.toString().padLeft(2, '0')}/${item.fechaRedencion!.year}'
              : '-';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                '#${item.id}',
                style: GoogleFonts.outfit(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              item.benefitName.isNotEmpty ? item.benefitName : 'Beneficio #${item.benefitId}',
              style: GoogleFonts.inter(
                color: themeColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Código: ${item.codigoValidacion} • Generado: $dateStr',
              style: GoogleFonts.inter(
                color: themeColors.textSecondary,
                fontSize: 13,
              ),
            ),
            trailing: StatusBadge(
              label: item.estado.toUpperCase(),
              isActive: item.estado == 'usado',
            ),
          );
        },
      ),
    );
  }
}
