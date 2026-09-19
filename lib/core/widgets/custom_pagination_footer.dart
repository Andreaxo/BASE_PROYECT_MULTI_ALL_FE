import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Reusable, high-fidelity data table pagination footer.
/// Displays clear slice boundaries ("Mostrando 1–15 de 16 resultados"),
/// customizable rows per page pill dropdown, and responsive navigation controls.
class CustomPaginationFooter extends StatelessWidget {
  final int totalItems;
  final int currentPage;
  final int rowsPerPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onRowsPerPageChanged;
  final List<int> availableRowsPerPage;

  const CustomPaginationFooter({
    super.key,
    required this.totalItems,
    required this.currentPage,
    required this.rowsPerPage,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
    this.availableRowsPerPage = const [5, 10, 15, 20, 25],
  });

  @override
  Widget build(BuildContext context) {
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppTheme.darkThemeColors;

    final totalPages = (totalItems / rowsPerPage).ceil();
    final safeTotalPages = totalPages == 0 ? 1 : totalPages;
    final from = totalItems == 0 ? 0 : (currentPage - 1) * rowsPerPage + 1;
    final to = (currentPage * rowsPerPage).clamp(0, totalItems);

    final template = context.tr('showing_range');
    final showingText = template
        .replaceAll('{from}', '$from')
        .replaceAll('{to}', '$to')
        .replaceAll('{total}', '$totalItems');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: themeColors.textPrimary.withValues(alpha: 0.015),
        border: Border(top: BorderSide(color: themeColors.borderColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 650;

          final rangeWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  showingText,
                  style: GoogleFonts.inter(
                    color: themeColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );

          final controlsWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('rows_per_page'),
                style: GoogleFonts.inter(
                  color: themeColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: themeColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: themeColors.borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: availableRowsPerPage.contains(rowsPerPage)
                        ? rowsPerPage
                        : availableRowsPerPage.first,
                    dropdownColor: themeColors.cardBackground,
                    icon: Icon(
                      Icons.arrow_drop_down_rounded,
                      color: themeColors.textSecondary,
                      size: 20,
                    ),
                    isDense: true,
                    style: GoogleFonts.inter(
                      color: themeColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                    items: availableRowsPerPage.map((size) {
                      return DropdownMenuItem<int>(
                        value: size,
                        child: Text('$size'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        onRowsPerPageChanged(val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // First page button
              _buildNavButton(
                icon: Icons.first_page_rounded,
                tooltip: context.tr('first_page'),
                enabled: currentPage > 1,
                onPressed: () => onPageChanged(1),
                themeColors: themeColors,
              ),
              const SizedBox(width: 4),

              // Prev page button
              _buildNavButton(
                icon: Icons.chevron_left_rounded,
                tooltip: context.tr('previous_page'),
                enabled: currentPage > 1,
                onPressed: () => onPageChanged(currentPage - 1),
                themeColors: themeColors,
              ),
              const SizedBox(width: 8),

              // Page indicator badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: themeColors.textPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: themeColors.borderColor),
                ),
                child: Text(
                  '${context.tr('page')} $currentPage ${context.tr('of')} $safeTotalPages',
                  style: GoogleFonts.inter(
                    color: themeColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Next page button
              _buildNavButton(
                icon: Icons.chevron_right_rounded,
                tooltip: context.tr('next_page'),
                enabled: currentPage < safeTotalPages,
                onPressed: () => onPageChanged(currentPage + 1),
                themeColors: themeColors,
              ),
              const SizedBox(width: 4),

              // Last page button
              _buildNavButton(
                icon: Icons.last_page_rounded,
                tooltip: context.tr('last_page'),
                enabled: currentPage < safeTotalPages,
                onPressed: () => onPageChanged(safeTotalPages),
                themeColors: themeColors,
              ),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: rangeWidget),
                const SizedBox(height: 10),
                Center(child: controlsWidget),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              rangeWidget,
              controlsWidget,
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onPressed,
    required AppThemeColors themeColors,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: enabled
            ? themeColors.textPrimary.withValues(alpha: 0.04)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled
              ? themeColors.borderColor
              : themeColors.borderColor.withValues(alpha: 0.4),
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          size: 18,
          color: enabled
              ? themeColors.textPrimary
              : themeColors.textSecondary.withValues(alpha: 0.3),
        ),
        tooltip: tooltip,
        onPressed: enabled ? onPressed : null,
      ),
    );
  }
}
