import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_alert.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/widgets/header_filter.dart';
import '../../../core/widgets/stat_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../users/providers/user_provider.dart';
import '../models/rifa_model.dart';
import '../providers/rifa_provider.dart';
import '../services/rifa_service.dart';
import '../../../core/widgets/custom_pagination_footer.dart';

class RifaAdminScreen extends StatefulWidget {
  const RifaAdminScreen({super.key});

  @override
  State<RifaAdminScreen> createState() => _RifaAdminScreenState();
}

class _RifaAdminScreenState extends State<RifaAdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Column filters
  String _idFilter = '';
  String _nombreFilter = '';
  String _premioFilter = '';
  String _estadoFilter = '';

  // Pagination
  int _currentPage = 1;
  int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RifaProvider>().loadAllRifas();
      context.read<UserProvider>().loadUsers();
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

  Widget _buildEstadoBadge(Rifa rifa) {
    final color = _getEstadoColor(rifa.estado);
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
              rifa.estadoLabel,
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

  void _showCreateOrEditDialog([Rifa? existingRifa]) {
    final isEdit = existingRifa != null;
    final nombreCtrl = TextEditingController(text: existingRifa?.nombre ?? '');
    final descCtrl = TextEditingController(text: existingRifa?.descripcion ?? '');
    final premioCtrl = TextEditingController(text: existingRifa?.premio ?? '');
    bool esPremioMayor = existingRifa?.esPremioMayor ?? false;

    DateTime fechaInicio = existingRifa?.fechaInicio ?? DateTime.now();
    DateTime fechaFin = existingRifa?.fechaFin ?? DateTime.now().add(const Duration(days: 30));
    DateTime fechaSorteo = existingRifa?.fechaSorteo ?? DateTime.now().add(const Duration(days: 31));

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        final themeColors = Theme.of(ctx).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> selectDate(BuildContext context, DateTime initial, Function(DateTime) onSelected) async {
              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setDialogState(() {
                  onSelected(picked);
                });
              }
            }

            return AlertDialog(
              backgroundColor: themeColors.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Text(
                isEdit ? 'Editar Rifa' : 'Nueva Rifa',
                style: GoogleFonts.outfit(
                  color: themeColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nombreCtrl,
                          style: GoogleFonts.inter(color: themeColors.textPrimary),
                          decoration: _inputDecoration('Nombre de la Rifa *', Icons.card_giftcard_rounded, themeColors),
                          validator: (v) => v == null || v.trim().isEmpty ? 'El nombre es obligatorio' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: premioCtrl,
                          style: GoogleFonts.inter(color: themeColors.textPrimary),
                          decoration: _inputDecoration('Premio *', Icons.emoji_events_rounded, themeColors),
                          validator: (v) => v == null || v.trim().isEmpty ? 'El premio es obligatorio' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: descCtrl,
                          maxLines: 2,
                          style: GoogleFonts.inter(color: themeColors.textPrimary),
                          decoration: _inputDecoration('Descripción (opcional)', Icons.description_rounded, themeColors),
                        ),
                        const SizedBox(height: 14),
                        // Premio Mayor Toggle Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: esPremioMayor ? Colors.amber.withValues(alpha: 0.12) : themeColors.sidebarBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: esPremioMayor ? Colors.amber.withValues(alpha: 0.5) : themeColors.borderColor,
                            ),
                          ),
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              children: [
                                Icon(
                                  Icons.workspace_premium_rounded,
                                  size: 20,
                                  color: esPremioMayor ? Colors.amber : themeColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '¿Es Premio Mayor?',
                                  style: GoogleFonts.outfit(
                                    color: themeColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                esPremioMayor
                                    ? 'En Premio Mayor, los participantes con más referidos en el periodo acumulan mayor probabilidad de ganar.'
                                    : 'Sorteo Estándar: Todos los participantes juegan con probabilidades iguales.',
                                style: GoogleFonts.inter(
                                  color: themeColors.textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                            value: esPremioMayor,
                            activeThumbColor: Colors.amber,
                            onChanged: (val) {
                              setDialogState(() {
                                esPremioMayor = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Dates
                        Row(
                          children: [
                            Expanded(
                              child: _datePickerTile(
                                label: 'Fecha Inicio',
                                date: fechaInicio,
                                onTap: () => selectDate(context, fechaInicio, (d) => fechaInicio = d),
                                themeColors: themeColors,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _datePickerTile(
                                label: 'Fecha Fin',
                                date: fechaFin,
                                onTap: () => selectDate(context, fechaFin, (d) => fechaFin = d),
                                themeColors: themeColors,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _datePickerTile(
                          label: 'Fecha del Sorteo',
                          date: fechaSorteo,
                          onTap: () => selectDate(context, fechaSorteo, (d) => fechaSorteo = d),
                          themeColors: themeColors,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancelar', style: GoogleFonts.inter(color: themeColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (fechaFin.isBefore(fechaInicio)) {
                      CustomAlert.show(context, message: 'La fecha de fin debe ser posterior a la de inicio', isSuccess: false);
                      return;
                    }
                    if (fechaSorteo.isBefore(fechaFin)) {
                      CustomAlert.show(context, message: 'La fecha de sorteo debe ser posterior a la fecha de fin', isSuccess: false);
                      return;
                    }

                    Navigator.pop(ctx);
                    final provider = context.read<RifaProvider>();

                    final fInicioStr = _formatDateIso(fechaInicio);
                    final fFinStr = _formatDateIso(fechaFin);
                    final fSorteoStr = _formatDateIso(fechaSorteo);

                    if (isEdit) {
                      final updated = await provider.updateRifa(
                        existingRifa.id,
                        UpdateRifaRequest(
                          nombre: nombreCtrl.text.trim(),
                          descripcion: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          premio: premioCtrl.text.trim(),
                          fechaInicio: fInicioStr,
                          fechaFin: fFinStr,
                          fechaSorteo: fSorteoStr,
                          esPremioMayor: esPremioMayor,
                        ),
                      );
                      if (mounted) {
                        CustomAlert.show(
                          context,
                          message: updated != null ? 'Rifa actualizada correctamente' : provider.errorMessage ?? 'Error al actualizar',
                          isSuccess: updated != null,
                        );
                      }
                    } else {
                      final created = await provider.createRifa(
                        CreateRifaRequest(
                          nombre: nombreCtrl.text.trim(),
                          descripcion: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                          premio: premioCtrl.text.trim(),
                          fechaInicio: fInicioStr,
                          fechaFin: fFinStr,
                          fechaSorteo: fSorteoStr,
                          esPremioMayor: esPremioMayor,
                        ),
                      );
                      if (mounted) {
                        CustomAlert.show(
                          context,
                          message: created != null ? 'Rifa creada correctamente' : provider.errorMessage ?? 'Error al crear',
                          isSuccess: created != null,
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(isEdit ? 'Guardar Cambios' : 'Crear Rifa', style: GoogleFonts.inter(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showActivarDialog(Rifa rifa) {
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Activar Rifa', style: GoogleFonts.outfit(color: themeColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas activar la rifa "${rifa.nombre}"?',
              style: GoogleFonts.inter(color: themeColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Al activar esta rifa, el sistema otorgará automáticamente las participaciones pendientes a los usuarios referentes.',
                      style: GoogleFonts.inter(color: themeColors.textPrimary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.inter(color: themeColors.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<RifaProvider>();
              final success = await provider.activarRifa(rifa.id);
              if (mounted) {
                CustomAlert.show(
                  context,
                  message: success ? 'Rifa activada correctamente' : provider.errorMessage ?? 'Error al activar rifa',
                  isSuccess: success,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: Text('Activar', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCerrarDialog(Rifa rifa) {
    _confirmActionDialog(
      title: 'Cerrar Rifa',
      message: '¿Estás seguro de cerrar la rifa "${rifa.nombre}"? No se aceptarán más participaciones.',
      buttonText: 'Cerrar Rifa',
      buttonColor: AppColors.warning,
      onConfirm: () async {
        final provider = context.read<RifaProvider>();
        final success = await provider.cerrarRifa(rifa.id);
        if (mounted) {
          CustomAlert.show(
            context,
            message: success ? 'Rifa cerrada' : provider.errorMessage ?? 'Error al cerrar',
            isSuccess: success,
          );
        }
      },
    );
  }

  void _showSortearDialog(Rifa rifa) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RouletteDrawDialog(rifa: rifa),
    );
  }

  void _showCancelarDialog(Rifa rifa) {
    _confirmActionDialog(
      title: 'Cancelar Rifa',
      message: '¿Estás seguro de cancelar la rifa "${rifa.nombre}"?',
      buttonText: 'Cancelar Rifa',
      buttonColor: AppColors.error,
      onConfirm: () async {
        final provider = context.read<RifaProvider>();
        final success = await provider.cancelarRifa(rifa.id);
        if (mounted) {
          CustomAlert.show(
            context,
            message: success ? 'Rifa cancelada' : provider.errorMessage ?? 'Error al cancelar',
            isSuccess: success,
          );
        }
      },
    );
  }

  void _confirmActionDialog({
    required String title,
    required String message,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onConfirm,
  }) {
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: GoogleFonts.outfit(color: themeColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.inter(color: themeColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.inter(color: themeColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
            child: Text(buttonText, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- Participaciones Modal & Manual Ticket Dialog ---

  void _showParticipacionesModal(Rifa rifa) {
    context.read<RifaProvider>().loadParticipaciones(rifa.id);
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: themeColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 580,
            height: 560,
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                final provider = context.watch<RifaProvider>();
                final participaciones = provider.selectedRifaParticipaciones;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.confirmation_number_rounded, color: AppColors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Participaciones — ${rifa.nombre}',
                                style: GoogleFonts.outfit(color: themeColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Total: ${participaciones.length} boletos registrados',
                                style: GoogleFonts.inter(color: themeColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close_rounded, color: themeColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Button Add Manual Ticket
                    if (rifa.isActiva)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showAgregarBoletoManualDialog(rifa.id);
                          },
                          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                          label: Text('Otorgar Boleto Manual', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // List
                    Expanded(
                      child: provider.isLoadingParticipaciones
                          ? const Center(child: CircularProgressIndicator())
                          : participaciones.isEmpty
                              ? Center(
                                  child: Text('No hay participaciones aún para esta rifa.', style: GoogleFonts.inter(color: themeColors.textSecondary)),
                                )
                              : ListView.separated(
                                  itemCount: participaciones.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final p = participaciones[index];
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: themeColors.sidebarBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: themeColors.borderColor),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.accent.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '#${p.numeroParticipacion}',
                                              style: GoogleFonts.outfit(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  p.nombreUsuario.isNotEmpty ? p.nombreUsuario : 'Usuario #${p.usuarioId}',
                                                  style: GoogleFonts.inter(color: themeColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                                                ),
                                                Text(
                                                  'Origen: ${p.origenLabel} • ${_formatDate(p.fechaParticipacion)}',
                                                  style: GoogleFonts.inter(color: themeColors.textSecondary, fontSize: 11),
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
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showAgregarBoletoManualDialog(int rifaId) {
    final userProvider = context.read<UserProvider>();
    final users = userProvider.users;
    int? selectedUserId = users.isNotEmpty ? users.first.id : null;
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: themeColors.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Otorgar Boleto Manual', style: GoogleFonts.outfit(color: themeColors.textPrimary, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selecciona el usuario que recibirá el boleto:', style: GoogleFonts.inter(color: themeColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 12),
                  if (users.isEmpty)
                    Text('Cargando usuarios...', style: GoogleFonts.inter(color: themeColors.textSecondary)
                    )
                  else
                    DropdownButtonFormField<int>(
                      value: selectedUserId,
                      dropdownColor: themeColors.cardBackground,
                      decoration: _inputDecoration('Usuario', Icons.person_rounded, themeColors),
                      items: users.map((u) {
                        final name = '${u.firstName} ${u.lastName}'.trim();
                        return DropdownMenuItem<int>(
                          value: u.id,
                          child: Text(
                            name.isNotEmpty ? '$name (${u.email})' : u.email,
                            style: GoogleFonts.inter(color: themeColors.textPrimary, fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedUserId = val),
                    ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.inter(color: themeColors.textSecondary))),
                ElevatedButton(
                  onPressed: selectedUserId == null
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          final provider = context.read<RifaProvider>();
                          final success = await provider.agregarParticipacionManual(rifaId, selectedUserId!);
                          if (mounted) {
                            CustomAlert.show(
                              context,
                              message: success ? 'Boleto manual otorgado' : provider.errorMessage ?? 'Error al otorgar boleto',
                              isSuccess: success,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text('Otorgar', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Ganadores Modal & Register Winner Dialog ---

  void _showGanadoresModal(Rifa rifa) {
    context.read<RifaProvider>().loadGanadores(rifa.id);
    context.read<RifaProvider>().loadParticipaciones(rifa.id);
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: themeColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 580,
            height: 560,
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                final provider = context.watch<RifaProvider>();
                final ganadores = provider.selectedRifaGanadores;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.emoji_events_rounded, color: Colors.amber),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ganadores — ${rifa.nombre}',
                                style: GoogleFonts.outfit(color: themeColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Premio: ${rifa.premio}',
                                style: GoogleFonts.inter(color: themeColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close_rounded, color: themeColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const SizedBox(height: 8),

                    // Winners List
                    Expanded(
                      child: provider.isLoadingGanadores
                          ? const Center(child: CircularProgressIndicator())
                          : ganadores.isEmpty
                              ? Center(
                                  child: Text(
                                    'No hay ganador aún. Presiona el botón "Sortear Rifa" 🎲 para realizar el sorteo automático.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(color: themeColors.textSecondary, fontSize: 13),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: ganadores.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final g = ganadores[index];
                                    return Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: themeColors.sidebarBg,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: themeColors.borderColor),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Ganador: ${g.nombreGanador}',
                                                  style: GoogleFonts.inter(color: themeColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                                ),
                                                Text(
                                                  'Boleto #${g.numeroParticipacion}',
                                                  style: GoogleFonts.inter(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Delivery Status Dropdown
                                          DropdownButton<String>(
                                            value: g.estadoEntrega,
                                            dropdownColor: themeColors.cardBackground,
                                            style: GoogleFonts.inter(color: themeColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                                            items: const [
                                              DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                                              DropdownMenuItem(value: 'notificado', child: Text('Notificado')),
                                              DropdownMenuItem(value: 'entregado', child: Text('Entregado')),
                                            ],
                                            onChanged: (val) async {
                                              if (val != null && val != g.estadoEntrega) {
                                                final success = await provider.actualizarEntrega(g.id, val, rifaId: rifa.id);
                                                if (mounted) {
                                                  CustomAlert.show(
                                                    context,
                                                    message: success ? 'Estado de entrega actualizado' : provider.errorMessage ?? 'Error al actualizar',
                                                    isSuccess: success,
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RifaProvider>();
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;

    // Filter logic
    final filtered = provider.allRifas.where((r) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        final matchesGlobal = r.id.toString() == q ||
            r.nombre.toLowerCase().contains(q) ||
            r.premio.toLowerCase().contains(q) ||
            r.estadoLabel.toLowerCase().contains(q);
        if (!matchesGlobal) return false;
      }
      if (_idFilter.isNotEmpty && !r.id.toString().contains(_idFilter)) return false;
      if (_nombreFilter.isNotEmpty && !r.nombre.toLowerCase().contains(_nombreFilter.toLowerCase())) return false;
      if (_premioFilter.isNotEmpty && !r.premio.toLowerCase().contains(_premioFilter.toLowerCase())) return false;
      if (_estadoFilter.isNotEmpty && !r.estadoLabel.toLowerCase().contains(_estadoFilter.toLowerCase())) return false;
      return true;
    }).toList();

    // Stats
    final totalRifas = provider.allRifas.length;
    final rifasActivas = provider.allRifas.where((r) => r.isActiva).length;
    final rifasCerradas = provider.allRifas.where((r) => r.isCerrada).length;
    final rifasSorteadas = provider.allRifas.where((r) => r.isSorteada).length;

    // Pagination
    final totalItems = filtered.length;
    final totalPages = (totalItems / _rowsPerPage).ceil();
    final safeTotalPages = totalPages == 0 ? 1 : totalPages;
    if (_currentPage > safeTotalPages) _currentPage = safeTotalPages;
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, totalItems);
    final pageItems = totalItems > 0 ? filtered.sublist(startIndex, endIndex) : <Rifa>[];

    final authProvider = context.watch<AuthProvider>();
    final canCreateRifa = authProvider.roleCode != 'operador';

    return DashboardShell(
      title: 'Gestión de Rifas',
      child: provider.isLoadingAll
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumbs
                  Row(
                    children: [
                      Text('Admin', style: GoogleFonts.inter(color: themeColors.textSecondary.withValues(alpha: 0.5), fontSize: 13)),
                      Icon(Icons.chevron_right_rounded, color: themeColors.textSecondary.withValues(alpha: 0.5), size: 14),
                      Text('Rifas', style: GoogleFonts.inter(color: themeColors.textPrimary.withValues(alpha: 0.8), fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Header Row
                  LayoutBuilder(
                    builder: (context, headerConstraints) {
                      final isMobileHeader = headerConstraints.maxWidth < 650;
                      if (isMobileHeader) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Gestión de Rifas',
                              style: GoogleFonts.outfit(
                                color: themeColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Crea, activa y gestiona sorteos, participaciones y ganadores',
                              style: GoogleFonts.inter(
                                color: themeColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            if (canCreateRifa) ...[
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showCreateOrEditDialog(),
                                  icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                                  label: Text('Nueva Rifa', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Gestión de Rifas', style: GoogleFonts.outfit(color: themeColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Crea, activa y gestiona sorteos, participaciones y ganadores', style: GoogleFonts.inter(color: themeColors.textSecondary, fontSize: 14)),
                              ],
                            ),
                          ),
                          if (canCreateRifa)
                            ElevatedButton.icon(
                              onPressed: () => _showCreateOrEditDialog(),
                              icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                              label: Text('Nueva Rifa', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Stats
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      final cards = [
                        StatCard(label: 'Total Rifas', value: totalRifas.toString(), icon: Icons.confirmation_number_outlined),
                        StatCard(label: 'Activas', value: rifasActivas.toString(), icon: Icons.stars_rounded),
                        StatCard(label: 'Cerradas', value: rifasCerradas.toString(), icon: Icons.lock_clock_rounded),
                        StatCard(label: 'Sorteadas', value: rifasSorteadas.toString(), icon: Icons.emoji_events_rounded),
                      ];

                      if (isWide) {
                        return Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList());
                      } else {
                        return Wrap(spacing: 12, runSpacing: 12, children: cards.map((c) => SizedBox(width: constraints.maxWidth / 2 - 18, child: c)).toList());
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Search Bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: themeColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: themeColors.borderColor),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(color: themeColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Buscar por ID, nombre, premio o estado...',
                        hintStyle: GoogleFonts.inter(color: themeColors.textSecondary, fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: themeColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Table
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final minTableWidth = 850.0;
                      final tableWidth = constraints.maxWidth > minTableWidth
                          ? constraints.maxWidth
                          : minTableWidth;

                      return Container(
                        decoration: BoxDecoration(
                          color: themeColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: themeColors.borderColor),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: tableWidth,
                                child: Column(
                                  children: [
                                    // Header
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: themeColors.tableHeaderBg,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(flex: 1, child: HeaderFilter(title: 'ID', onChanged: (v) => setState(() => _idFilter = v))),
                                          Expanded(flex: 3, child: HeaderFilter(title: 'Nombre', onChanged: (v) => setState(() => _nombreFilter = v))),
                                          Expanded(flex: 3, child: HeaderFilter(title: 'Premio', onChanged: (v) => setState(() => _premioFilter = v))),
                                          Expanded(flex: 2, child: HeaderFilter(title: 'Estado', onChanged: (v) => setState(() => _estadoFilter = v))),
                                          const SizedBox(width: 250), // Actions column
                                        ],
                                      ),
                                    ),

                                    // Rows
                                    if (pageItems.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(40),
                                        child: Center(
                                          child: Text('No se encontraron rifas', style: GoogleFonts.inter(color: themeColors.textSecondary, fontSize: 14)),
                                        ),
                                      ),
                                    ...pageItems.map((r) => _buildRow(r, themeColors)),
                                  ],
                                ),
                              ),
                            ),

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
                      );
                    },
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

  Widget _buildRow(Rifa r, AppThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: themeColors.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('#${r.id}', style: GoogleFonts.inter(color: themeColors.textSecondary, fontSize: 13))),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        r.nombre,
                        style: GoogleFonts.inter(
                          color: themeColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (r.esPremioMayor) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PREMIO MAYOR',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text('Sorteo: ${_formatDate(r.fechaSorteo)}', style: GoogleFonts.inter(color: themeColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text(r.premio, style: GoogleFonts.inter(color: themeColors.textPrimary, fontSize: 13), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: _buildEstadoBadge(r)),
          // Actions
          SizedBox(
            width: 250,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _actionIcon(
                  icon: Icons.edit_outlined,
                  color: Colors.blue,
                  tooltip: 'Editar',
                  onPressed: () => _showCreateOrEditDialog(r),
                ),
                if (!r.isActiva && !r.isSorteada && !r.isCancelada)
                  _actionIcon(
                    icon: Icons.play_arrow_rounded,
                    color: AppColors.accent,
                    tooltip: 'Activar',
                    onPressed: () => _showActivarDialog(r),
                  ),
                if (r.isActiva)
                  _actionIcon(
                    icon: Icons.pause_rounded,
                    color: AppColors.warning,
                    tooltip: 'Cerrar',
                    onPressed: () => _showCerrarDialog(r),
                  ),
                if (r.isActiva || r.isCerrada)
                  _actionIcon(
                    icon: Icons.casino_rounded,
                    color: const Color(0xFF8B5CF6),
                    tooltip: 'Sortear Rifa',
                    onPressed: () => _showSortearDialog(r),
                  ),
                if (!r.isCancelada && !r.isSorteada)
                  _actionIcon(
                    icon: Icons.block_rounded,
                    color: AppColors.error,
                    tooltip: 'Cancelar',
                    onPressed: () => _showCancelarDialog(r),
                  ),
                _actionIcon(
                  icon: Icons.confirmation_number_outlined,
                  color: AppColors.primary,
                  tooltip: 'Ver Participaciones',
                  onPressed: () => _showParticipacionesModal(r),
                ),
                _actionIcon(
                  icon: Icons.emoji_events_outlined,
                  color: Colors.amber[700]!,
                  tooltip: 'Ver / Registrar Ganadores',
                  onPressed: () => _showGanadoresModal(r),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  InputDecoration _inputDecoration(String label, IconData icon, AppThemeColors themeColors) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: themeColors.textSecondary),
      prefixIcon: Icon(icon, color: themeColors.textSecondary),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: themeColors.borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
    );
  }

  Widget _datePickerTile({required String label, required DateTime date, required VoidCallback onTap, required AppThemeColors themeColors}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: themeColors.borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 16, color: themeColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(color: themeColors.textSecondary, fontSize: 10)),
                  Text(_formatDate(date), style: GoogleFonts.inter(color: themeColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateIso(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Roulette Draw Modal & Confetti
// ─────────────────────────────────────────────────────────────────────────────

class _RouletteDrawDialog extends StatefulWidget {
  final Rifa rifa;

  const _RouletteDrawDialog({required this.rifa});

  @override
  State<_RouletteDrawDialog> createState() => _RouletteDrawDialogState();
}

class _RouletteDrawDialogState extends State<_RouletteDrawDialog>
    with SingleTickerProviderStateMixin {
  bool _isLoadingParticipaciones = true;
  bool _isSpinning = false;
  bool _hasDrawn = false;
  String? _errorMessage;

  List<ParticipacionRifa> _participantes = [];
  ParticipacionRifa? _currentTicket;
  GanadorRifa? _winnerResult;

  Timer? _spinTimer;
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _loadParticipaciones();
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadParticipaciones() async {
    try {
      final list = await RifaApiService.getParticipaciones(widget.rifa.id);
      if (mounted) {
        setState(() {
          _participantes = list;
          _isLoadingParticipaciones = false;
          if (list.isNotEmpty) {
            _currentTicket = list.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingParticipaciones = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _startRoulette() {
    if (_participantes.isEmpty || _isSpinning) return;

    setState(() {
      _isSpinning = true;
      _hasDrawn = false;
      _errorMessage = null;
      _winnerResult = null;
    });

    final random = math.Random();
    int elapsedMs = 0;
    const int totalDurationMs = 3800;
    int currentDelayMs = 40;

    // Trigger backend draw in background
    GanadorRifa? backendWinner;
    bool backendFinished = false;
    String? backendError;

    RifaApiService.sortear(widget.rifa.id).then((_) async {
      final winners = await RifaApiService.getGanadores(widget.rifa.id);
      if (winners.isNotEmpty) {
        backendWinner = winners.last;
      }
      backendFinished = true;
      // Refresh rifas in provider silently
      if (mounted) {
        context.read<RifaProvider>().loadAllRifas();
      }
    }).catchError((err) {
      backendError = err.toString().replaceAll('Exception: ', '');
      backendFinished = true;
    });

    void scheduleNextTick() {
      _spinTimer = Timer(Duration(milliseconds: currentDelayMs), () {
        if (!mounted) return;

        setState(() {
          // Pick a random participant to display on reel
          _currentTicket = _participantes[random.nextInt(_participantes.length)];
        });

        elapsedMs += currentDelayMs;
        final double progress = (elapsedMs / totalDurationMs).clamp(0.0, 1.0);

        // Ease out decelerating curve
        final double curve = Curves.easeInQuad.transform(progress);
        currentDelayMs = 40 + (curve * 320).round();

        final bool shouldStop = progress >= 1.0 && backendFinished;

        if (shouldStop) {
          if (backendError != null) {
            setState(() {
              _isSpinning = false;
              _errorMessage = backendError;
            });
          } else {
            // Find the winning ticket if available
            ParticipacionRifa? matchingTicket;
            if (backendWinner != null) {
              matchingTicket = _participantes.firstWhere(
                (p) => p.id == backendWinner!.participacionId || p.numeroParticipacion == backendWinner!.numeroParticipacion,
                orElse: () => _currentTicket!,
              );
            }

            setState(() {
              _isSpinning = false;
              _hasDrawn = true;
              if (matchingTicket != null) {
                _currentTicket = matchingTicket;
              }
              _winnerResult = backendWinner;
            });

            _confettiController.repeat();
          }
        } else {
          scheduleNextTick();
        }
      });
    }

    scheduleNextTick();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main Card
          Container(
            width: 580,
            constraints: const BoxConstraints(maxHeight: 700),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _hasDrawn
                    ? Colors.amber.withValues(alpha: 0.8)
                    : _isSpinning
                        ? const Color(0xFF8B5CF6)
                        : Colors.white24,
                width: _hasDrawn ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hasDrawn
                      ? Colors.amber.withValues(alpha: 0.25)
                      : const Color(0xFF6366F1).withValues(alpha: 0.2),
                  blurRadius: 36,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _hasDrawn
                              ? Colors.amber.withValues(alpha: 0.2)
                              : const Color(0xFF6366F1).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _hasDrawn ? Icons.emoji_events_rounded : Icons.casino_rounded,
                          color: _hasDrawn ? Colors.amber : const Color(0xFFA5B4FC),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _hasDrawn
                                  ? '¡Ganador Seleccionado!'
                                  : 'Sorteo Oficial de Rifa',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.rifa.nombre,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!_isSpinning)
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Prize & Type Info Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.card_giftcard_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Premio: ${widget.rifa.premio}',
                              style: GoogleFonts.outfit(
                                color: Colors.amber.shade200,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (widget.rifa.esPremioMayor)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  'PREMIO MAYOR',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Sorteo Equitativo',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ─── THE ANIMATED REEL / DRUM DISPLAY ───
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _hasDrawn
                            ? [const Color(0xFF2E1065), const Color(0xFF1E1B4B), const Color(0xFF451A03)]
                            : [const Color(0xFF030712), const Color(0xFF0F172A), const Color(0xFF030712)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _hasDrawn
                            ? Colors.amber
                            : _isSpinning
                                ? const Color(0xFFA855F7)
                                : Colors.white24,
                        width: _hasDrawn || _isSpinning ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _hasDrawn
                              ? Colors.amber.withValues(alpha: 0.3)
                              : _isSpinning
                                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.35)
                                  : Colors.transparent,
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Left & Right Center Pointers
                        Positioned(
                          left: 12,
                          child: Icon(
                            Icons.arrow_right_rounded,
                            size: 32,
                            color: _hasDrawn
                                ? Colors.amber
                                : _isSpinning
                                    ? const Color(0xFFA855F7)
                                    : Colors.white38,
                          ),
                        ),
                        Positioned(
                          right: 12,
                          child: Icon(
                            Icons.arrow_left_rounded,
                            size: 32,
                            color: _hasDrawn
                                ? Colors.amber
                                : _isSpinning
                                    ? const Color(0xFFA855F7)
                                    : Colors.white38,
                          ),
                        ),

                        // Center Reel Content
                        if (_isLoadingParticipaciones)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(color: AppColors.accent),
                              const SizedBox(height: 12),
                              Text(
                                'Cargando participantes...',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          )
                        else if (_participantes.isEmpty)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.sentiment_dissatisfied_rounded, color: Colors.white54, size: 36),
                              const SizedBox(height: 8),
                              Text(
                                'No hay boletos registrados para esta rifa.',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          )
                        else
                          AnimatedSwitcher(
                            duration: Duration(milliseconds: _isSpinning ? 30 : 250),
                            child: Column(
                              key: ValueKey(_currentTicket?.numeroParticipacion ?? 'ticket'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_hasDrawn) ...[
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'BOLETO GANADOR',
                                        style: GoogleFonts.inter(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                ],

                                // Big Ticket Number
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _hasDrawn
                                        ? Colors.amber.withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _hasDrawn ? Colors.amber : Colors.white24,
                                    ),
                                  ),
                                  child: Text(
                                    '#${_currentTicket?.numeroParticipacion ?? "------"}',
                                    style: GoogleFonts.outfit(
                                      color: _hasDrawn ? Colors.amber : Colors.white,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Participant Name
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_rounded,
                                      color: _hasDrawn ? Colors.amber : Colors.white70,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _hasDrawn && _winnerResult != null && _winnerResult!.nombreGanador.isNotEmpty
                                          ? _winnerResult!.nombreGanador
                                          : _currentTicket?.nombreUsuario.isNotEmpty == true
                                              ? _currentTicket!.nombreUsuario
                                              : 'Usuario #${_currentTicket?.usuarioId ?? ""}',
                                      style: GoogleFonts.outfit(
                                        color: _hasDrawn ? Colors.white : Colors.white70,
                                        fontSize: 18,
                                        fontWeight: _hasDrawn ? FontWeight.bold : FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // Origin Tag
                                Text(
                                  'Origen: ${_currentTicket?.origenLabel ?? ""}',
                                  style: GoogleFonts.inter(
                                    color: _hasDrawn ? Colors.amber.shade200 : Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Subtitle status during animation or winner
                  if (_isSpinning)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA855F7)),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Sorteando aleatoriamente entre ${_participantes.length} boletos...',
                          style: GoogleFonts.inter(color: const Color(0xFFA855F7), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    )
                  else if (_hasDrawn) ...[
                    // Delivery warning notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFF60A5FA), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Nota: Para formalizar la entrega del premio, valida que la membresía de este usuario esté activa.',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 12, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text(
                      '${_participantes.length} boletos registrados listos para sortear',
                      style: GoogleFonts.inter(color: Colors.white60, fontSize: 12.5),
                    ),
                  ],

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action Buttons
                  if (!_hasDrawn) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSpinning ? null : () => Navigator.pop(context),
                          child: Text(
                            'Cancelar',
                            style: GoogleFonts.inter(color: Colors.white60),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: (_isSpinning || _participantes.isEmpty) ? null : _startRoulette,
                          icon: _isSpinning
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.casino_rounded, color: Colors.white, size: 20),
                          label: Text(
                            _isSpinning ? 'Sorteando...' : '¡Iniciar Sorteo Aleatorio!',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 8,
                            shadowColor: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                          label: Text(
                            'Finalizar',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Confetti Animated Overlay
          if (_hasDrawn)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, _) => CustomPaint(
                    painter: _ConfettiPainter(animationValue: _confettiController.value),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confetti Animation Canvas Painter
// ─────────────────────────────────────────────────────────────────────────────

class _ConfettiParticle {
  final double x; // 0 to 1
  final double yOffset;
  final double speed;
  final double size;
  final double rotation;
  final Color color;

  _ConfettiParticle({
    required this.x,
    required this.yOffset,
    required this.speed,
    required this.size,
    required this.rotation,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double animationValue;
  static final List<_ConfettiParticle> _particles = _createParticles();

  _ConfettiPainter({required this.animationValue});

  static List<_ConfettiParticle> _createParticles() {
    final random = math.Random(42);
    final colors = [
      Colors.amber,
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFA855F7),
      Colors.pinkAccent,
    ];

    return List.generate(45, (i) {
      return _ConfettiParticle(
        x: random.nextDouble(),
        yOffset: random.nextDouble(),
        speed: 0.6 + random.nextDouble() * 0.8,
        size: 5.0 + random.nextDouble() * 6.0,
        rotation: random.nextDouble() * math.pi * 2,
        color: colors[random.nextInt(colors.length)],
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final double progress = (animationValue * p.speed + p.yOffset) % 1.0;
      final double currentY = progress * size.height;
      final double currentX = p.x * size.width + math.sin(progress * math.pi * 4) * 20;

      final paint = Paint()
        ..color = p.color.withValues(alpha: (1.0 - (progress - 0.7).clamp(0.0, 0.3) / 0.3))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(p.rotation + progress * math.pi * 3);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
