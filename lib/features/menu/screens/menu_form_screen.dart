import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/menu_model.dart';
import '../providers/menu_provider.dart';

class MenuFormScreen extends StatefulWidget {
  final MenuModel? menu;

  const MenuFormScreen({super.key, this.menu});

  @override
  State<MenuFormScreen> createState() => _MenuFormScreenState();
}

class _MenuFormScreenState extends State<MenuFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;
  late TextEditingController _labelEnController;
  late TextEditingController _routeController;
  late TextEditingController _sortOrderController;
  late bool _isActive;
  String _selectedIcon = 'grid_view_rounded';
  int? _selectedParentId;

  bool get isEditing => widget.menu != null;

  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'people_rounded', 'icon': Icons.people_rounded},
    {'name': 'business_rounded', 'icon': Icons.business_rounded},
    {'name': 'admin_panel_settings_rounded', 'icon': Icons.admin_panel_settings_rounded},
    {'name': 'menu_rounded', 'icon': Icons.menu_rounded},
    {'name': 'grid_view_rounded', 'icon': Icons.grid_view_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.menu?.label ?? '');
    _labelEnController = TextEditingController(text: widget.menu?.labelEn ?? '');
    _routeController = TextEditingController(text: widget.menu?.route ?? '');
    _sortOrderController = TextEditingController(text: widget.menu?.sortOrder.toString() ?? '0');
    _isActive = widget.menu?.isActive ?? true;
    _selectedParentId = widget.menu?.parentId;
    if (widget.menu != null && widget.menu!.icon.isNotEmpty) {
      _selectedIcon = widget.menu!.icon;
    }

    // Load menus list so we can select parents
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().loadMenus();
    });
  }

  @override
  void dispose() {
    _labelController.dispose();
    _labelEnController.dispose();
    _routeController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final menuProvider = context.read<MenuProvider>();
    bool success;

    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;

    if (isEditing) {
      success = await menuProvider.updateMenu(
        widget.menu!.id,
        UpdateMenuRequest(
          label: _labelController.text.trim(),
          labelEn: _labelEnController.text.trim(),
          route: _routeController.text.trim(),
          icon: _selectedIcon,
          sortOrder: sortOrder,
          isActive: _isActive,
          parentId: _selectedParentId ?? 0,
        ),
      );
    } else {
      success = await menuProvider.createMenu(
        CreateMenuRequest(
          label: _labelController.text.trim(),
          labelEn: _labelEnController.text.trim(),
          route: _routeController.text.trim(),
          icon: _selectedIcon,
          sortOrder: sortOrder,
          parentId: _selectedParentId,
        ),
      );
    }

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      final error = menuProvider.errorMessage ?? 'Ocurrió un error';
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
          isEditing ? 'Editar Menú' : 'Nuevo Menú',
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
                      isEditing ? Icons.edit_note_rounded : Icons.add_to_queue_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                _buildLabel('Etiqueta (Español)'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _labelController,
                  hint: 'Ej: Facturación, Configuración',
                  icon: Icons.label_important_outline_rounded,
                  validator: (v) => (v == null || v.isEmpty) ? 'La etiqueta en español es requerida' : null,
                ),
                const SizedBox(height: 20),

                _buildLabel('Etiqueta (Inglés)'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _labelEnController,
                  hint: 'Ej: Billing, Settings',
                  icon: Icons.translate_rounded,
                  validator: (v) => (v == null || v.isEmpty) ? 'La etiqueta en inglés es requerida' : null,
                ),
                const SizedBox(height: 20),

                _buildLabel('Ruta de Enlace (Frontend Route)'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _routeController,
                  hint: 'Ej: /billing, /settings',
                  icon: Icons.link_rounded,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'La ruta es requerida';
                    if (!v.startsWith('/')) return 'La ruta debe empezar con /';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _buildLabel('Orden de Visualización'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _sortOrderController,
                  hint: 'Ej: 1, 2, 3',
                  icon: Icons.sort_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? 'El orden es requerido' : null,
                ),
                const SizedBox(height: 20),

                _buildLabel('Seleccionar Ícono'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedIcon,
                      dropdownColor: const Color(0xFF1E1E2E),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                      isExpanded: true,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedIcon = val);
                        }
                      },
                      items: _availableIcons.map((i) {
                        return DropdownMenuItem<String>(
                          value: i['name'],
                          child: Row(
                            children: [
                              Icon(i['icon'], color: const Color(0xFF4ECDC4), size: 20),
                              const SizedBox(width: 14),
                              Text(i['name']),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _buildLabel('Menú Padre (Opcional)'),
                const SizedBox(height: 8),
                Consumer<MenuProvider>(
                  builder: (context, provider, _) {
                    final menuOptions = provider.menus.where((m) {
                      // Exclude itself in edit mode to avoid self-reference loop
                      if (isEditing && m.id == widget.menu!.id) return false;
                      // Only allow top-level menus to be parents (to keep hierarchy at 1 level parent-child)
                      return m.parentId == null;
                    }).toList();

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: _selectedParentId,
                          hint: Text('Ninguno (Menú Principal)', style: GoogleFonts.inter(color: Colors.white30, fontSize: 14)),
                          dropdownColor: const Color(0xFF1E1E2E),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                          isExpanded: true,
                          onChanged: (val) {
                            setState(() => _selectedParentId = val);
                          },
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Ninguno (Menú Principal)', style: GoogleFonts.inter(color: Colors.white54)),
                            ),
                            ...menuOptions.map((m) {
                              return DropdownMenuItem<int?>(
                                value: m.id,
                                child: Text(m.label),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                if (isEditing) ...[
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
                              'Menú activo',
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
                  const SizedBox(height: 32),
                ] else
                  const SizedBox(height: 12),

                Consumer<MenuProvider>(
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
                                isEditing ? 'Guardar Cambios' : 'Crear Menú',
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
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.3), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
