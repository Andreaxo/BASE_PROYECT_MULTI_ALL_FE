import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_alert.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/widgets/membership_gate_banner.dart';
import '../../../core/widgets/stat_card.dart';
import '../models/rifa_model.dart';
import '../providers/rifa_provider.dart';

class RifaUserScreen extends StatefulWidget {
  const RifaUserScreen({super.key});

  @override
  State<RifaUserScreen> createState() => _RifaUserScreenState();
}

class _RifaUserScreenState extends State<RifaUserScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<RifaProvider>().resetSilent();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RifaProvider>().loadUserViewData();
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
        return const Color(0xFF3B82F6); // Blue
      case 'referido':
        return const Color(0xFF10B981); // Emerald
      case 'beneficio':
        return const Color(0xFFF59E0B); // Amber
      case 'manual':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrigenBadge(String origen, String label) {
    final color = _getOrigenColor(origen);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, color: color, size: 12),
          const SizedBox(width: 4),
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
            width: 6,
            height: 6,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
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

    final filteredParticipaciones = misParticipaciones.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.numeroParticipacion.toLowerCase().contains(_searchQuery) ||
          p.origenLabel.toLowerCase().contains(_searchQuery);
    }).toList();

    return DashboardShell(
      title: 'Rifas y Sorteos',
      child: RefreshIndicator(
        onRefresh: () => provider.loadUserViewData(),
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
                    'Rifas',
                    style: GoogleFonts.inter(
                      color: themeColors.textPrimary.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Header Title ──
              Text(
                'Rifas y Sorteos Exclusivos',
                style: GoogleFonts.outfit(
                  color: themeColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Participa automáticamente acumulando boletos mediante tus referidos y beneficios',
                style: GoogleFonts.inter(
                  color: themeColors.textSecondary,
                  fontSize: 14,
                ),
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const CircularProgressIndicator(),
                )
              else if (activeRifa != null)
                _buildActiveRifaHero(activeRifa, misParticipaciones.length, themeColors)
              else
                _buildNoActiveRifaCard(themeColors),

              const SizedBox(height: 28),

              // ── Stats Summary Bar ──
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  final cards = [
                    StatCard(
                      label: 'Rifa Activa',
                      value: activeRifa != null ? activeRifa.nombre : 'Ninguna',
                      icon: Icons.confirmation_number_rounded,
                    ),
                    StatCard(
                      label: 'Tus Boletos',
                      value: misParticipaciones.length.toString(),
                      icon: Icons.local_activity_rounded,
                    ),
                    StatCard(
                      label: 'Rifas Pasadas',
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
                              width: constraints.maxWidth / 2 - 18, child: c))
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: themeColors.borderColor),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: themeColors.sidebarBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: themeColors.borderColor),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          dividerColor: Colors.transparent,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.primary.withValues(alpha: 0.2),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                          ),
                          labelColor: AppColors.primary,
                          unselectedLabelColor: themeColors.textSecondary,
                          labelStyle: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          tabs: const [
                            Tab(
                              icon: Icon(Icons.confirmation_number_rounded, size: 18),
                              text: 'Mis Boletos',
                            ),
                            Tab(
                              icon: Icon(Icons.emoji_events_rounded, size: 18),
                              text: 'Historial y Ganadores',
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(
                      height: 480,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Mis Boletos
                          _buildMisBoletosTab(
                            filteredParticipaciones,
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
    final hasImage = rifa.imagenUrl != null && rifa.imagenUrl!.isNotEmpty;
    final imageUrl = hasImage ? '${ApiConfig.serverUrl}${rifa.imagenUrl}' : '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E1B4B),
            Color(0xFF312E81),
            Color(0xFF4338CA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative glow
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rifa Image / Trophy Icon
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      imageUrl,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultHeroImage(),
                    ),
                  )
                else
                  _buildDefaultHeroImage(),

                const SizedBox(width: 24),

                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.accent),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.stars_rounded, color: AppColors.accent, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  'RIFA EN CURSO',
                                  style: GoogleFonts.inter(
                                    color: AppColors.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Sorteo: ${_formatDate(rifa.fechaSorteo)}',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        rifa.nombre,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 26,
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
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Premio: ${rifa.premio}',
                                  style: GoogleFonts.inter(
                                    color: Colors.amber,
                                    fontSize: 13,
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
                                const Icon(Icons.local_activity_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Tienes $totalBoletosUser boleto(s)',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Consumer<RifaProvider>(
                            builder: (context, provider, _) {
                              final alreadyParticipated = provider.misParticipaciones.any((p) => p.rifaId == rifa.id);

                              if (alreadyParticipated) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        '✓ Ya estás participando',
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
                                    : const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 18),
                                label: Text(
                                  'Participar',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultHeroImage() {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(
        Icons.card_giftcard_rounded,
        color: Colors.white,
        size: 56,
      ),
    );
  }

  Widget _buildNoActiveRifaCard(AppThemeColors themeColors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: themeColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.confirmation_number_outlined,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No hay ninguna rifa activa actualmente',
                  style: GoogleFonts.outfit(
                    color: themeColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '¡Permanece atento! Cuando se active una nueva rifa, recibirás automáticamente tus participaciones acumuladas por referidos y afiliaciones.',
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
    List<ParticipacionRifa> participaciones,
    bool isLoading,
    AppThemeColors themeColors,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Search & Filter header
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: themeColors.sidebarBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: themeColors.borderColor),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(color: themeColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar por número o por origen (referido, afiliación...)...',
                      hintStyle: GoogleFonts.inter(color: themeColors.textSecondary, fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded, color: themeColors.textSecondary, size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tickets List / Grid
          Expanded(
            child: participaciones.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.confirmation_number_outlined,
                            color: themeColors.textSecondary.withValues(alpha: 0.4), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No se encontraron boletos que coincidan con "$_searchQuery"'
                              : 'Aún no tienes boletos en la rifa activa.\n¡Invita a tus amigos para ganar boletos!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: themeColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 320,
                      mainAxisExtent: 110,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: participaciones.length,
                    itemBuilder: (context, index) {
                      final p = participaciones[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: themeColors.sidebarBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: themeColors.borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Ticket visual tag
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.accent],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.confirmation_number_rounded,
                                      color: Colors.white, size: 20),
                                  const SizedBox(height: 2),
                                  Text(
                                    '#${p.numeroParticipacion}',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Boleto #${p.numeroParticipacion}',
                                    style: GoogleFonts.outfit(
                                      color: themeColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildOrigenBadge(p.origen, p.origenLabel),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(p.fechaParticipacion),
                                    style: GoogleFonts.inter(
                                      color: themeColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
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
            Icon(Icons.emoji_events_outlined,
                color: themeColors.textSecondary.withValues(alpha: 0.4), size: 48),
            const SizedBox(height: 12),
            Text(
              'No hay historial de rifas anteriores todavía.',
              style: GoogleFonts.inter(
                color: themeColors.textSecondary,
                fontSize: 14,
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: themeColors.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              rifa.nombre,
                              style: GoogleFonts.outfit(
                                color: themeColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _buildEstadoBadge(rifa.estado, rifa.estadoLabel),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Premio: ${rifa.premio} • Sorteado el ${_formatDate(rifa.fechaSorteo)}',
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
              const SizedBox(height: 14),

              // Ganadores List
              if (ganadores.isEmpty)
                Text(
                  'Sin ganadores registrados.',
                  style: GoogleFonts.inter(
                    color: themeColors.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ganadores:',
                      style: GoogleFonts.inter(
                        color: themeColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...ganadores.map((g) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: themeColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: themeColors.borderColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.emoji_events_rounded,
                                color: Colors.amber, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Boleto #${g.numeroParticipacion}',
                              style: GoogleFonts.outfit(
                                color: AppColors.accent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                g.nombreGanador,
                                style: GoogleFonts.inter(
                                  color: themeColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _buildEntregaBadge(g.estadoEntrega, g.estadoEntregaLabel),
                          ],
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
