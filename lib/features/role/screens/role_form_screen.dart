import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../menu/providers/menu_provider.dart';
import '../models/role_model.dart';
import '../providers/role_provider.dart';

class RoleFormScreen extends StatefulWidget {
  final Role? role;

  const RoleFormScreen({super.key, this.role});

  @override
  State<RoleFormScreen> createState() => _RoleFormScreenState();
}

class _RoleFormScreenState extends State<RoleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late bool _isActive;

  // Stores permissions as "menuId_optionId" strings (e.g. "1_2")
  final Set<String> _selectedPermissions = {};

  bool get isEditing => widget.role != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.role?.name ?? '');
    _codeController = TextEditingController(text: widget.role?.code ?? '');
    _isActive = widget.role?.isActive ?? true;

    // Load menus and options definitions
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<MenuProvider>().loadMenus();
      if (mounted) {
        // Initialize existing permissions in edit mode
        if (isEditing && widget.role!.permissions.isNotEmpty) {
          setState(() {
            for (var p in widget.role!.permissions) {
              _selectedPermissions.add('${p.menuId}_${p.optionId}');
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final roleProvider = context.read<RoleProvider>();
    bool success;

    // Map set to requests
    final permissionsList = _selectedPermissions.map((key) {
      final parts = key.split('_');
      return PermissionRequest(
        menuId: int.parse(parts[0]),
        optionId: int.parse(parts[1]),
      );
    }).toList();

    if (isEditing) {
      success = await roleProvider.updateRole(
        widget.role!.id,
        UpdateRoleRequest(
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          isActive: _isActive,
          permissions: permissionsList,
        ),
      );
    } else {
      success = await roleProvider.createRole(
        CreateRoleRequest(
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          permissions: permissionsList,
        ),
      );
    }

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      final error = roleProvider.errorMessage ?? 'Ocurrió un error';
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
    final menuProvider = context.watch<MenuProvider>();
    final menus = menuProvider.menus;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Editar Rol' : 'Nuevo Rol',
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
                      isEditing ? Icons.security_rounded : Icons.add_moderator_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                _buildLabel('Nombre del Rol'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _nameController,
                  hint: 'Ej: Administrador, Auditor, Gestor',
                  icon: Icons.badge_outlined,
                  validator: (v) => (v == null || v.isEmpty) ? 'El nombre es requerido' : null,
                ),
                const SizedBox(height: 20),

                _buildLabel('Código Único'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _codeController,
                  hint: 'Ej: admin, auditor, manager',
                  icon: Icons.code_rounded,
                  enabled: !isEditing || widget.role!.code != 'superadmin', // Prevent editing superadmin code
                  validator: (v) => (v == null || v.isEmpty) ? 'El código es requerido' : null,
                ),
                const SizedBox(height: 20),

                if (isEditing && widget.role!.code != 'superadmin') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isActive ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                              color: _isActive ? const Color(0xFF4ECDC4) : const Color(0xFFFF6B6B),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Rol activo',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isActive,
                          onChanged: (value) {
                            setState(() => _isActive = value);
                          },
                          activeColor: const Color(0xFF4ECDC4),
                          inactiveTrackColor: Colors.white.withOpacity(0.1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Permissions Matrix Header
                _buildLabel('Matriz de Permisos por Módulo'),
                const SizedBox(height: 12),
                
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Matrix Table Header
                      Container(
                        color: Colors.white.withOpacity(0.04),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Módulo / Menú',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Ver (VIEW)',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Modificar (EDIT)',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Rows
                      menuProvider.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                            )
                          : menus.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Text(
                                    'No hay menús registrados en el sistema.',
                                    style: GoogleFonts.inter(color: Colors.white30),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: menus.length,
                                  separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
                                  itemBuilder: (context, idx) {
                                    final menu = menus[idx];
                                    final viewKey = '${menu.id}_1';
                                    final editKey = '${menu.id}_2';

                                    final hasView = _selectedPermissions.contains(viewKey);
                                    final hasEdit = _selectedPermissions.contains(editKey);

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  menu.label,
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white.withOpacity(0.9),
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  menu.route,
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white.withOpacity(0.4),
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          // VIEW Checkbox
                                          Expanded(
                                            child: Center(
                                              child: Checkbox(
                                                value: hasView,
                                                activeColor: const Color(0xFF6C63FF),
                                                onChanged: (val) {
                                                  setState(() {
                                                    if (val == true) {
                                                      _selectedPermissions.add(viewKey);
                                                    } else {
                                                      _selectedPermissions.remove(viewKey);
                                                      // If VIEW is removed, EDIT should also be removed
                                                      _selectedPermissions.remove(editKey);
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                          
                                          // EDIT Checkbox
                                          Expanded(
                                            child: Center(
                                              child: Checkbox(
                                                value: hasEdit,
                                                activeColor: const Color(0xFF4ECDC4),
                                                onChanged: (val) {
                                                  setState(() {
                                                    if (val == true) {
                                                      _selectedPermissions.add(editKey);
                                                      // If EDIT is added, VIEW must also be added
                                                      _selectedPermissions.add(viewKey);
                                                    } else {
                                                      _selectedPermissions.remove(editKey);
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                Consumer<RoleProvider>(
                  builder: (context, provider, _) {
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: provider.isLoading ? null : _handleSave,
                        icon: provider.isLoading ? const SizedBox.shrink() : const Icon(Icons.save_rounded, size: 20),
                        label: provider.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                isEditing ? 'Guardar Cambios' : 'Crear Rol',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF6C63FF).withOpacity(0.5),
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
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      enabled: enabled,
      style: GoogleFonts.inter(
        color: enabled ? Colors.white : Colors.white54,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.3), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
        filled: true,
        fillColor: enabled ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.02),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
