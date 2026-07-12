import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/upload_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_alert.dart';
import '../../../core/widgets/dashboard_shell.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();

  String _photoUrl = '';
  bool _isSaving = false;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _photoUrl = user?.photoUrl ?? '';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _isUploading = true;
      _errorMessage = null;
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

        final uploadedUrl = await UploadApiService.uploadImage(fileBytes, fileName);
        setState(() {
          _photoUrl = uploadedUrl;
        });

        if (mounted) {
          CustomAlert.show(
            context,
            message: 'Imagen subida correctamente',
            isSuccess: true,
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Información de usuario no encontrada';
      });
      return;
    }

    try {
      final request = UpdateUserRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: null,
        photoUrl: _photoUrl,
      );

      await UserApiService.update(userId, request);

      // Refresh AuthProvider profile state
      await authProvider.refreshProfile();

      if (mounted) {
        CustomAlert.show(
          context,
          message: 'Perfil actualizado correctamente',
          isSuccess: true,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;

    return DashboardShell(
      title: 'Mi Perfil',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mi Perfil',
                style: GoogleFonts.outfit(
                  color: themeColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gestiona tus datos personales, contraseña y foto de perfil.',
                style: GoogleFonts.inter(
                  color: themeColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo section
                  Card(
                    color: themeColors.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: themeColors.borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.5),
                                    width: 3,
                                  ),
                                  color: Colors.white.withOpacity(0.05),
                                ),
                                child: ClipOval(
                                  child: _photoUrl.isNotEmpty
                                      ? Image.network(
                                          '${ApiConfig.serverUrl}$_photoUrl',
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(
                                            Icons.person_rounded,
                                            size: 64,
                                            color: Colors.white30,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person_rounded,
                                          size: 64,
                                          color: Colors.white30,
                                        ),
                                ),
                              ),
                              if (_isUploading)
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _isUploading ? null : _pickAndUploadImage,
                            icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                            label: Text(
                              'Subir Foto',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary.withOpacity(0.15),
                              foregroundColor: AppColors.accent,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Fields section
                  Expanded(
                    child: Card(
                      color: themeColors.cardBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: themeColors.borderColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: GoogleFonts.inter(color: AppColors.error, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Nombre', themeColors),
                                      const SizedBox(height: 8),
                                      CustomTextField(
                                        controller: _firstNameController,
                                        hint: 'Tu nombre',
                                        icon: Icons.person_rounded,
                                        validator: (val) => val == null || val.trim().isEmpty ? 'El nombre es requerido' : null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Apellido', themeColors),
                                      const SizedBox(height: 8),
                                      CustomTextField(
                                        controller: _lastNameController,
                                        hint: 'Tu apellido',
                                        icon: Icons.person_outline_rounded,
                                        validator: (val) => val == null || val.trim().isEmpty ? 'El apellido es requerido' : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('Correo Electrónico', themeColors),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: _emailController,
                              hint: 'ejemplo@correo.com',
                              icon: Icons.email_rounded,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'El correo es requerido';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                                  return 'Ingresa un correo válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('Contraseña', themeColors),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _showChangePasswordModal,
                                icon: const Icon(Icons.lock_outline_rounded, size: 18),
                                label: const Text('Cambiar Contraseña'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary.withOpacity(0.15),
                                  foregroundColor: AppColors.accent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GradientButton(
                                  label: 'Guardar Cambios',
                                  isLoading: _isSaving,
                                  onPressed: _isSaving ? null : _handleSave,
                                ),
                              ],
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
      ),
    ),
  ),
);
}

  Widget _buildLabel(String text, AppThemeColors themeColors) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: themeColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  void _showChangePasswordModal() {
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;
    final currentPasswordController = TextEditingController();
    final confirmCurrentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    
    bool obscureCurrent = true;
    bool obscureConfirmCurrent = true;
    bool obscureNew = true;
    bool isChanging = false;
    String? dialogError;
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: themeColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: themeColors.borderColor),
              ),
              title: Text(
                'Cambiar Contraseña',
                style: GoogleFonts.outfit(
                  color: themeColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 400,
                child: Form(
                  key: dialogFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dialogError != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.error.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    dialogError!,
                                    style: GoogleFonts.inter(color: AppColors.error, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          'Contraseña Actual',
                          style: GoogleFonts.inter(color: themeColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        CustomTextField(
                          controller: currentPasswordController,
                          hint: 'Ingresa tu contraseña actual',
                          icon: Icons.lock_outline_rounded,
                          obscureText: obscureCurrent,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureCurrent ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: themeColors.textSecondary.withOpacity(0.5),
                              size: 20,
                            ),
                            onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Confirmar Contraseña Actual',
                          style: GoogleFonts.inter(color: themeColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        CustomTextField(
                          controller: confirmCurrentPasswordController,
                          hint: 'Confirma tu contraseña actual',
                          icon: Icons.lock_outline_rounded,
                          obscureText: obscureConfirmCurrent,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirmCurrent ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: themeColors.textSecondary.withOpacity(0.5),
                              size: 20,
                            ),
                            onPressed: () => setDialogState(() => obscureConfirmCurrent = !obscureConfirmCurrent),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Requerido';
                            if (val != currentPasswordController.text) return 'Las contraseñas no coinciden';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nueva Contraseña',
                          style: GoogleFonts.inter(color: themeColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        CustomTextField(
                          controller: newPasswordController,
                          hint: 'Ingresa tu nueva contraseña',
                          icon: Icons.vpn_key_rounded,
                          obscureText: obscureNew,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: themeColors.textSecondary.withOpacity(0.5),
                              size: 20,
                            ),
                            onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Requerido';
                            if (val.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isChanging ? null : () => Navigator.pop(ctx),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.inter(color: themeColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: isChanging
                      ? null
                      : () async {
                          if (!dialogFormKey.currentState!.validate()) return;
                          setDialogState(() {
                            isChanging = true;
                            dialogError = null;
                          });
                          try {
                            await UserApiService.changePassword(
                              currentPassword: currentPasswordController.text,
                              confirmCurrentPassword: confirmCurrentPasswordController.text,
                              newPassword: newPasswordController.text,
                            );
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              CustomAlert.show(
                                context,
                                message: 'Contraseña actualizada correctamente',
                                isSuccess: true,
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isChanging = false;
                              dialogError = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: isChanging
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Cambiar',
                          style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
