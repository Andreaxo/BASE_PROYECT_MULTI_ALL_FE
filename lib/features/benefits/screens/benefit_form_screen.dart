import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
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
      final userEmpresaId = authProvider.currentUser?.empresaId;
      if (_selectedCompanyId == null && userEmpresaId != null && userEmpresaId > 0) {
        setState(() {
          _selectedCompanyId = userEmpresaId;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Resuelve el nombre visible de una empresa a partir de su ID.
  /// Prioriza la razón social; si no la tiene, usa el nombre.
  String _resolveCompanyLabel(Company company) {
    final razon = company.razonSocial?.trim();
    if (razon != null && razon.isNotEmpty) return razon;
    return company.name;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompanyId == null || _selectedCompanyId == 0) {
      CustomAlert.show(
        context,
        message: 'Debes seleccionar una empresa',
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
          companyBenefits: _selectedCompanyId,
          isActive: _isActive,
        ),
      );
    } else {
      success = await benefitProvider.createBenefit(
        CreateBenefitRequest(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          companyBenefits: _selectedCompanyId ?? 0,
        ),
      );
    }

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      final error = benefitProvider.errorMessage ?? 'Ocurrió un error';
      CustomAlert.show(context, message: error, isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final benefitProvider = context.watch<BenefitProvider>();
    final companyProvider = context.watch<CompanyProvider>();
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
                                activeColor: const Color(0xFF4ECDC4),
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
                          _buildLabel('Empresa vinculada *'),
                          const SizedBox(height: 8),
                          _buildCompanyDropdown(
                            companyProvider,
                            themeColors,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Info Card ──────────────────────────────────────
                    InfoCard(
                      title: 'Beneficios por Empresa',
                      content:
                          'Cada beneficio está asociado a una empresa específica. '
                          'El nombre o razón social de la empresa aparecerá en la lista '
                          'de beneficios para facilitar su identificación.',
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

  Widget _buildCompanyDropdown(
    CompanyProvider companyProvider,
    AppThemeColors themeColors,
  ) {
    final companies = companyProvider.companies;
    final isLoadingCompanies = companyProvider.isLoading && companies.isEmpty;

    final hasValidSelection = _selectedCompanyId != null && companies.any((c) => c.id == _selectedCompanyId);
    final dropdownValue = hasValidSelection ? _selectedCompanyId : null;

    return Container(
      decoration: BoxDecoration(
        color: themeColors.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dropdownValue == null
              ? themeColors.borderColor
              : const Color(0xFF6C63FF).withValues(alpha: 0.5),
        ),
      ),
      child: isLoadingCompanies
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Cargando empresas...'),
                ],
              ),
            )
          : DropdownButtonHideUnderline(
              child: ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton<int>(
                  value: dropdownValue,
                  isExpanded: true,
                  dropdownColor: themeColors.cardBackground,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: themeColors.textSecondary,
                  ),
                  hint: Row(
                    children: [
                      const SizedBox(width: 8),
                      Icon(
                        Icons.business_rounded,
                        color: themeColors.textSecondary.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Selecciona una empresa...',
                        style: GoogleFonts.inter(
                          color: themeColors.textSecondary.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  items: companies.map((company) {
                    final label = _resolveCompanyLabel(company);
                    return DropdownMenuItem<int>(
                      value: company.id,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: company.isActive
                                  ? const Color(0xFF6C63FF).withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.08),
                              child: Text(
                                label.isNotEmpty
                                    ? label[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.outfit(
                                  color: company.isActive
                                      ? const Color(0xFF4ECDC4)
                                      : Colors.white38,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    label,
                                    style: GoogleFonts.inter(
                                      color: themeColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'NIT: ${company.nit}',
                                    style: GoogleFonts.inter(
                                      color:
                                          themeColors.textSecondary
                                              .withValues(alpha: 0.6),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCompanyId = value);
                  },
                ),
              ),
            ),
    );
  }
}
