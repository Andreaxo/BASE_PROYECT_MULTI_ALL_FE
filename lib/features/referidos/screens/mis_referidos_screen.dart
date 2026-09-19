import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_alert.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/widgets/membership_gate_banner.dart';
import '../../auth/providers/auth_provider.dart';
import '../../membresia/providers/membresia_provider.dart';
import '../models/referido_model.dart';
import '../providers/referido_provider.dart';
import '../../../core/widgets/custom_pagination_footer.dart';

class MisReferidosScreen extends StatefulWidget {
  const MisReferidosScreen({super.key});

  @override
  State<MisReferidosScreen> createState() => _MisReferidosScreenState();
}

class _MisReferidosScreenState extends State<MisReferidosScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    context.read<ReferidoProvider>().resetSilent();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MembresiaProvider>().loadMiMembresia();
      context.read<ReferidoProvider>().loadMisReferidos();
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

  void _showInviteDialog() {
    final authProvider = context.read<AuthProvider>();
    final membresiaProvider = context.read<MembresiaProvider>();
    if (!authProvider.isAdminOrSuperAdmin && !membresiaProvider.hasActiveMembership) {
      showDialog(
        context: context,
        builder: (ctx) {
          final themeColors =
              Theme.of(ctx).extension<AppThemeColors>() ??
              AppTheme.darkThemeColors;
          return AlertDialog(
            backgroundColor: themeColors.cardBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.lock_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Membresía Requerida',
                  style: GoogleFonts.outfit(
                    color: themeColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Text(
              'Para invitar referidos y generar recompensas por cada nuevo afiliado, necesitas contar con una membresía activa en Conexiate.',
              style: GoogleFonts.inter(
                color: themeColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cerrar', style: GoogleFonts.inter(color: themeColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed('/mi-membresia');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Activar Membresía', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
      return;
    }

    final emailCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        final themeColors =
            Theme.of(ctx).extension<AppThemeColors>() ??
            AppTheme.darkThemeColors;
        return AlertDialog(
          backgroundColor: themeColors.cardBackground,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Invitar a un amigo',
            style: GoogleFonts.outfit(
              color: themeColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailCtrl,
                  style: GoogleFonts.inter(color: themeColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico *',
                    labelStyle:
                        GoogleFonts.inter(color: themeColors.textSecondary),
                    prefixIcon: Icon(Icons.email_outlined,
                        color: themeColors.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: themeColors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'El correo es requerido';
                    if (!v.contains('@')) return 'Ingrese un correo válido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nombreCtrl,
                  style: GoogleFonts.inter(color: themeColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nombre (opcional)',
                    labelStyle:
                        GoogleFonts.inter(color: themeColors.textSecondary),
                    prefixIcon: Icon(Icons.person_outline,
                        color: themeColors.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: themeColors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
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
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                final provider = context.read<ReferidoProvider>();
                final success = await provider.createReferido(
                  CreateReferidoRequest(
                    emailReferido: emailCtrl.text.trim(),
                    nombreReferido: nombreCtrl.text.trim().isEmpty
                        ? null
                        : nombreCtrl.text.trim(),
                  ),
                );
                if (mounted) {
                  CustomAlert.show(
                    context,
                    message: success
                        ? 'Invitación enviada correctamente'
                        : provider.errorMessage ?? 'Error al enviar invitación',
                    isSuccess: success,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Enviar invitación',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return AppColors.warning;
      case 'registrado':
        return AppColors.primary;
      case 'afiliado':
        return AppColors.accent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAvatar(Referido referido, AppThemeColors themeColors) {
    final String displayName = referido.nombreReferido?.isNotEmpty == true
        ? referido.nombreReferido!
        : referido.nombreReferidoUser.isNotEmpty == true
            ? referido.nombreReferidoUser
            : 'Invitado';
    final String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    final List<Color> gradientColors;
    final int hash = initial.codeUnitAt(0);
    if (hash % 3 == 0) {
      gradientColors = [const Color(0xFF6C63FF), const Color(0xFF3B82F6)];
    } else if (hash % 3 == 1) {
      gradientColors = [const Color(0xFF10B981), const Color(0xFF3B82F6)];
    } else {
      gradientColors = [const Color(0xFFF59E0B), const Color(0xFFEF4444)];
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(Referido referido) {
    final color = _getEstadoColor(referido.estado);
    IconData icon;
    switch (referido.estado) {
      case 'pendiente':
        icon = Icons.schedule_rounded;
        break;
      case 'registrado':
        icon = Icons.login_rounded;
        break;
      case 'afiliado':
        icon = Icons.verified_rounded;
        break;
      default:
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
        boxShadow: [
          if (referido.estado == 'afiliado')
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 6,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Text(
            referido.estadoLabel,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecompensaBadge(Referido referido, AppThemeColors themeColors) {
    if (referido.recompensaOtorgada) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFA500).withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: Colors.black, size: 13),
            const SizedBox(width: 4),
            Text(
              'Otorgada',
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: themeColors.textSecondary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: themeColors.borderColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty_rounded, color: themeColors.textSecondary, size: 12),
            const SizedBox(width: 5),
            Text(
              'Pendiente',
              style: GoogleFonts.inter(
                color: themeColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReferidoProvider>();
    final membresiaProvider = context.watch<MembresiaProvider>();
    final authProvider = context.watch<AuthProvider>();
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppTheme.darkThemeColors;

    // Filter
    final filtered = provider.misReferidos.where((r) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery;
      return r.emailReferido.toLowerCase().contains(q) ||
          (r.nombreReferido?.toLowerCase().contains(q) ?? false) ||
          r.estadoLabel.toLowerCase().contains(q);
    }).toList();

    // Stats
    final total = provider.misReferidos.length;
    final pendientes =
        provider.misReferidos.where((r) => r.estado == 'pendiente').length;
    final registrados =
        provider.misReferidos.where((r) => r.estado == 'registrado').length;
    final afiliados =
        provider.misReferidos.where((r) => r.estado == 'afiliado').length;

    // Pagination
    final totalItems = filtered.length;
    final totalPages = (totalItems / _rowsPerPage).ceil();
    final safeTotalPages = totalPages == 0 ? 1 : totalPages;
    if (_currentPage > safeTotalPages) _currentPage = safeTotalPages;
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex =
        (startIndex + _rowsPerPage).clamp(0, totalItems);
    final pageItems =
        totalItems > 0 ? filtered.sublist(startIndex, endIndex) : <Referido>[];

    return DashboardShell(
      title: 'Mis Referidos',
      child: provider.isLoadingMis
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Breadcrumbs ──
                  Row(
                    children: [
                      Text('Inicio',
                          style: GoogleFonts.inter(
                              color: themeColors.textSecondary.withValues(alpha: 0.5),
                              fontSize: 13)),
                      Icon(Icons.chevron_right_rounded,
                          color: themeColors.textSecondary.withValues(alpha: 0.5),
                          size: 14),
                      Text('Mis Referidos',
                          style: GoogleFonts.inter(
                              color: themeColors.textPrimary.withValues(alpha: 0.8),
                              fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Header Row ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mis Referidos',
                            style: GoogleFonts.outfit(
                              color: themeColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Comparte tu código de invitación y gestiona tus referidos',
                            style: GoogleFonts.inter(
                              color: themeColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _showInviteDialog,
                          icon: const Icon(Icons.person_add_alt_1_rounded,
                              size: 20, color: Colors.white),
                          label: Text(
                            'Invitar Referido',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Gating Banner ──
                  const MembershipGateBanner(
                    featureName: 'las recompensas de referidos',
                  ),

                  // ── Code Refer Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0F0C29),
                          Color(0xFF302B63),
                          Color(0xFF24243E),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
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
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.accent],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.share_rounded,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tu código de referido',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Comparte tu código para invitar a más personas',
                                    style: GoogleFonts.inter(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (provider.codeRefer.isNotEmpty)
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.tag_rounded,
                                          color: AppColors.primary, size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        provider.codeRefer,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 6,
                                          shadows: [
                                            Shadow(
                                              color: AppColors.accent.withValues(alpha: 0.5),
                                              blurRadius: 12,
                                            ),
                                            Shadow(
                                              color: AppColors.primary.withValues(alpha: 0.4),
                                              blurRadius: 24,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Clipboard.setData(
                                      ClipboardData(text: provider.codeRefer),
                                    );
                                    CustomAlert.show(
                                      context,
                                      message:
                                          'Código copiado al portapapeles',
                                      isSuccess: true,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.accent,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.copy_rounded,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.lock_clock_rounded,
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
                                        'Código disponible con membresía activa',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Activa tu membresía mensual Conexiate para desbloquear tu código de invitación y acumular comisiones.',
                                        style: GoogleFonts.inter(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed('/mi-membresia');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.flash_on_rounded, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Activar',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Stats Row ──
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      final cards = [
                        _ReferralStatCard(
                          label: 'Total Invitaciones',
                          value: total.toString(),
                          icon: Icons.people_alt_outlined,
                          accentColor: const Color(0xFF6C63FF),
                        ),
                        _ReferralStatCard(
                          label: 'Pendientes',
                          value: pendientes.toString(),
                          icon: Icons.hourglass_empty_rounded,
                          accentColor: AppColors.warning,
                        ),
                        _ReferralStatCard(
                          label: 'Registrados',
                          value: registrados.toString(),
                          icon: Icons.person_add_alt_1_rounded,
                          accentColor: const Color(0xFF3B82F6),
                        ),
                        _ReferralStatCard(
                          label: 'Afiliados',
                          value: afiliados.toString(),
                          icon: Icons.verified_rounded,
                          accentColor: const Color(0xFF10B981),
                        ),
                      ];

                      if (isWide) {
                        return Row(
                          children: cards
                              .map((c) => Expanded(
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      child: c)))
                              .toList(),
                        );
                      } else {
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: cards
                              .map((c) =>
                                  SizedBox(width: constraints.maxWidth / 2 - 18, child: c))
                              .toList(),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── Header: search + invite button ──
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: themeColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: themeColors.borderColor),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.inter(
                                color: themeColors.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Buscar por email, nombre o estado...',
                              hintStyle: GoogleFonts.inter(
                                  color: themeColors.textSecondary,
                                  fontSize: 14),
                              prefixIcon: Icon(Icons.search_rounded,
                                  color: themeColors.textSecondary),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _showInviteDialog,
                        icon: const Icon(Icons.person_add_alt_1_rounded,
                            size: 18),
                        label: Text(
                          'Invitar',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Table ──
                  Container(
                    decoration: BoxDecoration(
                      color: themeColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: themeColors.borderColor),
                    ),
                    child: Column(
                      children: [
                        // Table header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.tableHeaderBg,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                          child: Row(
                            children: [
                              _headerCell('Usuario Referido', flex: 4),
                              _headerCell('Estado', flex: 2),
                              _headerCell('Recompensa', flex: 2),
                              _headerCell('Fecha de Invitación', flex: 2),
                            ],
                          ),
                        ),
                        // Table rows
                        if (pageItems.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                (!authProvider.isAdminOrSuperAdmin && !membresiaProvider.hasActiveMembership)
                                    ? 'Tu red de referidos se activará con tu membresía.\n¡Actívala hoy y comienza a invitar a tus conocidos!'
                                    : (filtered.isEmpty && _searchQuery.isEmpty
                                        ? 'Aún no has invitado a nadie.\n¡Comparte tu código para empezar!'
                                        : 'No se encontraron resultados'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: themeColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ...pageItems.map((r) => _buildRow(r, themeColors)),

                        // Pagination
                        CustomPaginationFooter(
                          totalItems: totalItems,
                          currentPage: _currentPage,
                          rowsPerPage: _rowsPerPage,
                          onPageChanged: (newPage) =>
                              setState(() => _currentPage = newPage),
                          onRowsPerPageChanged: (newSize) => setState(() {
                            _rowsPerPage = newSize;
                            _currentPage = 1;
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _headerCell(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRow(Referido r, AppThemeColors themeColors) {
    return _ReferidoRow(
      referido: r,
      themeColors: themeColors,
      avatar: _buildAvatar(r, themeColors),
      estadoBadge: _buildEstadoBadge(r),
      recompensaBadge: _buildRecompensaBadge(r, themeColors),
      dateString: _formatDate(r.fechaReferido),
    );
  }


  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

// ── Custom row item with premium hover states ──
class _ReferidoRow extends StatefulWidget {
  final Referido referido;
  final AppThemeColors themeColors;
  final Widget avatar;
  final Widget estadoBadge;
  final Widget recompensaBadge;
  final String dateString;

  const _ReferidoRow({
    required this.referido,
    required this.themeColors,
    required this.avatar,
    required this.estadoBadge,
    required this.recompensaBadge,
    required this.dateString,
  });

  @override
  State<_ReferidoRow> createState() => _ReferidoRowState();
}

class _ReferidoRowState extends State<_ReferidoRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _isHovered 
              ? widget.themeColors.cardBackground.withRed(30).withGreen(30).withBlue(50).withValues(alpha: 0.4)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: _isHovered 
                  ? AppColors.primary.withValues(alpha: 0.4) 
                  : widget.themeColors.borderColor,
              width: _isHovered ? 1.2 : 1,
            ),
          ),
          boxShadow: _isHovered ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  widget.avatar,
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.referido.nombreReferido?.isNotEmpty == true
                              ? widget.referido.nombreReferido!
                              : widget.referido.nombreReferidoUser.isNotEmpty == true
                                  ? widget.referido.nombreReferidoUser
                                  : 'Invitado',
                          style: GoogleFonts.outfit(
                            color: widget.themeColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 12,
                              color: widget.themeColors.textSecondary.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.referido.emailReferido,
                                style: GoogleFonts.inter(
                                  color: widget.themeColors.textSecondary,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: widget.estadoBadge,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: widget.recompensaBadge,
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 12,
                    color: widget.themeColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.dateString,
                    style: GoogleFonts.inter(
                      color: widget.themeColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom premium statistics card ──
class _ReferralStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _ReferralStatCard({
    required this.accentColor,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeColors.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 13,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        color: themeColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: themeColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Positioned(
            right: -4,
            bottom: -8,
            child: Icon(
              icon,
              size: 50,
              color: accentColor.withValues(alpha: 0.04),
            ),
          ),
        ],
      ),
    );
  }
}

