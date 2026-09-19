import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_alert.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/membresia_model.dart';
import '../providers/membresia_provider.dart';

class MembresiaScreen extends StatefulWidget {
  const MembresiaScreen({super.key});

  @override
  State<MembresiaScreen> createState() => _MembresiaScreenState();
}

class _MembresiaScreenState extends State<MembresiaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MembresiaProvider>().loadMiMembresia();
    });
  }

  Future<void> _handlePayment(BuildContext context) async {
    final provider = context.read<MembresiaProvider>();
    final resp = await provider.iniciarPago();

    if (!mounted) return;

    if (resp != null) {
      if (resp.checkoutUrl.isNotEmpty) {
        final uri = Uri.tryParse(resp.checkoutUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      if (mounted) {
        _showPaymentModal(context, resp);
      }
    } else {
      final error = provider.errorMessage ?? 'Error al generar orden de pago';
      CustomAlert.show(context, message: error, isSuccess: false);
    }
  }

  void _showPaymentModal(BuildContext context, IniciarPagoResponse resp) {
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppTheme.darkThemeColors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.3),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.credit_card_rounded,
                color: AppColors.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pasarela de Pago Wompi',
                style: GoogleFonts.outfit(
                  color: themeColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu orden de pago ha sido generada exitosamente.',
              style: GoogleFonts.inter(
                color: themeColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeColors.cardBackground.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeColors.borderColor,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Referencia:',
                        style: GoogleFonts.inter(
                          color: themeColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        resp.referencia,
                        style: GoogleFonts.inter(
                          color: themeColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Monto:',
                        style: GoogleFonts.inter(
                          color: themeColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        r'$25.000 COP',
                        style: GoogleFonts.inter(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.science_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Modo Sandbox: Puedes simular la aprobación inmediata de la tarjeta oficial (4242...) con el botón de abajo o abrir el checkout de Wompi si tienes tus llaves reales en .env.',
                      style: GoogleFonts.inter(
                        color: themeColors.textPrimary,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cerrar',
                  style: GoogleFonts.inter(color: themeColors.textSecondary),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final success = await context.read<MembresiaProvider>().simularPago(status: 'APPROVED');
                  if (mounted) {
                    if (success) {
                      CustomAlert.show(
                        context,
                        message: '¡Pago aprobado con éxito! Tu membresía está activa por 30 días.',
                        isSuccess: true,
                      );
                    }
                  }
                },
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text('Simular Pago Aprobado (4242)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (resp.checkoutUrl.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.tryParse(resp.checkoutUrl);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Abrir Wompi Oficial'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancelRenewal(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Renovación Automática'),
        content: const Text(
          '¿Estás seguro de que deseas desactivar la renovación automática? Al finalizar tu período actual, tu membresía quedará inactiva.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Mantener Activada'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await context.read<MembresiaProvider>().cancelarRenovacion();
      if (mounted) {
        if (success) {
          CustomAlert.show(
            context,
            message: 'Renovación automática desactivada',
            isSuccess: true,
          );
        } else {
          CustomAlert.show(
            context,
            message: 'Error al cambiar la renovación',
            isSuccess: false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppTheme.darkThemeColors;
    final provider = context.watch<MembresiaProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isAdminOrSuperAdmin = authProvider.isAdminOrSuperAdmin;
    final isValidator =
        authProvider.roleCode == 'business_validator' ||
        authProvider.roleCode == 'negocio';

    final memb = provider.miMembresia;
    final isActiva = isAdminOrSuperAdmin || (memb?.isActiva ?? false);

    return DashboardShell(
      title: 'Membresía',
      child: provider.isLoading && memb == null && !isAdminOrSuperAdmin
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : RefreshIndicator(
              onRefresh: () => provider.loadMiMembresia(),
              color: AppColors.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Title
                    Text(
                      isAdminOrSuperAdmin
                          ? 'Membresías y Control de Acceso'
                          : isValidator
                              ? 'Membresía del Negocio Aliado'
                              : 'Mi Membresía Conexiate',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: themeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAdminOrSuperAdmin
                          ? 'Como Administrador, supervisas la red de afiliados y negocios. Tu cuenta posee acceso maestro vitalicio sin costo.'
                          : isValidator
                              ? 'Mantén activa la suscripción de tu empresa para ofrecer beneficios y validar redenciones en Conexiate.'
                              : 'Accede a descuentos ilimitados, rifas exclusivas y comisiones por referidos.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: themeColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Hero Membership Card
                    _buildMembershipHeroCard(
                      context,
                      memb,
                      isActiva,
                      isValidator,
                      isAdminOrSuperAdmin,
                      themeColors,
                      provider.isPaying,
                    ),

                    const SizedBox(height: 24),

                    // Auto Renewal Card (If member is active and not superadmin)
                    if (isActiva && !isAdminOrSuperAdmin) ...[
                      _buildAutoRenewalCard(context, memb, themeColors),
                      const SizedBox(height: 24),
                    ],

                    // Included Benefits Section
                    Text(
                      isAdminOrSuperAdmin
                          ? 'Funciones y Privilegios del Administrador'
                          : 'Beneficios Incluidos en tu Membresía',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildBenefitsGrid(context, isValidator, isAdminOrSuperAdmin, themeColors),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMembershipHeroCard(
    BuildContext context,
    MembresiaModel? memb,
    bool isActiva,
    bool isValidator,
    bool isAdminOrSuperAdmin,
    AppThemeColors themeColors,
    bool isPaying,
  ) {
    final dateFormat = DateFormat("dd 'de' MMMM 'de' yyyy", 'es');

    Color badgeColor;
    Color badgeBg;
    String badgeText;
    IconData badgeIcon;

    if (isAdminOrSuperAdmin) {
      badgeColor = const Color(0xFF10B981);
      badgeBg = const Color(0xFF10B981).withValues(alpha: 0.15);
      badgeText = 'ACCESO MAESTRO VITALICIO';
      badgeIcon = Icons.shield_rounded;
    } else if (isActiva) {
      badgeColor = const Color(0xFF10B981);
      badgeBg = const Color(0xFF10B981).withValues(alpha: 0.15);
      badgeText = 'MEMBRESÍA ACTIVA';
      badgeIcon = Icons.verified_rounded;
    } else if (memb?.isVencida ?? false) {
      badgeColor = const Color(0xFFEF4444);
      badgeBg = const Color(0xFFEF4444).withValues(alpha: 0.15);
      badgeText = 'MEMBRESÍA VENCIDA';
      badgeIcon = Icons.history_toggle_off_rounded;
    } else {
      badgeColor = const Color(0xFFF59E0B);
      badgeBg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
      badgeText = 'MEMBRESÍA INACTIVA';
      badgeIcon = Icons.pending_actions_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActiva
              ? [
                  const Color(0xFF064E3B).withValues(alpha: 0.6),
                  const Color(0xFF0F172A).withValues(alpha: 0.9),
                ]
              : [
                  const Color(0xFF1E1E2E).withValues(alpha: 0.9),
                  const Color(0xFF2D1537).withValues(alpha: 0.8),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActiva
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : AppColors.accent.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isActiva ? const Color(0xFF10B981) : AppColors.accent)
                .withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Badge & Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, color: badgeColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      badgeText,
                      style: GoogleFonts.outfit(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isAdminOrSuperAdmin ? 'Sin costo' : r'$25.000 COP',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    isAdminOrSuperAdmin ? 'Acceso Vitalicio' : '/ mes',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Plan Title
          Text(
            isAdminOrSuperAdmin
                ? 'Super Administrador Conexiate'
                : isValidator
                    ? 'Suscripción Negocio Aliado'
                    : 'Membresía Premium Conexiate',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAdminOrSuperAdmin
                ? 'Cuentas con acceso maestro y permanente a todos los módulos de la plataforma sin requerir afiliación ni pagos periódicos.'
                : isActiva
                    ? (memb?.fechaFin != null
                        ? 'Tu suscripción está activa hasta el ${dateFormat.format(memb!.fechaFin!)} (${memb.diasRestantes} días restantes).'
                        : 'Membresía activa por tiempo indefinido.')
                    : 'Activa tu membresía ahora a través de Wompi para desbloquear todos los beneficios.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white70,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 24),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),

          // Bottom Action Row
          if (isAdminOrSuperAdmin)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFF10B981),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Super Administrador • Cuenta con Privilegios Totales',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else if (isActiva && (memb?.diasRestantes ?? 0) > 3)
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Membresía al Día',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            memb?.renovacionAutomatica == true
                                ? 'Próximo cobro automático: ${memb?.fechaFin != null ? dateFormat.format(memb!.fechaFin!) : "Programado"}'
                                : 'Activa hasta: ${memb?.fechaFin != null ? dateFormat.format(memb!.fechaFin!) : ""}',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (memb?.tieneMetodoPago == true)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.credit_card_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tarjeta guardada para auto-débito',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                GradientButton(
                  label: isActiva
                      ? r'Renovar Membresía ($25.000 COP)'
                      : r'Pagar y Activar Membresía ($25.000 COP)',
                  icon: Icons.payment_rounded,
                  isLoading: isPaying,
                  onPressed: isPaying ? null : () => _handlePayment(context),
                ),
                if (isActiva)
                  Text(
                    '⚠️ Tu membresía vence en ${memb?.diasRestantes ?? 0} días',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFF59E0B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAutoRenewalCard(
    BuildContext context,
    MembresiaModel? memb,
    AppThemeColors themeColors,
  ) {
    final isAutoRenew = memb?.renovacionAutomatica ?? false;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: themeColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isAutoRenew ? AppColors.accent : Colors.grey)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isAutoRenew
                  ? Icons.autorenew_rounded
                  : Icons.pause_circle_outline_rounded,
              color: isAutoRenew ? AppColors.accent : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Renovación Automática',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAutoRenew
                      ? 'Activa. Tu membresía se renovará automáticamente al finalizar el período.'
                      : 'Desactivada. Tu membresía finalizará cuando venza la fecha actual.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: themeColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isAutoRenew)
            TextButton(
              onPressed: () => _handleCancelRenewal(context),
              child: Text(
                'Desactivar',
                style: GoogleFonts.inter(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitsGrid(
    BuildContext context,
    bool isValidator,
    bool isAdminOrSuperAdmin,
    AppThemeColors themeColors,
  ) {
    final benefits = isAdminOrSuperAdmin
        ? [
            {
              'icon': Icons.admin_panel_settings_rounded,
              'title': 'Control Maestro Total',
              'desc': 'Acceso pleno e ilimitado a toda la plataforma sin costo ni requerimiento de afiliación.',
            },
            {
              'icon': Icons.storefront_rounded,
              'title': 'Gestión de Comercios Aliados',
              'desc': 'Administra y autoriza empresas y validadores de negocios en el ecosistema.',
            },
            {
              'icon': Icons.card_giftcard_rounded,
              'title': 'Catálogo de Beneficios',
              'desc': 'Crea, supervisa y audita todos los beneficios y cupones publicados.',
            },
            {
              'icon': Icons.confirmation_number_rounded,
              'title': 'Control y Sorteo de Rifas',
              'desc': 'Gestiona rifas, asigna boletos, ejecuta sorteos y registra ganadores.',
            },
          ]
        : isValidator
            ? [
                {
                  'icon': Icons.qr_code_scanner_rounded,
                  'title': 'Validación de Cupones',
                  'desc': 'Escanea y valida cupones de descuento de clientes Conexiate.',
                },
                {
                  'icon': Icons.storefront_rounded,
                  'title': 'Presencia en la Red Aliada',
                  'desc': 'Aparece visible en la lista de comercios y negocios de la app.',
                },
                {
                  'icon': Icons.card_giftcard_rounded,
                  'title': 'Publicación de Beneficios',
                  'desc': 'Crea ofertas y promociones exclusivas para atraer clientes.',
                },
                {
                  'icon': Icons.analytics_rounded,
                  'title': 'Reporte de Redenciones',
                  'desc': 'Monitorea en tiempo real todas las visitas y compras generadas.',
                },
              ]
            : [
                {
                  'icon': Icons.local_offer_rounded,
                  'title': 'Descuentos Exclusivos',
                  'desc': 'Acceso a precios especiales y promociones en toda la red aliada.',
                },
                {
                  'icon': Icons.confirmation_number_rounded,
                  'title': 'Rifas Mensuales',
                  'desc': 'Participación directa y boletos automáticos en premios del sistema.',
                },
                {
                  'icon': Icons.share_rounded,
                  'title': 'Sistema de Referidos',
                  'desc': 'Invita a tus amigos y genera ganancias automáticas por cada afiliación.',
                },
                {
                  'icon': Icons.support_agent_rounded,
                  'title': 'Soporte Prioritario',
                  'desc': 'Atención rápida y canales directos con el equipo de Conexiate.',
                },
              ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        mainAxisExtent: 130,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: benefits.length,
      itemBuilder: (context, index) {
        final b = benefits[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: themeColors.borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  b['icon'] as IconData,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b['title'] as String,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: themeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b['desc'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: themeColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
