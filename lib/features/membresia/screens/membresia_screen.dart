import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _MembresiaScreenState extends State<MembresiaScreen>
    with WidgetsBindingObserver {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MembresiaProvider>().loadMiMembresia();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User switched back to this window after completing payment in Wompi tab
      context.read<MembresiaProvider>().loadMiMembresia();
    }
  }

  Future<void> _handlePayment() async {
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
        _showPaymentModal(resp);
      }
    } else {
      final error = provider.errorMessage ?? 'Error al generar orden de pago';
      if (mounted) {
        CustomAlert.show(context, message: error, isSuccess: false);
      }
    }
  }

  void _showPaymentModal(IniciarPagoResponse resp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _WompiPaymentModalDialog(
        resp: resp,
        onRetry: () {
          _handlePayment();
        },
        onCompleted: () {
          if (mounted) {
            context.read<MembresiaProvider>().loadMiMembresia();
            CustomAlert.show(
              context,
              message:
                  '🎉 ¡Pago confirmado con éxito! Tu membresía ya está activa y tienes acceso a todos los beneficios exclusivos.',
              isSuccess: true,
              duration: const Duration(seconds: 8),
            );
          }
        },
      ),
    ).then((_) {
      if (mounted) {
        context.read<MembresiaProvider>().loadMiMembresia();
      }
    });
  }

  Future<void> _handleCancelRenewal() async {
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
    final isAdminOrSuperAdmin = authProvider.isAdminOrSuperAdmin || authProvider.roleCode == 'operador';
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
                  onPressed: isPaying ? null : _handlePayment,
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
              onPressed: _handleCancelRenewal,
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

// ---------------------------------------------------------------------------
// MODAL DE PAGO WOMPI REDISEÑADO (MODERNO, SEGURO Y CON AUTO-SINCRONIZACIÓN)
// ---------------------------------------------------------------------------

enum PaymentModalStatus { waiting, approved, declined }

class _WompiPaymentModalDialog extends StatefulWidget {
  final IniciarPagoResponse resp;
  final VoidCallback? onRetry;
  final VoidCallback onCompleted;

  const _WompiPaymentModalDialog({
    required this.resp,
    this.onRetry,
    required this.onCompleted,
  });

  @override
  State<_WompiPaymentModalDialog> createState() =>
      _WompiPaymentModalDialogState();
}

class _WompiPaymentModalDialogState extends State<_WompiPaymentModalDialog> {
  Timer? _pollTimer;
  PaymentModalStatus _status = PaymentModalStatus.waiting;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer =
        Timer.periodic(const Duration(milliseconds: 2500), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final provider = context.read<MembresiaProvider>();
      await provider.loadMiMembresia(silent: true);
      if (!mounted) return;

      if (provider.hasActiveMembership ||
          provider.miMembresia?.isUltimoPagoAprobado == true) {
        timer.cancel();
        setState(() {
          _status = PaymentModalStatus.approved;
        });
      } else if (provider.miMembresia?.isUltimoPagoRechazado == true) {
        timer.cancel();
        setState(() {
          _status = PaymentModalStatus.declined;
        });
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _copyReference() {
    Clipboard.setData(ClipboardData(text: widget.resp.referencia));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppTheme.darkThemeColors;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          decoration: BoxDecoration(
            color: themeColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: themeColors.borderColor.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0.2),
                            AppColors.primary.withValues(alpha: 0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Pasarela Wompi',
                                style: GoogleFonts.outfit(
                                  color: themeColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  'Bancolombia',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF10B981),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Transacción cifrada y protegida',
                            style: GoogleFonts.inter(
                              color: themeColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: themeColors.textSecondary,
                        size: 20,
                      ),
                      tooltip: 'Cerrar ventana',
                      onPressed: () {
                        _pollTimer?.cancel();
                        Navigator.of(context).pop();
                        widget.onCompleted();
                      },
                    ),
                  ],
                ),
              ),

              // Body based on status
              Padding(
                padding: const EdgeInsets.all(22),
                child: _buildBody(themeColors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppThemeColors themeColors) {
    switch (_status) {
      case PaymentModalStatus.waiting:
        return _buildWaitingView(themeColors);
      case PaymentModalStatus.approved:
        return _buildApprovedView(themeColors);
      case PaymentModalStatus.declined:
        return _buildDeclinedView(themeColors);
    }
  }

  Widget _buildWaitingView(AppThemeColors themeColors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Order details card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: themeColors.cardBackground.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: themeColors.borderColor.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Suscripción:',
                    style: GoogleFonts.inter(
                      color: themeColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Membresía Mensual',
                    style: GoogleFonts.inter(
                      color: themeColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                  InkWell(
                    onTap: _copyReference,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Row(
                        children: [
                          Text(
                            widget.resp.referencia,
                            style: GoogleFonts.inter(
                              color: themeColors.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _copied
                                ? Icons.check_circle_rounded
                                : Icons.copy_rounded,
                            size: 14,
                            color: _copied
                                ? const Color(0xFF10B981)
                                : themeColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  color: themeColors.borderColor.withValues(alpha: 0.5),
                  height: 1,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total a pagar:',
                    style: GoogleFonts.inter(
                      color: themeColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    r'$25.000 COP',
                    style: GoogleFonts.outfit(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Live status container
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sincronizando pago en tiempo real...',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Al completar la transacción en la pasarela de Wompi, tus beneficios se activarán automáticamente sin que tengas que presionar nada.',
                style: GoogleFonts.inter(
                  color: themeColors.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Reabrir pasarela
        if (widget.resp.checkoutUrl.isNotEmpty) ...[
          ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.tryParse(widget.resp.checkoutUrl);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Reabrir pestaña de Wompi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        TextButton(
          onPressed: () {
            _pollTimer?.cancel();
            Navigator.of(context).pop();
            widget.onCompleted();
          },
          child: Text(
            'Cerrar ventana (puedes continuar navegando)',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: themeColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovedView(AppThemeColors themeColors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF10B981),
            size: 38,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '¡Pago Confirmado con Éxito!',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: themeColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tu membresía Conexiate ya está activa. Tienes acceso inmediato a todos los descuentos y beneficios exclusivos.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: themeColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.stars_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Vigencia: 30 días de beneficios activos',
                style: GoogleFonts.inter(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onCompleted();
            },
            icon: const Icon(Icons.celebration_rounded, size: 18),
            label: const Text('¡Comenzar a disfrutar!'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeclinedView(AppThemeColors themeColors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.cancel_rounded,
            color: Colors.redAccent,
            size: 38,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Transacción No Procesada',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: themeColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'La entidad financiera o Wompi no pudo autorizar el pago. Revisa los fondos o intenta con otra tarjeta o método de pago.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: themeColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onCompleted();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: themeColors.textSecondary,
                  side: BorderSide(color: themeColors.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cerrar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onRetry?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
