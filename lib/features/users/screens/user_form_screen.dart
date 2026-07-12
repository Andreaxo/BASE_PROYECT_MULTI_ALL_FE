import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/outline_button.dart';
import '../../../core/widgets/info_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../company/providers/company_provider.dart';
import '../../role/providers/role_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_alert.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';

class UserFormScreen extends StatefulWidget {
  final User? user;

  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late bool _isActive;
  bool _obscurePassword = true;
  bool _activatePasswordInput = false;

  int? _selectedRoleId;
  final Set<int> _selectedCompanyIds = {};

  bool get isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
    _firstNameController = TextEditingController(text: widget.user?.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.user?.lastName ?? '');
    _isActive = widget.user?.isActive ?? true;

    _selectedRoleId = widget.user?.roleId;
    if (widget.user != null) {
      _selectedCompanyIds.addAll(widget.user!.companies.map((c) => c.id));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoleProvider>().loadRoles();
      context.read<CompanyProvider>().loadCompanies();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = context.read<UserProvider>();
    bool success;

    if (isEditing) {
      success = await userProvider.updateUser(
        widget.user!.id,
        UpdateUserRequest(
          email: _emailController.text.trim(),
          password: (_activatePasswordInput && _passwordController.text.isNotEmpty)
              ? _passwordController.text
              : null,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          isActive: _isActive,
          roleId: _selectedRoleId,
          companyIds: _selectedCompanyIds.toList(),
        ),
      );
    } else {
      success = await userProvider.createUser(
        CreateUserRequest(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          roleId: _selectedRoleId,
          companyIds: _selectedCompanyIds.toList(),
        ),
      );
    }

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      final error = userProvider.errorMessage ?? context.tr('error_occurred');
      CustomAlert.show(
        context,
        message: error,
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = context.watch<RoleProvider>();
    final companyProvider = context.watch<CompanyProvider>();
    final userProvider = context.watch<UserProvider>();
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
          context.tr('users_directory'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? context.tr('edit_user') : context.tr('add_user'),
                            style: GoogleFonts.outfit(
                              color: themeColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Configure los datos personales, el rol de acceso y empresas asignadas para el usuario.',
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

                LayoutBuilder(
                  builder: (context, constraints) {
                    final useTwoColumns = constraints.maxWidth > 900;
                    
                    final leftColumn = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Information Card
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
                              Text(
                                'Información Básica',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel(context.tr('first_name')),
                                        const SizedBox(height: 8),
                                        CustomTextField(
                                          controller: _firstNameController,
                                          hint: 'Ej: Juan',
                                          icon: Icons.person_outline_rounded,
                                          validator: (v) => (v == null || v.isEmpty) ? 'El nombre es requerido' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildLabel(context.tr('last_name')),
                                        const SizedBox(height: 8),
                                        CustomTextField(
                                          controller: _lastNameController,
                                          hint: 'Ej: Pérez',
                                          icon: Icons.person_outline_rounded,
                                          validator: (v) => (v == null || v.isEmpty) ? 'El apellido es requerido' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              _buildLabel(context.tr('email')),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: _emailController,
                                hint: 'juan.perez@example.com',
                                icon: Icons.email_outlined,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'El email es requerido';
                                  if (!v.contains('@')) return 'Email inválido';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              if (isEditing && !_activatePasswordInput) ...[
                                _buildLabel(context.tr('password')),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => setState(() => _activatePasswordInput = true),
                                    icon: const Icon(Icons.lock_reset_rounded, size: 18),
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
                              ] else ...[
                                _buildLabel(context.tr('password')),
                                const SizedBox(height: 8),
                                CustomTextField(
                                  controller: _passwordController,
                                  hint: isEditing ? 'Nueva contraseña (mínimo 6 caracteres)' : 'Mínimo 6 caracteres',
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  validator: (v) {
                                    if (!isEditing && (v == null || v.isEmpty)) return 'La contraseña es requerida';
                                    if (isEditing && _activatePasswordInput && (v == null || v.isEmpty)) return 'La contraseña es requerida';
                                    if (v != null && v.isNotEmpty && v.length < 6) return 'Debe tener al menos 6 caracteres';
                                    return null;
                                  },
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      color: themeColors.textSecondary.withOpacity(0.5),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Conseil Card
                        InfoCard(
                          title: 'Seguridad de Cuentas',
                          content: 'Utilice contraseñas seguras que incluyan combinaciones de letras, números y caracteres especiales. El correo del usuario debe ser único en el sistema.',
                          icon: Icons.security_outlined,
                          iconColor: const Color(0xFFFFB300),
                        ),
                      ],
                    );

                    final rightColumn = Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: themeColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: themeColors.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Roles y Empresas',
                            style: GoogleFonts.outfit(
                              color: themeColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildLabel('Rol Asignado'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: themeColors.textPrimary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: themeColors.borderColor),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _selectedRoleId,
                                hint: Text('Selecciona un Rol', style: GoogleFonts.inter(color: themeColors.textSecondary.withOpacity(0.5), fontSize: 14)),
                                dropdownColor: themeColors.cardBackground,
                                icon: Icon(Icons.arrow_drop_down, color: themeColors.textSecondary),
                                style: GoogleFonts.inter(color: themeColors.textPrimary, fontSize: 15),
                                isExpanded: true,
                                onChanged: (val) {
                                  setState(() => _selectedRoleId = val);
                                },
                                items: roleProvider.roles.map((r) {
                                  return DropdownMenuItem<int>(
                                    value: r.id,
                                    child: Text(r.name, style: GoogleFonts.inter(color: themeColors.textPrimary)),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildLabel('Empresas Relacionadas'),
                          const SizedBox(height: 12),
                          companyProvider.isLoading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: CircularProgressIndicator(color: AppColors.primary),
                                  ),
                                )
                              : companyProvider.companies.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Text(
                                        'No hay empresas registradas.',
                                        style: GoogleFonts.inter(color: themeColors.textSecondary.withOpacity(0.5)),
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: themeColors.textPrimary.withOpacity(0.02),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: themeColors.borderColor),
                                      ),
                                      height: 200,
                                      child: ListView.separated(
                                        itemCount: companyProvider.companies.length,
                                        separatorBuilder: (_, __) => Divider(color: themeColors.borderColor, height: 1),
                                        itemBuilder: (context, index) {
                                          final company = companyProvider.companies[index];
                                          final isChecked = _selectedCompanyIds.contains(company.id);

                                          return CheckboxListTile(
                                            value: isChecked,
                                            title: Text(
                                              company.name,
                                              style: GoogleFonts.inter(color: themeColors.textPrimary, fontSize: 14),
                                            ),
                                            activeColor: AppColors.primary,
                                            checkColor: Colors.black,
                                            controlAffinity: ListTileControlAffinity.leading,
                                            onChanged: (val) {
                                              setState(() {
                                                if (val == true) {
                                                  _selectedCompanyIds.add(company.id);
                                                } else {
                                                  _selectedCompanyIds.remove(company.id);
                                                }
                                              });
                                            },
                                          );
                                        },
                                      ),
                                    ),
                        ],
                      ),
                    );

                    if (useTwoColumns) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 1, child: leftColumn),
                          const SizedBox(width: 24),
                          Expanded(flex: 1, child: rightColumn),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          leftColumn,
                          const SizedBox(height: 24),
                          rightColumn,
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 40),

                // Bottom actions bar
                Divider(color: themeColors.borderColor),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlineButtonWidget(
                      label: context.tr('cancel'),
                      onPressed: () => Navigator.pop(context),
                      width: 140,
                    ),
                    const SizedBox(width: 16),
                    GradientButton(
                      label: isEditing ? context.tr('save_changes') : context.tr('create_user'),
                      icon: Icons.save_rounded,
                      isLoading: userProvider.isLoading,
                      onPressed: _handleSave,
                      width: 200,
                    ),
                  ],
                ),
                const SizedBox(height: 48),
              ],
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
