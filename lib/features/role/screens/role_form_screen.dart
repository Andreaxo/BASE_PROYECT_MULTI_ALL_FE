import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/outline_button.dart';
import '../../../core/widgets/info_card.dart';
import '../../menu/models/menu_model.dart';
import '../../menu/providers/menu_provider.dart';
import '../../../core/theme/app_theme.dart';
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
  late TextEditingController _descriptionController;
  late bool _isActive;

  // Stores permissions as "menuId_optionId" strings (e.g. "1_2")
  final Set<String> _selectedPermissions = {};

  // Search filter query
  String _menuSearchQuery = '';

  // Collapsed/Expanded state for parent menus
  final Map<int, bool> _expandedParents = {};

  bool get isEditing => widget.role != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.role?.name ?? '');
    _codeController = TextEditingController(text: widget.role?.code ?? '');
    _descriptionController = TextEditingController(text: ''); // Added description controller
    _isActive = widget.role?.isActive ?? true;

    // Auto-generate code from role name (e.g. "Editor" -> "ROL_EDITOR")
    if (!isEditing) {
      _nameController.addListener(_onNameChanged);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<MenuProvider>().loadMenus();
      if (mounted) {
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
    if (!isEditing) {
      _nameController.removeListener(_onNameChanged);
    }
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final text = _nameController.text
        .toUpperCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^A-Z0-9_]'), '');
    _codeController.text = text.isEmpty ? '' : 'ROL_$text';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final roleProvider = context.read<RoleProvider>();
    bool success;

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

  void _toggleCascade(int menuId, int optionId, bool checked) {
    final viewKey = '${menuId}_1';
    final editKey = '${menuId}_2';
    final createKey = '${menuId}_3';
    final deleteKey = '${menuId}_4';
    final currentKey = '${menuId}_$optionId';

    setState(() {
      if (checked) {
        _selectedPermissions.add(currentKey);
        // If checking CREATE, EDIT, or DELETE -> automatically check VIEW
        if (optionId != 1) {
          _selectedPermissions.add(viewKey);
        }
      } else {
        _selectedPermissions.remove(currentKey);
        // If unchecking VIEW -> automatically uncheck CREATE, EDIT, and DELETE
        if (optionId == 1) {
          _selectedPermissions.remove(createKey);
          _selectedPermissions.remove(editKey);
          _selectedPermissions.remove(deleteKey);
        }
      }
    });
  }

  void _selectAll(List<MenuModel> menus) {
    setState(() {
      for (var m in menus) {
        _selectedPermissions.add('${m.id}_1');
        _selectedPermissions.add('${m.id}_2');
        _selectedPermissions.add('${m.id}_3');
        _selectedPermissions.add('${m.id}_4');
      }
    });
  }

  void _clearAll(List<MenuModel> menus) {
    setState(() {
      for (var m in menus) {
        _selectedPermissions.remove('${m.id}_1');
        _selectedPermissions.remove('${m.id}_2');
        _selectedPermissions.remove('${m.id}_3');
        _selectedPermissions.remove('${m.id}_4');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final roleProvider = context.watch<RoleProvider>();
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;
    final menus = menuProvider.menus;

    // Filter visible menus hierarchically
    final query = _menuSearchQuery.toLowerCase();
    final matchingMenus = menus.where((m) =>
        m.label.toLowerCase().contains(query) ||
        m.route.toLowerCase().contains(query)
    ).toList();

    final Set<int> visibleMenuIds = {};
    for (var m in matchingMenus) {
      visibleMenuIds.add(m.id);
      if (m.parentId != null) {
        visibleMenuIds.add(m.parentId!);
      }
    }

    final filteredMenus = menus.where((m) => visibleMenuIds.contains(m.id)).toList();
    final parentMenus = filteredMenus.where((m) => m.parentId == null).toList();

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
          'Gestión de Roles',
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
                // Title and Subtitle Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Editar Rol' : 'Crear Nuevo Rol',
                            style: GoogleFonts.outfit(
                              color: themeColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Configure los permisos y niveles de acceso para el perfil del sistema.',
                            style: GoogleFonts.inter(
                              color: themeColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isEditing && widget.role!.code != 'superadmin') ...[
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

                // Responsive Column Layout (Two columns on widescreen)
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
                              _buildLabel('Nombre del Rol'),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: _nameController,
                                hint: 'Ej: Editor de Contenido',
                                icon: Icons.badge_outlined,
                                validator: (v) => (v == null || v.isEmpty) ? 'El nombre es requerido' : null,
                              ),
                              const SizedBox(height: 20),
                              _buildLabel('Código Único (Auto-generado)'),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: _codeController,
                                hint: 'ROL_EDITOR_DE_CONTENIDO',
                                icon: Icons.code_rounded,
                                enabled: !isEditing || widget.role!.code != 'superadmin',
                                validator: (v) => (v == null || v.isEmpty) ? 'El código es requerido' : null,
                              ),
                              const SizedBox(height: 20),
                              _buildLabel('Descripción'),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: _descriptionController,
                                hint: 'Describa brevemente las responsabilidades...',
                                icon: Icons.description_outlined,
                                maxLines: 4,
                                minLines: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // InfoCard Pro Tip
                        InfoCard(
                          title: 'Consejo Profesional',
                          content: 'Asigne solo los permisos estrictamente necesarios siguiendo el principio de "mínimo privilegio" para mejorar la seguridad del sistema.',
                          icon: Icons.lightbulb_outline_rounded,
                          iconColor: const Color(0xFFFFB300),
                        ),
                      ],
                    );

                    final rightColumn = Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Permissions title and links
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.lock_person_rounded, color: Colors.white70, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Permisos y Reglas',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () => _selectAll(menus),
                                    child: Text(
                                      'Seleccionar Todo',
                                      style: GoogleFonts.inter(color: const Color(0xFF4ECDC4), fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => _clearAll(menus),
                                    child: Text(
                                      'Limpiar',
                                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Search Filter inside Matrix Card
                          Container(
                            decoration: BoxDecoration(
                              color: themeColors.textPrimary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              onChanged: (val) {
                                setState(() {
                                  _menuSearchQuery = val;
                                });
                              },
                              style: GoogleFonts.inter(color: themeColors.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.search, color: themeColors.textSecondary, size: 18),
                                hintText: 'Buscar módulo o categoría...',
                                hintStyle: GoogleFonts.inter(color: themeColors.textSecondary, fontSize: 13),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Table Matrix Header
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: themeColors.textPrimary.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Módulo / Categoría',
                                    style: GoogleFonts.inter(color: themeColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                _buildHeaderCol('Ver'),
                                _buildHeaderCol('Crear'),
                                _buildHeaderCol('Editar'),
                                _buildHeaderCol('Borrar'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          menuProvider.isLoading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(40.0),
                                    child: CircularProgressIndicator(color: AppColors.primary),
                                  ),
                                )
                              : parentMenus.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(40.0),
                                        child: Text(
                                          'No hay módulos que coincidan.',
                                          style: GoogleFonts.inter(color: themeColors.textSecondary),
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: parentMenus.length,
                                      separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.03), height: 1),
                                      itemBuilder: (context, idx) {
                                        final parent = parentMenus[idx];
                                        final children = filteredMenus.where((m) => m.parentId == parent.id).toList();
                                        final hasChildren = children.isNotEmpty;
                                        final isExpanded = _expandedParents[parent.id] ?? true;

                                        return Column(
                                          children: [
                                            // Parent Row
                                            _buildMenuRow(
                                              menu: parent,
                                              isChild: false,
                                              hasChildren: hasChildren,
                                              isExpanded: isExpanded,
                                              onExpandToggle: () {
                                                setState(() {
                                                  _expandedParents[parent.id] = !isExpanded;
                                                });
                                              },
                                            ),
                                            // Children Rows
                                            if (hasChildren && isExpanded)
                                              ...children.map((child) => _buildMenuRow(
                                                    menu: child,
                                                    isChild: true,
                                                    hasChildren: false,
                                                    isExpanded: false,
                                                  )),
                                          ],
                                        );
                                      },
                                    ),
                          
                          const SizedBox(height: 16),
                          Divider(color: Colors.white.withOpacity(0.05)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_selectedPermissions.length} de ${menus.length * 4} permisos seleccionados',
                                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4ECDC4),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Autoguardado de borrador activo',
                                    style: GoogleFonts.inter(color: Colors.white30, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );

                    if (useTwoColumns) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: leftColumn),
                          const SizedBox(width: 24),
                          Expanded(flex: 3, child: rightColumn),
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

                // Bottom Buttons Bar
                Divider(color: Colors.white.withOpacity(0.05)),
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
                      isLoading: roleProvider.isLoading,
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

  Widget _buildHeaderCol(String label) {
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.inter(color: themeColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMenuRow({
    required MenuModel menu,
    required bool isChild,
    required bool hasChildren,
    required bool isExpanded,
    VoidCallback? onExpandToggle,
  }) {
    final themeColors = Theme.of(context).extension<AppThemeColors>() ?? AppTheme.darkThemeColors;
    final viewKey = '${menu.id}_1';
    final editKey = '${menu.id}_2';
    final createKey = '${menu.id}_3';
    final deleteKey = '${menu.id}_4';

    final hasView = _selectedPermissions.contains(viewKey);
    final hasEdit = _selectedPermissions.contains(editKey);
    final hasCreate = _selectedPermissions.contains(createKey);
    final hasDelete = _selectedPermissions.contains(deleteKey);

    return Padding(
      padding: EdgeInsets.only(
        left: isChild ? 24.0 : 8.0,
        right: 8.0,
        top: 8.0,
        bottom: 8.0,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (hasChildren)
                  IconButton(
                    icon: Icon(
                      isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                      color: themeColors.textSecondary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onExpandToggle,
                  )
                else if (!isChild)
                  const SizedBox(width: 20), // spacer to align with parent folder icon

                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menu.label,
                        style: GoogleFonts.inter(
                          color: themeColors.textPrimary,
                          fontWeight: isChild ? FontWeight.normal : FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        menu.route,
                        style: GoogleFonts.inter(
                          color: themeColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // View Checkbox (1)
          Expanded(
            child: Center(
              child: Checkbox(
                value: hasView,
                activeColor: AppColors.primary,
                onChanged: (val) => _toggleCascade(menu.id, 1, val ?? false),
              ),
            ),
          ),
          // Create Checkbox (3)
          Expanded(
            child: Center(
              child: Checkbox(
                value: hasCreate,
                activeColor: AppColors.accent,
                onChanged: (val) => _toggleCascade(menu.id, 3, val ?? false),
              ),
            ),
          ),
          // Edit Checkbox (2)
          Expanded(
            child: Center(
              child: Checkbox(
                value: hasEdit,
                activeColor: Colors.amber,
                onChanged: (val) => _toggleCascade(menu.id, 2, val ?? false),
              ),
            ),
          ),
          // Delete Checkbox (4)
          Expanded(
            child: Center(
              child: Checkbox(
                value: hasDelete,
                activeColor: AppColors.error,
                onChanged: (val) => _toggleCascade(menu.id, 4, val ?? false),
              ),
            ),
          ),
        ],
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
