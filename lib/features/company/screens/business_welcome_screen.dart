import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../auth/providers/auth_provider.dart';
import '../../benefits/providers/benefit_provider.dart';
import '../../benefits/providers/redemption_provider.dart';

/// Screen displayed to Business Validators when they log in.
/// Provides a warm greeting, displays the company name and role explanation,
/// shows the company subscription status, and offers quick access cards.
class BusinessWelcomeScreen extends StatefulWidget {
  const BusinessWelcomeScreen({super.key});

  @override
  State<BusinessWelcomeScreen> createState() => _BusinessWelcomeScreenState();
}

class _BusinessWelcomeScreenState extends State<BusinessWelcomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.activeCompany == null) {
        auth.refreshProfile();
      }
      context.read<BenefitProvider>().loadMyCompanyBenefits();
      context.read<RedemptionProvider>().loadCompanyRedemptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final benefitProvider = context.watch<BenefitProvider>();
    final redemptionProvider = context.watch<RedemptionProvider>();
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

    final suscripcionEstado = (company?.suscripcionEstado ?? 'prueba').toLowerCase();
    final isSubscriptionActive =
        suscripcionEstado == 'prueba' || suscripcionEstado == 'activa';

    final totalBenefits = benefitProvider.benefits.length;
    final activeBenefits =
        benefitProvider.benefits.where((b) => b.isActive).length;
    final totalRedemptions = redemptionProvider.companyRedemptions.length;

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
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF0F172A)],
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
                                color: Colors.white,
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
                                      color: Colors.white.withValues(alpha: 0.9),
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
                      _buildSubscriptionPill(suscripcionEstado),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
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
                              color: Colors.white.withValues(alpha: 0.95),
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
                        title: 'Suscripción de Empresa',
                        description:
                            'Consulta el estado de la suscripción de tu negocio aliado, fechas de corte y canales de pago habilitados.',
                        buttonText: 'Ver Suscripción',
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
        bg = const Color(0xFF3B82F6).withValues(alpha: 0.2);
        fg = const Color(0xFF60A5FA);
        label = 'Período de Prueba';
        icon = Icons.timer_rounded;
        break;
      case 'vencida':
      case 'inactiva':
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
}
