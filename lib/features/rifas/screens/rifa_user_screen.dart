import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_alert.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/widgets/membership_gate_banner.dart';
import '../../../core/widgets/stat_card.dart';
import '../../referidos/providers/referido_provider.dart';
import '../models/rifa_model.dart';
import '../providers/rifa_provider.dart';

/// Pantalla premium para usuarios miembros de Conexiate
/// Ofrece visualización detallada de la rifa en curso, boletos acumulados ("Golden Tickets")
/// con filtrado por origen y el historial completo de ganadores.
class RifaUserScreen extends StatefulWidget {
  const RifaUserScreen({super.key});

  @override
  State<RifaUserScreen> createState() => _RifaUserScreenState();
}

class _RifaUserScreenState extends State<RifaUserScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'afiliacion', 'referido', 'beneficio'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<RifaProvider>().resetSilent();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RifaProvider>().loadUserViewData();
      final refProv = context.read<ReferidoProvider>();
      if (refProv.codeRefer.isEmpty && !refProv.isLoadingMis) {
        refProv.loadMisReferidos();
      }
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
    });
  }

  Color _getOrigenColor(String origen) {
    switch (origen) {
      case 'afiliacion':
        return const Color(0xFF3B82F6); // Sapphire Blue
      case 'referido':
        return const Color(0xFF10B981); // Emerald Green
      case 'beneficio':
        return const Color(0xFFF59E0B); // Amber Gold
      case 'manual':
        return const Color(0xFF8B5CF6); // Royal Purple
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getOrigenIcon(String origen) {
    switch (origen) {
      case 'afiliacion':
        return Icons.verified_rounded;
      case 'referido':
        return Icons.group_add_rounded;
      case 'beneficio':
        return Icons.loyalty_rounded;
      case 'manual':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.stars_rounded;
    }
  }

  Widget _buildOrigenBadge(String origen, String label) {
    final color = _getOrigenColor(origen);
    final icon = _getOrigenIcon(origen);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'activa':
        return AppColors.accent;
      case 'cerrada':
        return AppColors.warning;
      case 'sorteada':
        return const Color(0xFF8B5CF6);
      case 'cancelada':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEstadoBadge(String estado, String label) {
    final color = _getEstadoColor(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getEntregaColor(String estadoEntrega) {
    switch (estadoEntrega) {
      case 'pendiente':
        return AppColors.warning;
      case 'notificado':
        return const Color(0xFF3B82F6);
      case 'entregado':
        return AppColors.accent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEntregaBadge(String estadoEntrega, String label) {
    final color = _getEntregaColor(estadoEntrega);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RifaProvider>();
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;

    final activeRifa = provider.activeRifa;
    final misParticipaciones = provider.misParticipaciones;
    final historial = provider.historialRifas;

    final filteredByOrigin = _selectedFilter == 'all'
        ? misParticipaciones
        : misParticipaciones.where((p) => p.origen == _selectedFilter).toList();

    final filteredParticipaciones = filteredByOrigin.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.numeroParticipacion.toString().contains(_searchQuery) ||
          p.origen.toLowerCase().contains(_searchQuery) ||
          p.origenLabel.toLowerCase().contains(_searchQuery);
    }).toList();

    return DashboardShell(
      title: 'Rifas y Sorteos',
      child: RefreshIndicator(
        onRefresh: () async {
          await provider.loadUserViewData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Breadcrumbs ──
              Row(
                children: [
                  Text(
                    'Inicio',
                    style: GoogleFonts.inter(
                      color: themeColors.textSecondary.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: themeColors.textSecondary.withValues(alpha: 0.5),
                    size: 14,
                  ),
                  Text(
                    'Rifas y Sorteos',
                    style: GoogleFonts.inter(
                      color: themeColors.textPrimary.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Header Title ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sorteos Exclusivos Conexiate',
                          style: GoogleFonts.outfit(
                            color: themeColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Participa con cada boleto acumulado por tu membresía, amigos referidos y canje de beneficios.',
                          style: GoogleFonts.inter(
                            color: themeColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Gating Banner ──
              const MembershipGateBanner(
                featureName: 'las rifas y sorteos exclusivos',
              ),

              // ── Active Rifa Hero Banner ──
              if (provider.isLoadingActive)
                Container(
                  height: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: themeColors.cardBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: themeColors.borderColor),
                  ),
                  child: const CircularProgressIndicator(),
                )
              else if (activeRifa != null)
                _buildActiveRifaHero(activeRifa, misParticipaciones.length, themeColors)
              else
                _buildNoActiveRifaCard(themeColors),

              const SizedBox(height: 24),

              // ── Stats Summary Bar ──
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  final cards = [
                    StatCard(
                      label: 'Sorteo Activo',
                      value: activeRifa != null ? activeRifa.nombre : 'Ninguno en curso',
                      icon: Icons.confirmation_number_rounded,
                    ),
                    StatCard(
                      label: 'Tus Boletos Acumulados',
                      value: misParticipaciones.length.toString(),
                      icon: Icons.local_activity_rounded,
                    ),
                    StatCard(
                      label: 'Sorteos Realizados',
                      value: historial.length.toString(),
                      icon: Icons.history_rounded,
                    ),
                  ];

                  if (isWide) {
                    return Row(
                      children: cards
                          .map((c) => Expanded(
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: c)))
                          .toList(),
                    );
                  } else {
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: cards
                          .map((c) => SizedBox(
                              width: (constraints.maxWidth / 2) - 12, child: c))
                          .toList(),
                    );
                  }
                },
              ),

              const SizedBox(height: 28),

              // ── Tab Navigation ──
              Container(
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
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: themeColors.sidebarBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: themeColors.borderColor),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.25),
                                AppColors.accent.withValues(alpha: 0.25),
                              ],
                            ),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.6)),
                          ),
                          labelColor: AppColors.accent,
                          unselectedLabelColor: themeColors.textSecondary,
                          labelStyle: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          tabs: [
                            Tab(
                              icon: const Icon(Icons.confirmation_number_rounded, size: 18),
                              text: 'Mis Boletos (${misParticipaciones.length})',
                            ),
                            Tab(
                              icon: const Icon(Icons.emoji_events_rounded, size: 18),
                              text: 'Historial de Ganadores (${historial.length})',
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tab View with flexible height
                    SizedBox(
                      height: 580,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Mis Boletos
                          _buildMisBoletosTab(
                            filteredParticipaciones,
                            misParticipaciones,
                            provider.isLoadingMis,
                            themeColors,
                          ),
                          // Tab 2: Historial y Ganadores
                          _buildHistorialTab(
                            historial,
                            provider.isLoadingHistorial,
                            themeColors,
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
      ),
    );
  }

  Widget _buildActiveRifaHero(Rifa rifa, int totalBoletosUser, AppThemeColors themeColors) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E1B4B),
            Color(0xFF312E81),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.15),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background ambient highlights
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            left: 200,
            bottom: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(26),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 650;

                final heroArtwork = Container(
                  width: isCompact ? 90 : 120,
                  height: isCompact ? 90 : 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.card_giftcard_rounded,
                        color: Colors.white.withValues(alpha: 0.25),
                        size: isCompact ? 56 : 72,
                      ),
                      Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.amber.shade300,
                        size: isCompact ? 40 : 54,
                      ),
                    ],
                  ),
                );

                final heroDetails = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge & draw date
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.accent),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'SORTEO EN CURSO',
                                style: GoogleFonts.inter(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 12),
                              const SizedBox(width: 6),
                              Text(
                                'Sorteo: ${_formatDate(rifa.fechaSorteo)}',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      rifa.nombre,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: isCompact ? 22 : 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (rifa.descripcion != null && rifa.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        rifa.descripcion!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Prize Badge & Tickets Counter
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.withValues(alpha: 0.25),
                                Colors.amber.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Premio: ${rifa.premio}',
                                style: GoogleFonts.outfit(
                                  color: Colors.amber,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '$totalBoletosUser boletos en juego',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Consumer<RifaProvider>(
                          builder: (context, provider, _) {
                            final alreadyParticipated = provider.misParticipaciones.any((p) => p.rifaId == rifa.id);

                            if (alreadyParticipated) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Participando Activamente',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF10B981),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ElevatedButton.icon(
                              onPressed: provider.isLoadingAction
                                  ? null
                                  : () async {
                                      final success = await provider.participarEnRifa(rifa.id);
                                      if (context.mounted) {
                                        if (success) {
                                          CustomAlert.show(
                                            context,
                                            message: '¡Te has registrado en la rifa con éxito!',
                                            isSuccess: true,
                                          );
                                          provider.loadUserViewData();
                                        } else {
                                          final err = provider.errorMessage ?? 'No pudiste registrarte en la rifa';
                                          CustomAlert.show(context, message: err, isSuccess: false);
                                        }
                                      }
                                    },
                              icon: provider.isLoadingAction
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.stars_rounded, color: Colors.white, size: 18),
                              label: Text(
                                'Entrar al Sorteo',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                elevation: 4,
                                shadowColor: AppColors.accent.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      heroArtwork,
                      const SizedBox(height: 18),
                      heroDetails,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    heroArtwork,
                    const SizedBox(width: 24),
                    Expanded(child: heroDetails),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoActiveRifaCard(AppThemeColors themeColors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: themeColors.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: themeColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.accent.withValues(alpha: 0.15),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_empty_rounded,
              color: AppColors.accent,
              size: 36,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No hay ninguna rifa activa en este momento',
                  style: GoogleFonts.outfit(
                    color: themeColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '¡Sigue acumulando oportunidades! Con cada amigo que invites a Conexiate, sumarás boletos automáticos que entrarán en el próximo sorteo oficial.',
                  style: GoogleFonts.inter(
                    color: themeColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMisBoletosTab(
    List<ParticipacionRifa> filteredParticipaciones,
    List<ParticipacionRifa> allParticipaciones,
    bool isLoading,
    AppThemeColors themeColors,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalAfiliacion = allParticipaciones.where((p) => p.origen == 'afiliacion').length;
    final totalReferido = allParticipaciones.where((p) => p.origen == 'referido').length;
    final totalBeneficio = allParticipaciones.where((p) => p.origen == 'beneficio').length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Search & Filter Chips Header ──
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: themeColors.sidebarBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: themeColors.borderColor),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(color: themeColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar por número (#105) o tipo de origen...',
                      hintStyle: GoogleFonts.inter(
                        color: themeColors.textSecondary.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(Icons.search_rounded, color: themeColors.textSecondary, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Origin Filter Chips ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todos (${allParticipaciones.length})', 'all', themeColors),
                const SizedBox(width: 8),
                _buildFilterChip('Por Membresía ($totalAfiliacion)', 'afiliacion', themeColors),
                const SizedBox(width: 8),
                _buildFilterChip('Por Referidos ($totalReferido)', 'referido', themeColors),
                const SizedBox(width: 8),
                _buildFilterChip('Por Beneficios ($totalBeneficio)', 'beneficio', themeColors),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Tickets Grid ──
          Expanded(
            child: filteredParticipaciones.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: themeColors.sidebarBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: themeColors.borderColor),
                            ),
                            child: Icon(
                              Icons.confirmation_number_outlined,
                              color: themeColors.textSecondary.withValues(alpha: 0.4),
                              size: 44,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _selectedFilter != 'all'
                                ? 'No se encontraron boletos con los filtros aplicados'
                                : 'Aún no tienes boletos en el sorteo activo',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: themeColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '¡Invita amigos a suscribirse para obtener boletos adicionales de forma automática!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: themeColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Consumer<ReferidoProvider>(
                            builder: (context, refProv, _) {
                              final code = refProv.codeRefer;
                              if (code.isEmpty) return const SizedBox.shrink();

                              return OutlinedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: code));
                                  CustomAlert.show(
                                    context,
                                    message: '¡Código $code copiado al portapapeles!',
                                    isSuccess: true,
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: Text(
                                  'Copiar mi código: $code',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.accent,
                                  side: const BorderSide(color: AppColors.accent),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 360,
                      mainAxisExtent: 120,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: filteredParticipaciones.length,
                    itemBuilder: (context, index) {
                      final p = filteredParticipaciones[index];
                      return _buildGoldenTicketCard(p, themeColors);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String key, AppThemeColors themeColors) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = key);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : themeColors.sidebarBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : themeColors.borderColor,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : themeColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildGoldenTicketCard(ParticipacionRifa p, AppThemeColors themeColors) {
    final color = _getOrigenColor(p.origen);

    return Container(
      decoration: BoxDecoration(
        color: themeColors.sidebarBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            // Left Stub (Holographic ticket badge)
            Container(
              width: 76,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.9),
                    color.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.confirmation_number_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '№',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '#${p.numeroParticipacion}',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Perforated line divider
            CustomPaint(
              size: const Size(1, 120),
              painter: _PerforatedLinePainter(color: themeColors.borderColor),
            ),

            // Ticket details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Boleto #${p.numeroParticipacion}',
                            style: GoogleFonts.outfit(
                              color: themeColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildOrigenBadge(p.origen, p.origenLabel),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: themeColors.textSecondary.withValues(alpha: 0.6),
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(p.fechaParticipacion),
                          style: GoogleFonts.inter(
                            color: themeColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorialTab(
    List<RifaHistorialItem> historial,
    bool isLoading,
    AppThemeColors themeColors,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (historial.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: themeColors.sidebarBg,
                shape: BoxShape.circle,
                border: Border.all(color: themeColors.borderColor),
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                color: themeColors.textSecondary.withValues(alpha: 0.4),
                size: 44,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Aún no hay sorteos anteriores finalizados',
              style: GoogleFonts.outfit(
                color: themeColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cuando concluya el sorteo actual, aquí podrás consultar el ganador y registro del premio.',
              style: GoogleFonts.inter(
                color: themeColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: historial.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = historial[index];
        final rifa = item.rifa;
        final ganadores = item.ganadores;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeColors.sidebarBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: themeColors.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withValues(alpha: 0.2),
                          Colors.orange.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                rifa.nombre,
                                style: GoogleFonts.outfit(
                                  color: themeColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildEstadoBadge(rifa.estado, rifa.estadoLabel),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Premio: ${rifa.premio} • Realizado el ${_formatDate(rifa.fechaSorteo)}',
                          style: GoogleFonts.inter(
                            color: themeColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Ganadores List
              if (ganadores.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Sin ganadores registrados para este sorteo.',
                    style: GoogleFonts.inter(
                      color: themeColors.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ganadores del Sorteo:',
                      style: GoogleFonts.inter(
                        color: themeColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...ganadores.map((g) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: themeColors.cardBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: themeColors.borderColor),
                        ),
                        child: LayoutBuilder(
                          builder: (context, wConstraints) {
                            final isNarrow = wConstraints.maxWidth < 450;
                            final ticketBadge = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Boleto #${g.numeroParticipacion}',
                                style: GoogleFonts.outfit(
                                  color: AppColors.accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );

                            final entregaBadge = _buildEntregaBadge(g.estadoEntrega, g.estadoEntregaLabel);

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 20),
                                      const SizedBox(width: 8),
                                      ticketBadge,
                                      const Spacer(),
                                      entregaBadge,
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    g.nombreGanador,
                                    style: GoogleFonts.inter(
                                      color: themeColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 22),
                                const SizedBox(width: 12),
                                ticketBadge,
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    g.nombreGanador,
                                    style: GoogleFonts.inter(
                                      color: themeColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                entregaBadge,
                              ],
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Painter para la línea punteada estilo talonario de rifa
class _PerforatedLinePainter extends CustomPainter {
  final Color color;

  _PerforatedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
