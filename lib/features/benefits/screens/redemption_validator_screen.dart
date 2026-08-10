import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/redemption_model.dart';
import '../providers/redemption_provider.dart';

class RedemptionValidatorScreen extends StatefulWidget {
  const RedemptionValidatorScreen({super.key});

  @override
  State<RedemptionValidatorScreen> createState() =>
      _RedemptionValidatorScreenState();
}

class _RedemptionValidatorScreenState
    extends State<RedemptionValidatorScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RedemptionProvider>().loadCompanyRedemptions();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onValidatePressed() async {
    final rawCode = _codeController.text;
    final provider = context.read<RedemptionProvider>();

    final success = await provider.validateCode(rawCode);

    if (!mounted) return;

    if (success && provider.lastValidatedResponse != null) {
      _codeController.clear();
      _showSuccessDialog(provider.lastValidatedResponse!);
    } else if (provider.errorMessage != null) {
      _showDetailedErrorDialog(provider.errorMessage!);
    }
  }

  void _showSuccessDialog(ValidateCodeResponse response) {
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
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4ECDC4),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '¡Código Canjeado con Éxito!',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              const SizedBox(height: 12),
              _buildDialogDetailRow('Beneficio:', response.benefitName),
              if (response.usuarioNombre.isNotEmpty)
                _buildDialogDetailRow('Empleado:', response.usuarioNombre),
              _buildDialogDetailRow('Estado:', 'USADO'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Entendido',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF191924),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
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

  void _showDetailedErrorDialog(String rawError) {
    String title = 'No se pudo validar';
    String message = rawError;
    IconData icon = Icons.error_outline_rounded;
    Color iconColor = const Color(0xFFFF6B6B);
    Color bgColor = const Color(0xFFFF6B6B).withValues(alpha: 0.15);

    final lowerErr = rawError.toLowerCase();

    if (lowerErr.contains('pertenece a tu empresa') ||
        lowerErr.contains('no pertenece')) {
      title = 'Código de otra empresa';
      message =
          'Este código de beneficio pertenece a otra empresa aliada. No tienes permiso para validarlo en este establecimiento.';
      icon = Icons.domain_disabled_rounded;
      iconColor = const Color(0xFFFF9F43);
      bgColor = const Color(0xFFFF9F43).withValues(alpha: 0.15);
    } else if (lowerErr.contains('utilizado') || lowerErr.contains('usado')) {
      title = 'Código ya utilizado';
      message =
          'Este código de beneficio ya fue canjeado anteriormente y no puede ser usado por segunda vez.';
      icon = Icons.history_toggle_off_rounded;
      iconColor = const Color(0xFF54a0ff);
      bgColor = const Color(0xFF54a0ff).withValues(alpha: 0.15);
    } else if (lowerErr.contains('vencido') || lowerErr.contains('expiró')) {
      title = 'Código vencido';
      message =
          'Este código ha expirado debido a que la fecha de vigencia del beneficio ya finalizó.';
      icon = Icons.timer_off_rounded;
      iconColor = const Color(0xFFEE5253);
      bgColor = const Color(0xFFEE5253).withValues(alpha: 0.15);
    } else if (lowerErr.contains('inválido') || lowerErr.contains('invalido')) {
      title = 'Código no encontrado';
      message =
          'El código escrito no existe en el sistema. Verifica que esté bien escrito (8 caracteres).';
      icon = Icons.search_off_rounded;
      iconColor = const Color(0xFFFF6B6B);
    }

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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13.5,
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
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cerrar',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

  Widget _buildDialogDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final redemptionProvider = context.watch<RedemptionProvider>();
    final authProvider = context.watch<AuthProvider>();
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;

    final companyName = authProvider.activeCompany?.name ?? 'Tu Empresa';

    return DashboardShell(
      title: 'Validación de Beneficios',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner Header ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1E2E), Color(0xFF2D2B42)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ECDC4).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.store_rounded,
                      color: Color(0xFF4ECDC4),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Validador de Redenciones',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Aliado: $companyName — Ingresa el código alfanumérico dictado por el empleado.',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Card de Formulario de Validación ───────────────────────
            Card(
              color: themeColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: themeColors.borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Validar Código de Redención',
                      style: GoogleFonts.outfit(
                        color: themeColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Escribe el código de 8 caracteres mostrado por el cliente.',
                      style: GoogleFonts.inter(
                        color: themeColors.textSecondary,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
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
                              controller: _codeController,
                              enabled: !redemptionProvider.isValidating,
                              style: GoogleFonts.spaceMono(
                                color: themeColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z0-9\-\s]'),
                                ),
                              ],
                              decoration: InputDecoration(
                                hintText: 'Ej. 7K3M92XQ',
                                hintStyle: GoogleFonts.spaceMono(
                                  color: themeColors.textSecondary.withValues(alpha: 0.3),
                                  fontSize: 16,
                                  letterSpacing: 2,
                                ),
                                prefixIcon: Icon(
                                  Icons.qr_code_rounded,
                                  color: AppColors.accent,
                                  size: 22,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              onSubmitted: (_) => _onValidatePressed(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: redemptionProvider.isValidating
                                ? null
                                : _onValidatePressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: redemptionProvider.isValidating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check_circle_outline, color: Colors.white),
                            label: Text(
                              redemptionProvider.isValidating
                                  ? 'Validando...'
                                  : 'Validar Código',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Historial de Redenciones Canjeadas ─────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Redenciones Validadas por tu Empresa',
                  style: GoogleFonts.outfit(
                    color: themeColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: themeColors.textSecondary,
                  ),
                  onPressed: () => context
                      .read<RedemptionProvider>()
                      .loadCompanyRedemptions(),
                  tooltip: 'Actualizar historial',
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildCompanyRedemptionsList(redemptionProvider, themeColors),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyRedemptionsList(
    RedemptionProvider provider,
    AppThemeColors themeColors,
  ) {
    if (provider.isLoading && provider.companyRedemptions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (provider.companyRedemptions.isEmpty) {
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
                Icons.store_rounded,
                size: 64,
                color: themeColors.textSecondary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Aún no se han validado redenciones para tu empresa',
                style: GoogleFonts.outfit(
                  color: themeColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Los códigos canjeados en este establecimiento aparecerán aquí.',
                style: GoogleFonts.inter(
                  color: themeColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
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
        itemCount: provider.companyRedemptions.length,
        separatorBuilder: (_, __) =>
            Divider(color: themeColors.borderColor, height: 1),
        itemBuilder: (context, index) {
          final item = provider.companyRedemptions[index];
          final dateStr = item.fechaRedencion != null
              ? '${item.fechaRedencion!.day.toString().padLeft(2, '0')}/${item.fechaRedencion!.month.toString().padLeft(2, '0')}/${item.fechaRedencion!.year} ${item.fechaRedencion!.hour.toString().padLeft(2, '0')}:${item.fechaRedencion!.minute.toString().padLeft(2, '0')}'
              : '-';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF4ECDC4).withValues(alpha: 0.15),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: Color(0xFF4ECDC4),
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
              'Código: ${item.codigoValidacion} • Redimido: $dateStr',
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
