import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_alert.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/widgets/header_filter.dart';
import '../../../core/widgets/stat_card.dart';
import '../models/referido_model.dart';
import '../providers/referido_provider.dart';

class ReferidoAdminScreen extends StatefulWidget {
  const ReferidoAdminScreen({super.key});

  @override
  State<ReferidoAdminScreen> createState() => _ReferidoAdminScreenState();
}

class _ReferidoAdminScreenState extends State<ReferidoAdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Column filters
  String _idFilter = '';
  String _referenteFilter = '';
  String _emailFilter = '';
  String _estadoFilter = '';
  String _recompensaFilter = '';

  // Pagination
  int _currentPage = 1;
  final int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    context.read<ReferidoProvider>().resetSilent();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReferidoProvider>().loadAllReferidos();
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

  Widget _buildEstadoBadge(Referido referido) {
    final color = _getEstadoColor(referido.estado);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
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
              referido.estadoLabel,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Referido referido) {
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppTheme.darkThemeColors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar referido',
          style: GoogleFonts.outfit(
            color: themeColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              color: themeColors.textSecondary,
              fontSize: 14,
            ),
            children: [
              const TextSpan(text: '¿Eliminar el registro de referido de '),
              TextSpan(
                text: referido.emailReferido,
                style: TextStyle(
                  color: themeColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: '?'),
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
              Navigator.pop(ctx);
              final provider = context.read<ReferidoProvider>();
              final success = await provider.deleteReferido(referido.id);
              if (mounted) {
                CustomAlert.show(
                  context,
                  message: success
                      ? 'Referido eliminado correctamente'
                      : provider.errorMessage ?? 'Error al eliminar',
                  isSuccess: success,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Eliminar',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAfiliar(Referido referido) async {
    final provider = context.read<ReferidoProvider>();
    final success = await provider.afiliarReferido(referido.id);
    if (mounted) {
      CustomAlert.show(
        context,
        message: success
            ? 'Referido afiliado correctamente'
            : provider.errorMessage ?? 'Error al afiliar',
        isSuccess: success,
      );
    }
  }

  Future<void> _handleRecompensa(Referido referido) async {
    final provider = context.read<ReferidoProvider>();
    final success = await provider.otorgarRecompensa(referido.id);
    if (mounted) {
      CustomAlert.show(
        context,
        message: success
            ? 'Recompensa otorgada correctamente'
            : provider.errorMessage ?? 'Error al otorgar recompensa',
        isSuccess: success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReferidoProvider>();
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppTheme.darkThemeColors;

    // Filter
    final filtered = provider.allReferidos.where((r) {
      // Global search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        final matchesGlobal =
            r.id.toString() == q ||
            r.emailReferido.toLowerCase().contains(q) ||
            r.nombreReferente.toLowerCase().contains(q) ||
            r.estadoLabel.toLowerCase().contains(q);
        if (!matchesGlobal) return false;
      }
      // Column filters
      if (_idFilter.isNotEmpty && !r.id.toString().contains(_idFilter)) {
        return false;
      }
      if (_referenteFilter.isNotEmpty &&
          !r.nombreReferente.toLowerCase().contains(
            _referenteFilter.toLowerCase(),
          )) {
        return false;
      }
      if (_emailFilter.isNotEmpty &&
          !r.emailReferido.toLowerCase().contains(_emailFilter.toLowerCase())) {
        return false;
      }
      if (_estadoFilter.isNotEmpty &&
          !r.estadoLabel.toLowerCase().contains(_estadoFilter.toLowerCase())) {
        return false;
      }
      if (_recompensaFilter.isNotEmpty) {
        final recompText = r.recompensaOtorgada ? 'sí' : 'no';
        if (!recompText.contains(_recompensaFilter.toLowerCase())) return false;
      }
      return true;
    }).toList();

    // Stats
    final total = provider.allReferidos.length;
    final pendientes = provider.allReferidos
        .where((r) => r.estado == 'pendiente')
        .length;
    final afiliados = provider.allReferidos
        .where((r) => r.estado == 'afiliado')
        .length;
    final recompensasPendientes = provider.allReferidos
        .where((r) => r.estado == 'afiliado' && !r.recompensaOtorgada)
        .length;

    // Pagination
    final totalItems = filtered.length;
    final totalPages = (totalItems / _rowsPerPage).ceil();
    final safeTotalPages = totalPages == 0 ? 1 : totalPages;
    if (_currentPage > safeTotalPages) _currentPage = safeTotalPages;
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, totalItems);
    final pageItems = totalItems > 0
        ? filtered.sublist(startIndex, endIndex)
        : <Referido>[];

    return DashboardShell(
      title: 'Gestión de Referidos',
      child: provider.isLoadingAll
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Breadcrumbs ──
                  Row(
                    children: [
                      Text(
                        'Admin',
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
                        'Referidos',
                        style: GoogleFonts.inter(
                          color: themeColors.textPrimary.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Header Row ──
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestión de Referidos',
                        style: GoogleFonts.outfit(
                          color: themeColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supervisa, afilia y otorga recompensas a todos los referidos registrados',
                        style: GoogleFonts.inter(
                          color: themeColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

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
                              child: const Icon(
                                Icons.share_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
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
                                    'Comparte tu código personal para invitar a nuevos usuarios',
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
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.tag_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      provider.codeRefer.isNotEmpty
                                          ? provider.codeRefer
                                          : '—',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 4,
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
                                  if (provider.codeRefer.isNotEmpty) {
                                    Clipboard.setData(
                                      ClipboardData(text: provider.codeRefer),
                                    );
                                    CustomAlert.show(
                                      context,
                                      message: 'Código copiado al portapapeles',
                                      isSuccess: true,
                                    );
                                  }
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
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.copy_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Copiar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Stats ──
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      final cards = [
                        StatCard(
                          label: 'Total Referidos',
                          value: total.toString(),
                          icon: Icons.people_alt_outlined,
                        ),
                        StatCard(
                          label: 'Pendientes',
                          value: pendientes.toString(),
                          icon: Icons.hourglass_empty_rounded,
                        ),
                        StatCard(
                          label: 'Afiliados',
                          value: afiliados.toString(),
                          icon: Icons.verified_rounded,
                        ),
                        StatCard(
                          label: 'Recompensas por otorgar',
                          value: recompensasPendientes.toString(),
                          icon: Icons.card_giftcard_rounded,
                        ),
                      ];

                      if (isWide) {
                        return Row(
                          children: cards
                              .map(
                                (c) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: c,
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      } else {
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: cards
                              .map(
                                (c) => SizedBox(
                                  width: constraints.maxWidth / 2 - 18,
                                  child: c,
                                ),
                              )
                              .toList(),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── Search bar ──
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: themeColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: themeColors.borderColor),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(
                        color: themeColors.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar por ID, email, referente o estado...',
                        hintStyle: GoogleFonts.inter(
                          color: themeColors.textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: themeColors.textSecondary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
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
                        // Table header with filters
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.tableHeaderBg,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: DefaultTextStyle.merge(
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            child: Row(
                            children: [
                              Expanded(
                                child: HeaderFilter(
                                  title: 'ID',
                                  onChanged: (v) =>
                                      setState(() => _idFilter = v),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: HeaderFilter(
                                  title: 'Referente',
                                  onChanged: (v) =>
                                      setState(() => _referenteFilter = v),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: HeaderFilter(
                                  title: 'Email Referido',
                                  onChanged: (v) =>
                                      setState(() => _emailFilter = v),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: HeaderFilter(
                                  title: 'Estado',
                                  onChanged: (v) =>
                                      setState(() => _estadoFilter = v),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: HeaderFilter(
                                  title: 'Recompensa',
                                  onChanged: (v) =>
                                      setState(() => _recompensaFilter = v),
                                ),
                              ),
                              const SizedBox(width: 110), // Actions column
                            ],
                          ),
                          ),
                        ),
                        // Table rows
                        if (pageItems.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                'No se encontraron referidos',
                                style: GoogleFonts.inter(
                                  color: themeColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ...pageItems.map((r) => _buildAdminRow(r, themeColors)),

                        // Pagination
                        if (totalItems > _rowsPerPage)
                          _buildPagination(safeTotalPages, themeColors),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminRow(Referido r, AppThemeColors themeColors) {
    return _AdminReferidoRow(
      referido: r,
      themeColors: themeColors,
      estadoBadge: _buildEstadoBadge(r),
      actionsWidget: SizedBox(
        width: 110,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (r.estado == 'registrado')
              _actionIcon(
                icon: Icons.verified_rounded,
                color: AppColors.accent,
                tooltip: 'Afiliar',
                onPressed: () => _handleAfiliar(r),
              ),
            if (r.estado == 'afiliado' && !r.recompensaOtorgada)
              _actionIcon(
                icon: Icons.card_giftcard_rounded,
                color: AppColors.warning,
                tooltip: 'Otorgar recompensa',
                onPressed: () => _handleRecompensa(r),
              ),
            _actionIcon(
              icon: Icons.delete_outline_rounded,
              color: AppColors.error,
              tooltip: 'Eliminar',
              onPressed: () => _showDeleteDialog(r),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(int totalPages, AppThemeColors themeColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${context.tr('page')} $_currentPage ${context.tr('of')} $totalPages',
            style: GoogleFonts.inter(
              color: themeColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              color: _currentPage > 1
                  ? themeColors.textPrimary
                  : themeColors.textSecondary,
            ),
            onPressed: _currentPage > 1
                ? () => setState(() => _currentPage--)
                  : null,
            iconSize: 20,
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: _currentPage < totalPages
                  ? themeColors.textPrimary
                  : themeColors.textSecondary,
            ),
            onPressed: _currentPage < totalPages
                ? () => setState(() => _currentPage++)
                : null,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

// ── Custom admin row item with premium hover states ──
class _AdminReferidoRow extends StatefulWidget {
  final Referido referido;
  final AppThemeColors themeColors;
  final Widget estadoBadge;
  final Widget actionsWidget;

  const _AdminReferidoRow({
    required this.referido,
    required this.themeColors,
    required this.estadoBadge,
    required this.actionsWidget,
  });

  @override
  State<_AdminReferidoRow> createState() => _AdminReferidoRowState();
}

class _AdminReferidoRowState extends State<_AdminReferidoRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.referido;
    final themeColors = widget.themeColors;

    // Premium initials-based avatar
    final initials = (r.nombreReferente.isNotEmpty ? r.nombreReferente[0] : (r.emailReferido.isNotEmpty ? r.emailReferido[0] : '?')).toUpperCase();
    final List<Color> avatarColors = [
      AppColors.primary,
      AppColors.accent,
    ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isHovered 
              ? themeColors.cardBackground.withRed(30).withGreen(30).withBlue(50).withValues(alpha: 0.4)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: _isHovered 
                  ? AppColors.primary.withValues(alpha: 0.4) 
                  : themeColors.borderColor,
              width: _isHovered ? 1.2 : 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '#${r.id}',
                style: GoogleFonts.inter(
                  color: themeColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: avatarColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.nombreReferente,
                      style: GoogleFonts.inter(
                        color: themeColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    r.emailReferido,
                    style: GoogleFonts.inter(
                      color: themeColors.textPrimary,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (r.nombreReferido != null && r.nombreReferido!.isNotEmpty)
                    Text(
                      r.nombreReferido!,
                      style: GoogleFonts.inter(
                        color: themeColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(flex: 2, child: widget.estadoBadge),
            Expanded(
              flex: 2,
              child: r.recompensaOtorgada
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.warning,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Sí',
                          style: GoogleFonts.inter(
                            color: AppColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'No',
                      style: GoogleFonts.inter(
                        color: themeColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
            ),
            widget.actionsWidget,
          ],
        ),
      ),
    );
  }
}
