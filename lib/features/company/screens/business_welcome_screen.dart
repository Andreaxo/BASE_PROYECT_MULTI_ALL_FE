import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_alert.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/outline_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../benefits/providers/benefit_provider.dart';
import '../../benefits/providers/redemption_provider.dart';
import '../../company/services/company_service.dart';
import '../../membresia/providers/membresia_provider.dart';

/// Screen displayed to Business Validators when they log in.
/// Provides a warm greeting, displays the company name and role explanation,
/// shows the company subscription status, and offers quick access cards.
class BusinessWelcomeScreen extends StatefulWidget {
  const BusinessWelcomeScreen({super.key});

  @override
  State<BusinessWelcomeScreen> createState() => _BusinessWelcomeScreenState();
}

class _BusinessWelcomeScreenState extends State<BusinessWelcomeScreen> {
  bool _isCheckingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    try {
      final auth = context.read<AuthProvider>();
      await auth.refreshProfile();
      if (!mounted) return;
      await context.read<MembresiaProvider>().loadMiMembresia(silent: true);
      if (!mounted) return;
      context.read<BenefitProvider>().loadMyCompanyBenefits();
      context.read<RedemptionProvider>().loadCompanyRedemptions();
    } catch (_) {
      // Ignorar errores de refresco en segundo plano
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final benefitProvider = context.watch<BenefitProvider>();
    final redemptionProvider = context.watch<RedemptionProvider>();
    final membresiaProvider = context.watch<MembresiaProvider>();
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppTheme.darkThemeColors;

    final userName = authProvider.userName.isNotEmpty
        ? authProvider.userName
        : 'Validador';
    final company = authProvider.activeCompany ??
        (authProvider.userCompanies.isNotEmpty ? authProvider.userCompanies.first : null);

    String companyName = '';
    if (company != null) {
      companyName = company.name.isNotEmpty
          ? company.name
          : (company.razonSocial?.isNotEmpty == true ? company.razonSocial! : '');
    }
    if (companyName.isEmpty && authProvider.currentUser?.companies.isNotEmpty == true) {
      final c = authProvider.currentUser!.companies.first;
      companyName = c.name.isNotEmpty ? c.name : (c.razonSocial ?? '');
    }
    if (companyName.isEmpty) {
      companyName = 'Empresa Aliada';
    }

    final memb = membresiaProvider.miMembresia;
    final rawCompEstado = (company?.suscripcionEstado ?? 'prueba').toLowerCase();
    final isCompanyDisabled = (company != null && !company.isActive);

    // Una empresa está inactiva si está explícitamente desactivada o su suscripción está en inactivo/a
    final isCompanyInactive = isCompanyDisabled ||
        rawCompEstado == 'inactiva' ||
        rawCompEstado == 'inactivo';

    final effectiveEstado = isCompanyInactive
        ? 'inactiva'
        : ((memb != null &&
                memb.estado.isNotEmpty &&
                memb.estado.toLowerCase() != 'inactiva' &&
                memb.estado.toLowerCase() != 'inactivo')
            ? memb.estado.toLowerCase()
            : rawCompEstado);

    // Si aún se está comprobando el estado con el backend y localmente parecía inactiva,
    // evitamos mostrar bruscamente la pantalla de bloqueo durante ese segundo.
    if (isCompanyInactive && _isCheckingStatus) {
      return Scaffold(
        backgroundColor: themeColors.gradientBg.first,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Comprobando estado del negocio...',
                style: GoogleFonts.inter(
                  color: themeColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isCompanyInactive) {
      return Scaffold(
        backgroundColor: themeColors.gradientBg.first,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.hub_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Conexiate',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: themeColors.textPrimary,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                onPressed: () => context.read<AuthProvider>().logout(),
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                label: Text(
                  'Cerrar Sesión',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: themeColors.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.domain_disabled_rounded,
                        color: Color(0xFFEF4444),
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Perfil de Negocio Inactivo',
                      style: GoogleFonts.outfit(
                        color: themeColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        companyName,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tu cuenta de negocio aliado ha sido desactivada por el administrador del sistema. Por motivos de seguridad y control operativo, el acceso a las demás opciones del sistema, la publicación de beneficios y la validación de redenciones se encuentran completamente pausadas.',
                      style: GoogleFonts.inter(
                        color: themeColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.contact_support_outlined,
                            color: Color(0xFF3B82F6),
                            size: 26,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¿Cómo reactivar tu cuenta?',
                                  style: GoogleFonts.inter(
                                    color: themeColors.textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ponte en contacto con nuestro equipo de soporte o envía una alerta directa de desbloqueo al superadministrador.',
                                  style: GoogleFonts.inter(
                                    color: themeColors.textSecondary,
                                    fontSize: 12.5,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmall = constraints.maxWidth < 420;
                        final logoutBtn = OutlineButtonWidget(
                          label: 'Cerrar Sesión',
                          icon: Icons.logout_rounded,
                          onPressed: () => context.read<AuthProvider>().logout(),
                          width: isSmall ? double.infinity : 160,
                        );
                        final supportBtn = GradientButton(
                          label: 'Contactar a Soporte',
                          icon: Icons.support_agent_rounded,
                          width: isSmall ? double.infinity : 220,
                          onPressed: () => _showSupportModal(context, companyName, themeColors),
                        );

                        if (isSmall) {
                          return Column(
                            children: [
                              supportBtn,
                              const SizedBox(height: 12),
                              logoutBtn,
                            ],
                          );
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            logoutBtn,
                            const SizedBox(width: 14),
                            supportBtn,
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final isSubscriptionActive =
        !isCompanyInactive &&
        (effectiveEstado == 'prueba' || effectiveEstado == 'activa');

    final totalBenefits = benefitProvider.benefits.length;
    final activeBenefits =
        benefitProvider.benefits.where((b) => b.isActive).length;
    final totalRedemptions = redemptionProvider.companyRedemptions.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DashboardShell(
      title: 'Panel de Negocio',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Banner de Bienvenida ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF0F172A)]
                      : [themeColors.cardBackground, const Color(0xFFEEF2FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accent, AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡Bienvenido, $userName!',
                              style: GoogleFonts.outfit(
                                color: isDark ? Colors.white : themeColors.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.business_center_rounded,
                                  color: AppColors.accent.withValues(alpha: 0.9),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    companyName,
                                    style: GoogleFonts.inter(
                                      color: isDark ? Colors.white.withValues(alpha: 0.9) : themeColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildSubscriptionPill(effectiveEstado),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.07) : themeColors.textPrimary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.12) : themeColors.borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Recuerda que este es tu sitio para administrar los beneficios de tu empresa y validar las redenciones de tus clientes.',
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white.withValues(alpha: 0.95) : themeColors.textSecondary,
                              fontSize: 14,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Alerta si la suscripción no está activa ───────────────────
            if (!isSubscriptionActive)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF87171)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFDC2626),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Suscripción de Empresa Inactiva o Vencida',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF991B1B),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'La suscripción de tu empresa se encuentra inactiva o vencida. Para crear nuevos beneficios y publicar promociones, por favor activa tu suscripción comunicándote con el administrador de Conexiate.',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF7F1D1D),
                              fontSize: 13.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // ── Métricas del Negocio ──────────────────────────────────────
            Text(
              'Resumen de tu Empresa',
              style: GoogleFonts.outfit(
                color: themeColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth,
                      child: _buildMetricCard(
                        title: 'Beneficios Totales',
                        value: '$totalBenefits',
                        subtitle: '$activeBenefits activos actualmente',
                        icon: Icons.card_giftcard_rounded,
                        color: AppColors.accent,
                        themeColors: themeColors,
                      ),
                    ),
                    SizedBox(
                      width: isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth,
                      child: _buildMetricCard(
                        title: 'Redenciones Realizadas',
                        value: '$totalRedemptions',
                        subtitle: 'Códigos canjeados en tu local',
                        icon: Icons.check_circle_outline_rounded,
                        color: const Color(0xFF10B981),
                        themeColors: themeColors,
                      ),
                    ),
                    SizedBox(
                      width: isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth,
                      child: _buildMetricCard(
                        title: 'Estado del Negocio',
                        value: isSubscriptionActive ? 'Operativo' : 'Requiere Pago',
                        subtitle: 'Empresa vinculada a Conexiate',
                        icon: Icons.verified_rounded,
                        color: isSubscriptionActive ? const Color(0xFF6366F1) : const Color(0xFFEF4444),
                        themeColors: themeColors,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // ── Acciones Rápidas (Tarjetas de Módulos) ─────────────────────
            Text(
              'Acciones Rápidas',
              style: GoogleFonts.outfit(
                color: themeColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 750;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    // Tarjeta 1: Validar Redenciones
                    SizedBox(
                      width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                      child: _buildActionCard(
                        context: context,
                        icon: Icons.qr_code_scanner_rounded,
                        iconColor: const Color(0xFF4ECDC4),
                        title: 'Validar Redenciones',
                        description:
                            'Ingresa o valida los códigos alfanuméricos presentados por los clientes afiliados para entregar sus beneficios.',
                        buttonText: 'Ir al Validador',
                        route: '/redemptions',
                        themeColors: themeColors,
                      ),
                    ),

                    // Tarjeta 2: Gestionar Mis Beneficios
                    SizedBox(
                      width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                      child: _buildActionCard(
                        context: context,
                        icon: Icons.card_giftcard_rounded,
                        iconColor: const Color(0xFFFF9F43),
                        title: 'Gestionar Mis Beneficios',
                        description:
                            'Crea nuevos descuentos, edita las condiciones de las promociones existentes o activa/desactiva ofertas de tu comercio.',
                        buttonText: 'Administrar Beneficios',
                        route: '/company-benefits',
                        themeColors: themeColors,
                      ),
                    ),

                    // Tarjeta 3: Mi Membresía / Suscripción
                    SizedBox(
                      width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                      child: _buildActionCard(
                        context: context,
                        icon: Icons.workspace_premium_rounded,
                        iconColor: const Color(0xFFA55EEA),
                        title: 'Membresía del Negocio Aliado',
                        description:
                            'Consulta el estado de tu membresía de prueba por 1 año, fechas de vigencia y beneficios habilitados.',
                        buttonText: 'Ver Membresía',
                        route: '/membresia',
                        themeColors: themeColors,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionPill(String estado) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (estado) {
      case 'activa':
        bg = const Color(0xFF10B981).withValues(alpha: 0.2);
        fg = const Color(0xFF34D399);
        label = 'Suscripción Activa';
        icon = Icons.check_circle_rounded;
        break;
      case 'prueba':
        bg = const Color(0xFF10B981).withValues(alpha: 0.18);
        fg = const Color(0xFF10B981);
        label = 'Membresía de Prueba (1 Año)';
        icon = Icons.card_giftcard_rounded;
        break;
      case 'inactiva':
      case 'inactivo':
        bg = const Color(0xFFEF4444).withValues(alpha: 0.2);
        fg = const Color(0xFFF87171);
        label = 'Perfil Inactivo';
        icon = Icons.domain_disabled_rounded;
        break;
      case 'vencida':
      default:
        bg = const Color(0xFFEF4444).withValues(alpha: 0.2);
        fg = const Color(0xFFF87171);
        label = 'Suscripción Vencida';
        icon = Icons.cancel_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: fg,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required AppThemeColors themeColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: themeColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: themeColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: themeColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: themeColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String buttonText,
    required String route,
    required AppThemeColors themeColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: themeColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: themeColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.inter(
              color: themeColors.textSecondary,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(route);
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                buttonText,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSupportModal(BuildContext context, String companyName, AppThemeColors themeColors) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        bool isSending = false;
        bool hasSentNotification = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: themeColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: themeColors.borderColor),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.support_agent_rounded,
                              color: AppColors.primary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Solicitud de Desbloqueo',
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: themeColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  companyName,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: themeColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: themeColors.textSecondary),
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Tu cuenta de negocio se encuentra actualmente pausada. Puedes solicitar la reactivación a través de cualquiera de las siguientes opciones:',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: themeColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Opción 1: Notificación directa al Super Admin
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.notifications_active_rounded,
                                  color: AppColors.accent,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Alerta directa al Superadministrador',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: themeColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Envía una notificación instantánea al panel del superadministrador solicitando la reactivación de tu negocio.',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: themeColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (hasSentNotification) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF10B981),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '¡Solicitud enviada! El superadministrador ha recibido tu notificación de desbloqueo.',
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF10B981),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              if (errorMessage != null) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    errorMessage!,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFEF4444),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: isSending
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.send_rounded, size: 17),
                                  label: Text(
                                    isSending ? 'Enviando solicitud...' : 'Notificar al Administrador',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: isSending
                                      ? null
                                      : () async {
                                          setModalState(() {
                                            isSending = true;
                                            errorMessage = null;
                                          });
                                          try {
                                            await CompanyApiService.solicitarReactivacion();
                                            setModalState(() {
                                              isSending = false;
                                              hasSentNotification = true;
                                            });
                                            if (context.mounted) {
                                              CustomAlert.show(
                                                context,
                                                message: 'Notificación de reactivación enviada al superadministrador con éxito.',
                                                isSuccess: true,
                                              );
                                            }
                                          } catch (e) {
                                            setModalState(() {
                                              isSending = false;
                                              errorMessage = e.toString().replaceFirst('Exception: ', '');
                                            });
                                          }
                                        },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Opción 2: Correo de soporte
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: themeColors.sidebarBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: themeColors.borderColor,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.email_outlined,
                                  color: Color(0xFF3B82F6),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Correo oficial de soporte',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: themeColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Escribe detallando tu solicitud y datos de tu empresa a:',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: themeColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: themeColors.cardBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: themeColors.borderColor),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: SelectableText(
                                      'soporte@conexiate.co',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded, size: 18),
                                    color: themeColors.textSecondary,
                                    tooltip: 'Copiar correo',
                                    onPressed: () {
                                      Clipboard.setData(
                                        const ClipboardData(text: 'soporte@conexiate.co'),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Correo copiado al portapapeles: soporte@conexiate.co'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botón Cerrar
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          child: Text(
                            'Cerrar',
                            style: GoogleFonts.inter(
                              color: themeColors.textSecondary,
                              fontWeight: FontWeight.w600,
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
          },
        );
      },
    );
  }
}
