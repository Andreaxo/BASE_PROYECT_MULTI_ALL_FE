import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/outline_button.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/theme/app_theme.dart';
import '../models/company_model.dart';
import '../providers/company_provider.dart';

class CompanyFormScreen extends StatefulWidget {
  final Company? company;

  const CompanyFormScreen({super.key, this.company});

  @override
  State<CompanyFormScreen> createState() => _CompanyFormScreenState();
}

class _CompanyFormScreenState extends State<CompanyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late bool _isActive;

  bool get isEditing => widget.company != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.company?.name ?? '');
    _isActive = widget.company?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final companyProvider = context.read<CompanyProvider>();
    bool success;

    if (isEditing) {
      success = await companyProvider.updateCompany(
        widget.company!.id,
        UpdateCompanyRequest(
          name: _nameController.text.trim(),
          isActive: _isActive,
        ),
      );
    } else {
      success = await companyProvider.createCompany(
        CreateCompanyRequest(
          name: _nameController.text.trim(),
        ),
      );
    }

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      final error = companyProvider.errorMessage ?? 'Ocurrió un error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyProvider = context.watch<CompanyProvider>();
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;

    return Scaffold(
      backgroundColor: themeColors.gradientBg.first,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: themeColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Empresas',
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
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Switch Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing ? 'Editar Empresa' : 'Nueva Empresa',
                                style: GoogleFonts.outfit(
                                  color: themeColors.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Registre o modifique la información de la empresa multicliente.',
                                style: GoogleFonts.inter(
                                  color: themeColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isEditing) ...[
                          Row(
                            children: [
                              Text(
                                'Estado: ',
                                style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                              ),
                              Switch(
                                value: _isActive,
                                onChanged: (value) {
                                  setState(() => _isActive = value);
                                },
                                activeColor: const Color(0xFF4ECDC4),
                                inactiveTrackColor: Colors.white.withOpacity(0.1),
                              ),
                              Text(
                                _isActive ? 'Activo' : 'Inactivo',
                                style: GoogleFonts.inter(
                                  color: _isActive ? const Color(0xFF4ECDC4) : const Color(0xFFFF6B6B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Main card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                isEditing ? Icons.domain_verification_rounded : Icons.domain_add_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildLabel('Nombre de la Empresa'),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _nameController,
                            hint: 'Ej: Empresa Base S.A.',
                            icon: Icons.business_rounded,
                            validator: (v) => (v == null || v.isEmpty) ? 'El nombre es requerido' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Conseil Card
                    InfoCard(
                      title: 'Aislamiento Organizacional',
                      content: 'El nombre de la empresa debe describir claramente a la entidad asociada. Los datos de inventario y catálogos de este espacio de trabajo no serán visibles por otras empresas.',
                      icon: Icons.info_outline_rounded,
                      iconColor: const Color(0xFF4ECDC4),
                    ),
                    const SizedBox(height: 32),

                    // Action buttons
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
                          label: 'Guardar Cambios',
                          icon: Icons.save_rounded,
                          isLoading: companyProvider.isLoading,
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

  Widget _buildLabel(String text) {
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;
    return Text(
      text,
      style: GoogleFonts.inter(
        color: themeColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
