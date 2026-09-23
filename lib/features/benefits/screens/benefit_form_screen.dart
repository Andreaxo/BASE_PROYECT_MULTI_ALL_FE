import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_alert.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/outline_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../company/models/company_model.dart';
import '../../company/providers/company_provider.dart';
import '../models/benefit_model.dart';
import '../providers/benefit_provider.dart';

class BenefitFormScreen extends StatefulWidget {
  final Benefit? benefit;

  const BenefitFormScreen({super.key, this.benefit});

  @override
  State<BenefitFormScreen> createState() => _BenefitFormScreenState();
}

class _BenefitFormScreenState extends State<BenefitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late bool _isActive;

  /// ID de la empresa seleccionada en el dropdown
  int? _selectedCompanyId;

  bool get isEditing => widget.benefit != null;



  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.benefit?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.benefit?.description ?? '');
    _isActive = widget.benefit?.isActive ?? true;

    final initialCompId = (widget.benefit?.companyBenefits != null && widget.benefit!.companyBenefits > 0)
        ? widget.benefit!.companyBenefits
        : null;
    _selectedCompanyId = initialCompId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final companyProvider = context.read<CompanyProvider>();
      if (companyProvider.companies.isEmpty) {
        companyProvider.loadCompanies();
      }
      final authProvider = context.read<AuthProvider>();
      if (_selectedCompanyId == null) {
        final autoCompId = authProvider.activeCompany?.id ??
            authProvider.currentUser?.empresaId ??
            (authProvider.userCompanies.isNotEmpty
                ? authProvider.userCompanies.first.id
                : (authProvider.isAdminOrSuperAdmin && companyProvider.companies.isNotEmpty
                    ? companyProvider.companies.first.id
                    : null));
        if (autoCompId != null && autoCompId > 0) {
          setState(() {
            _selectedCompanyId = autoCompId;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Resuelve el nombre visible de una empresa a partir de su objeto.
  /// Prioriza la razón social; si no la tiene, usa el nombre comercial.
  String _resolveCompanyLabel(Company company) {
    final razon = company.razonSocial?.trim();
    if (razon != null && razon.isNotEmpty) return razon;
    return company.name;
  }

  /// Resuelve la empresa asociada para mostrar sus datos y asegurar que el beneficio
  /// quede estrictamente asignado a ella.
  Company? _resolveTargetCompany(
    AuthProvider authProvider,
    CompanyProvider companyProvider,
  ) {
    final compId = _selectedCompanyId ??
        widget.benefit?.companyBenefits ??
        authProvider.activeCompany?.id ??
        authProvider.currentUser?.empresaId ??
        (authProvider.userCompanies.isNotEmpty
            ? authProvider.userCompanies.first.id
            : null);

    if (compId == null) {
      return authProvider.activeCompany;
    }

    if (authProvider.activeCompany?.id == compId) {
      return authProvider.activeCompany;
    }

    final inUser = authProvider.userCompanies.where((c) => c.id == compId);
    if (inUser.isNotEmpty) return inUser.first;

    final inAll = companyProvider.companies.where((c) => c.id == compId);
    if (inAll.isNotEmpty) return inAll.first;

    return authProvider.activeCompany;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final companyProvider = context.read<CompanyProvider>();
    final targetCompany = _resolveTargetCompany(authProvider, companyProvider);
    final targetCompanyId = targetCompany?.id ?? _selectedCompanyId;

    if (targetCompanyId == null || targetCompanyId == 0) {
      CustomAlert.show(
        context,
        message: 'No se ha detectado una empresa vinculada para registrar este beneficio',
        isSuccess: false,
      );
      return;
    }

    final benefitProvider = context.read<BenefitProvider>();
    bool success;

    if (isEditing) {
      success = await benefitProvider.updateBenefit(
        widget.benefit!.id,
        UpdateBenefitRequest(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          companyBenefits: targetCompanyId,
          isActive: _isActive,
        ),
      );
    } else {
      success = await benefitProvider.createBenefit(
        CreateBenefitRequest(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          companyBenefits: targetCompanyId,
        ),
      );
    }

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      final error = benefitProvider.errorMessage ?? 'Ocurrió un error';
      final lowerErr = error.toLowerCase();
      if (lowerErr.contains('suscripción') ||
          lowerErr.contains('suscripcion') ||
          lowerErr.contains('subscription') ||
          lowerErr.contains('expirad') ||
          lowerErr.contains('vencid')) {
        _showSubscriptionExpiredDialog(context, error);
      } else {
        CustomAlert.show(context, message: error, isSuccess: false);
      }
    }
  }

  void _showSubscriptionExpiredDialog(BuildContext context, String rawMessage) {
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppTheme.darkThemeColors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: themeColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Suscripción Inactiva o Vencida',
                style: GoogleFonts.outfit(
                  color: themeColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
              rawMessage.isNotEmpty && rawMessage.contains('suscripción')
                  ? rawMessage
                  : 'La suscripción de tu empresa se encuentra inactiva o vencida. Para crear nuevos beneficios y publicar promociones, por favor activa tu suscripción comunicándote con el administrador de Conexiate.',
              style: GoogleFonts.inter(
                color: themeColors.textSecondary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Entendido',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final benefitProvider = context.watch<BenefitProvider>();
    final companyProvider = context.watch<CompanyProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isSuperAdmin = authProvider.isAdminOrSuperAdmin;
    final targetCompany = _resolveTargetCompany(authProvider, companyProvider);
    if (_selectedCompanyId == null && targetCompany != null) {
      _selectedCompanyId = targetCompany.id;
    }

    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppTheme.darkThemeColors;

    return Scaffold(
      backgroundColor: themeColors.gradientBg.first,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: themeColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Beneficios',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: themeColors.textSecondary,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: themeColors.gradientBg,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Título y switch de estado ──────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing
                                    ? 'Editar Beneficio'
                                    : 'Nuevo Beneficio',
                                style: GoogleFonts.outfit(
                                  color: themeColors.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isEditing
                                    ? 'Modifica la información del beneficio asociado a la empresa.'
                                    : 'Registra un nuevo beneficio vinculado a una empresa existente.',
                                style: GoogleFonts.inter(
                                  color: themeColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isEditing) ...[
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Estado',
                                style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              Switch(
                                value: _isActive,
                                onChanged: (value) =>
                                    setState(() => _isActive = value),
                                activeThumbColor: const Color(0xFF4ECDC4),
                                inactiveTrackColor:
                                    Colors.white.withValues(alpha: 0.1),
                              ),
                              Text(
                                _isActive ? 'Activo' : 'Inactivo',
                                style: GoogleFonts.inter(
                                  color: _isActive
                                      ? const Color(0xFF4ECDC4)
                                      : const Color(0xFFFF6B6B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Tarjeta principal ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icono decorativo
                          Center(
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6C63FF),
                                    Color(0xFF4ECDC4),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6C63FF)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.card_giftcard_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Nombre
                          _buildLabel('Nombre del Beneficio *'),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _nameController,
                            hint: 'Ej: Descuento en salud, Bono alimenticio...',
                            icon: Icons.card_giftcard_rounded,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'El nombre es requerido'
                                    : null,
                          ),
                          const SizedBox(height: 22),

                          // Descripción
                          _buildLabel('Descripción'),
                          const SizedBox(height: 8),
                          _buildDescriptionField(themeColors),
                          const SizedBox(height: 22),

                          // Empresa vinculada
                          _buildLabel('Empresa Vinculada'),
                          const SizedBox(height: 8),
                          _buildCompanyInfoCard(
                            targetCompany,
                            themeColors,
                            isSuperAdmin,
                          ),
                          if (isSuperAdmin && !isEditing) ...[
                            const SizedBox(height: 12),
                            _buildSuperAdminCompanySelector(
                              companyProvider,
                              themeColors,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Info Card ──────────────────────────────────────
                    InfoCard(
                      title: 'Beneficios por Empresa',
                      content:
                          'Los beneficios quedan registrados de forma exclusiva bajo la razón social de tu empresa. '
                          'Los miembros afiliados podrán encontrarlos y redimirlos identificando tu negocio.',
                      icon: Icons.info_outline_rounded,
                      iconColor: const Color(0xFF4ECDC4),
                    ),
                    const SizedBox(height: 32),

                    // ── Botones de acción ──────────────────────────────
                    Divider(color: themeColors.borderColor),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlineButtonWidget(
                          label: 'Cancelar',
                          onPressed: () => Navigator.pop(context),
                          width: 140,
                        ),
                        const SizedBox(width: 16),
                        GradientButton(
                          label:
                              isEditing ? 'Guardar Cambios' : 'Crear Beneficio',
                          icon: Icons.save_rounded,
                          isLoading: benefitProvider.isLoading,
                          onPressed: _handleSave,
                          width: 200,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppTheme.darkThemeColors;
    return Text(
      text,
      style: GoogleFonts.inter(
        color: themeColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDescriptionField(AppThemeColors themeColors) {
    return Container(
      decoration: BoxDecoration(
        color: themeColors.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColors.borderColor),
      ),
      child: TextFormField(
        controller: _descriptionController,
        cursorColor: const Color(0xFF6C63FF),
        cursorWidth: 2.0,
        cursorRadius: const Radius.circular(2),
        showCursor: true,
        maxLines: 4,
        style: GoogleFonts.inter(
          color: themeColors.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Describe el beneficio ofrecido...',
          hintStyle: GoogleFonts.inter(
            color: themeColors.textSecondary.withValues(alpha: 0.5),
            fontSize: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: Icon(
              Icons.description_rounded,
              color: themeColors.textSecondary.withValues(alpha: 0.5),
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  // ── Tarjeta de información exclusiva de la empresa (sin select para negocios) ──

  Widget _buildCompanyInfoCard(
    Company? company,
    AppThemeColors themeColors,
    bool isSuperAdmin,
  ) {
    if (company == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: themeColors.textPrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: themeColors.borderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.business_outlined, color: Colors.amber, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'No se ha detectado una empresa vinculada a tu cuenta. Comunícate con soporte.',
                style: GoogleFonts.inter(
                  color: themeColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final label = _resolveCompanyLabel(company);
    final commercialName = company.name.trim();
    final hasRazonSocial =
        company.razonSocial != null && company.razonSocial!.trim().isNotEmpty;
    final photoUrl = company.photoUrl.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar o Logo
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl.startsWith('http')
                            ? photoUrl
                            : '${ApiConfig.serverUrl}$photoUrl',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            label.isNotEmpty ? label[0].toUpperCase() : 'E',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          label.isNotEmpty ? label[0].toUpperCase() : 'E',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 14),

              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: themeColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                size: 12,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isSuperAdmin ? 'Empresa Seleccionada' : 'Tu Empresa',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (hasRazonSocial && commercialName != label) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Nombre comercial: $commercialName',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: themeColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _buildDetailChip(
                          Icons.badge_outlined,
                          'NIT: ${company.nit}',
                          themeColors,
                        ),
                        if (company.codigoEmpresa != null &&
                            company.codigoEmpresa!.isNotEmpty)
                          _buildDetailChip(
                            Icons.tag_rounded,
                            'Código: ${company.codigoEmpresa}',
                            themeColors,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: themeColors.textPrimary.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: themeColors.borderColor.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_rounded,
                  size: 14,
                  color: themeColors.textSecondary.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSuperAdmin
                        ? 'Modo Administrador: El beneficio se asociará a la empresa seleccionada arriba.'
                        : 'Seguridad: Los beneficios se vinculan automáticamente a tu empresa y no pueden transferirse a terceros.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: themeColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(
    IconData icon,
    String text,
    AppThemeColors themeColors,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: themeColors.textSecondary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: themeColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Selector exclusivo de SuperAdmin para asociar beneficios a cualquier empresa
  Widget _buildSuperAdminCompanySelector(
    CompanyProvider companyProvider,
    AppThemeColors themeColors,
  ) {
    final companies = companyProvider.companies;
    final isLoadingCompanies = companyProvider.isLoading && companies.isEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: themeColors.textPrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.admin_panel_settings_rounded,
                size: 16,
                color: Color(0xFF6C63FF),
              ),
              const SizedBox(width: 6),
              Text(
                'Cambiar Empresa (Exclusivo SuperAdmin)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6C63FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          isLoadingCompanies
              ? const Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Cargando empresas del sistema...'),
                  ],
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedCompanyId,
                    isExpanded: true,
                    dropdownColor: themeColors.cardBackground,
                    icon: Icon(
                      Icons.swap_horiz_rounded,
                      color: themeColors.textSecondary,
                    ),
                    hint: Text(
                      'Selecciona otra empresa...',
                      style: GoogleFonts.inter(
                        color: themeColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    items: companies.map((comp) {
                      final name = _resolveCompanyLabel(comp);
                      return DropdownMenuItem<int>(
                        value: comp.id,
                        child: Text(
                          '$name (NIT: ${comp.nit})',
                          style: GoogleFonts.inter(
                            color: themeColors.textPrimary,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCompanyId = val);
                      }
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
