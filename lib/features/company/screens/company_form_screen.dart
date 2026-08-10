import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/upload_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/outline_button.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_alert.dart';
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
  late TextEditingController _nitController;
  late TextEditingController _razonSocialController;
  late bool _isActive;
  String _photoUrl = '';
  bool _isUploading = false;

  late TextEditingController _validatorEmailController;
  late TextEditingController _validatorPasswordController;
  late TextEditingController _validatorFirstNameController;
  late TextEditingController _validatorLastNameController;

  bool get isEditing => widget.company != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.company?.name ?? '');
    _nitController = TextEditingController(
      text: widget.company?.nit.toString() ?? '',
    );
    _isActive = widget.company?.isActive ?? true;
    _photoUrl = widget.company?.photoUrl ?? '';
    _razonSocialController = TextEditingController(
      text: widget.company?.razonSocial ?? '',
    );
    _validatorEmailController = TextEditingController();
    _validatorPasswordController = TextEditingController();
    _validatorFirstNameController = TextEditingController();
    _validatorLastNameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nitController.dispose();
    _razonSocialController.dispose();
    _validatorEmailController.dispose();
    _validatorPasswordController.dispose();
    _validatorFirstNameController.dispose();
    _validatorLastNameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final fileBytes = result.files.single.bytes!;
        final fileName = result.files.single.name;

        final uploadedUrl = await UploadApiService.uploadImage(
          fileBytes,
          fileName,
        );
        setState(() {
          _photoUrl = uploadedUrl;
        });

        if (mounted) {
          CustomAlert.show(
            context,
            message: 'Logo de empresa subido correctamente',
            isSuccess: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomAlert.show(
          context,
          message: e.toString().replaceAll('Exception: ', ''),
          isSuccess: false,
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
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
          nit: int.parse(_nitController.text.trim()),
          razonSocial: _razonSocialController.text.trim(),
          isActive: _isActive,
          photoUrl: _photoUrl,
        ),
      );
    } else {
      success = await companyProvider.createCompany(
        CreateCompanyRequest(
          name: _nameController.text.trim(),
          nit: int.tryParse(_nitController.text.trim()),
          razonSocial: _razonSocialController.text.trim(),
          photoUrl: _photoUrl,
          validatorEmail: _validatorEmailController.text.trim(),
          validatorPassword: _validatorPasswordController.text.trim(),
          validatorFirstName: _validatorFirstNameController.text.trim(),
          validatorLastName: _validatorLastNameController.text.trim(),
        ),
      );
    }

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      final error = companyProvider.errorMessage ?? 'Ocurrió un error';
      CustomAlert.show(context, message: error, isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                                style: GoogleFonts.inter(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                              Switch(
                                value: _isActive,
                                onChanged: (value) {
                                  setState(() => _isActive = value);
                                },
                                activeColor: const Color(0xFF4ECDC4),
                                inactiveTrackColor: Colors.white.withValues(alpha: 
                                  0.1,
                                ),
                              ),
                              Text(
                                _isActive ? 'Activo' : 'Inactivo',
                                style: GoogleFonts.inter(
                                  color: _isActive
                                      ? const Color(0xFF4ECDC4)
                                      : const Color(0xFFFF6B6B),
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
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                InkWell(
                                  onTap: _isUploading
                                      ? null
                                      : _pickAndUploadLogo,
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 
                                          0.5,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: _photoUrl.isNotEmpty
                                          ? Image.network(
                                              '${ApiConfig.serverUrl}$_photoUrl',
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Icon(
                                                isEditing
                                                    ? Icons
                                                          .domain_verification_rounded
                                                    : Icons.domain_add_rounded,
                                                color: AppColors.accent,
                                                size: 32,
                                              ),
                                            )
                                          : Icon(
                                              isEditing
                                                  ? Icons
                                                        .domain_verification_rounded
                                                  : Icons.domain_add_rounded,
                                              color: Colors.white70,
                                              size: 32,
                                            ),
                                    ),
                                  ),
                                ),
                                if (_isUploading)
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildLabel('Nombre de la Empresa'),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _nameController,
                            hint: 'Ej: Droguería La Sultana',
                            icon: Icons.business_rounded,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'El nombre es requerido'
                                : null,
                          ),
                          const SizedBox(height: 24),

                          _buildLabel('NIT de la empresa'),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _nitController,
                            hint: 'Ej: NIT 1.020.020-1',
                            icon: Icons.numbers_rounded,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(15),
                            ],
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'El NIT es requerido'
                                : null,
                          ),
                          const SizedBox(height: 24),

                          _buildLabel('Razon Social'),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _razonSocialController,
                            hint: 'Ej: Droguería La Sultana Ltda.',
                            icon: Icons.description_rounded,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'La razon social es requerida'
                                : null,
                          ),

                          if (!isEditing) ...[
                            const SizedBox(height: 24),
                            Divider(color: Theme.of(context).dividerColor),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Cuenta del Validador de Negocio (Opcional)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: themeColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildLabel('Correo Electrónico del Validador'),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: _validatorEmailController,
                              hint: 'ejemplo@negocio.com',
                              icon: Icons.email_rounded,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            _buildLabel('Contraseña de Acceso'),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: _validatorPasswordController,
                              hint: 'Mínimo 6 caracteres',
                              icon: Icons.lock_rounded,
                              obscureText: true,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Nombre Encargado'),
                                      const SizedBox(height: 8),
                                      CustomTextField(
                                        controller: _validatorFirstNameController,
                                        hint: 'Ej: Carlos',
                                        icon: Icons.person_rounded,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Apellido Encargado'),
                                      const SizedBox(height: 8),
                                      CustomTextField(
                                        controller: _validatorLastNameController,
                                        hint: 'Ej: Pérez',
                                        icon: Icons.person_outline_rounded,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Conseil Card
                    InfoCard(
                      title: 'Aislamiento Organizacional',
                      content:
                          'El nombre de la empresa debe describir claramente a la entidad asociada. Así se podrán generar los beneficios',
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
}
