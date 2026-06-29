import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../company/providers/company_provider.dart';
import '../../role/providers/role_provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';

/// Form screen for creating or editing a user.
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

  int? _selectedRoleId;
  final Set<int> _selectedCompanyIds = {};

  bool get isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
    _firstNameController =
        TextEditingController(text: widget.user?.firstName ?? '');
    _lastNameController =
        TextEditingController(text: widget.user?.lastName ?? '');
    _isActive = widget.user?.isActive ?? true;

    _selectedRoleId = widget.user?.roleId;
    if (widget.user != null) {
      _selectedCompanyIds.addAll(widget.user!.companies.map((c) => c.id));
    }

    // Load available roles and companies for dropdown/selection
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
          password: _passwordController.text.isNotEmpty
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
      // Show error snackbar
      final error = userProvider.errorMessage ?? context.tr('error_occurred');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final isSuperAdmin = authProvider.roleCode == 'superadmin';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? context.tr('edit_user') : context.tr('add_user'),
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF1A1A2E),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar header
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      isEditing
                          ? Icons.edit_outlined
                          : Icons.person_add_outlined,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // First Name
                _buildLabel(context.tr('first_name')),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _firstNameController,
                  hint: context.tr('enter_first_name'),
                  icon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.isEmpty)
                      ? context.tr('first_name_required')
                      : null,
                ),
                const SizedBox(height: 20),

                // Last Name
                _buildLabel(context.tr('last_name')),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _lastNameController,
                  hint: context.tr('enter_last_name'),
                  icon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.isEmpty)
                      ? context.tr('last_name_required')
                      : null,
                ),
                const SizedBox(height: 20),

                // Email
                _buildLabel(context.tr('email')),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController,
                  hint: 'correo@ejemplo.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return context.tr('email_required');
                    if (!v.contains('@')) return context.tr('invalid_email');
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password
                _buildLabel(isEditing
                    ? context.tr('password_keep_empty')
                    : context.tr('password')),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _passwordController,
                  hint: isEditing ? context.tr('password_placeholder_edit') : context.tr('password_min_length'),
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white.withOpacity(0.4),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (v) {
                    if (!isEditing && (v == null || v.isEmpty)) {
                      return context.tr('password_required');
                    }
                    if (v != null && v.isNotEmpty && v.length < 6) {
                      return context.tr('password_min_length');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // SuperAdmin-only Role and Company management
                if (isSuperAdmin) ...[
                  // Role Dropdown
                  _buildLabel(context.tr('assigned_role')),
                  const SizedBox(height: 8),
                  Consumer<RoleProvider>(
                    builder: (context, roleProvider, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedRoleId,
                            hint: Text(
                              context.tr('select_role'),
                              style: GoogleFonts.inter(color: Colors.white30, fontSize: 14),
                            ),
                            dropdownColor: const Color(0xFF1E1E2E),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                            isExpanded: true,
                            onChanged: (val) {
                              setState(() {
                                _selectedRoleId = val;
                              });
                            },
                            items: roleProvider.roles.map((role) {
                              return DropdownMenuItem<int>(
                                value: role.id,
                                child: Text(role.name),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Company Select Checkboxes
                  _buildLabel(context.tr('associated_companies')),
                  const SizedBox(height: 8),
                  Consumer<CompanyProvider>(
                    builder: (context, companyProvider, _) {
                      if (companyProvider.isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                          ),
                        );
                      }
                      if (companyProvider.companies.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            context.tr('no_companies_found'),
                            style: GoogleFonts.inter(color: Colors.white30, fontSize: 14),
                          ),
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: companyProvider.companies.length,
                          itemBuilder: (context, index) {
                            final company = companyProvider.companies[index];
                            final isChecked = _selectedCompanyIds.contains(company.id);

                            return CheckboxListTile(
                              value: isChecked,
                              title: Text(
                                company.name,
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                              ),
                              activeColor: const Color(0xFF6C63FF),
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
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // Active toggle (only for edit mode)
                if (isEditing) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isActive
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.cancel_outlined,
                              color: _isActive
                                  ? const Color(0xFF4ECDC4)
                                  : const Color(0xFFFF6B6B),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              context.tr('user_active'),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isActive,
                          onChanged: (value) {
                            setState(() => _isActive = value);
                          },
                          activeColor: const Color(0xFF4ECDC4),
                          inactiveTrackColor:
                              Colors.white.withOpacity(0.1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ] else
                  const SizedBox(height: 12),

                // Save button
                Consumer<UserProvider>(
                  builder: (context, provider, _) {
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed:
                            provider.isLoading ? null : _handleSave,
                        icon: provider.isLoading
                            ? const SizedBox.shrink()
                            : const Icon(Icons.save_rounded, size: 20),
                        label: provider.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                ),
                              )
                            : Text(
                                isEditing ? context.tr('save_changes') : context.tr('create_user'),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF6C63FF).withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: Colors.white.withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: Colors.white.withOpacity(0.3),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
        ),
        errorStyle: GoogleFonts.inter(color: const Color(0xFFFF6B6B)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
