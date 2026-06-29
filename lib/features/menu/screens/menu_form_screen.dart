import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/outline_button.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/theme/app_theme.dart';
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
  late TextEditingController _labelFrController;
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
    {'name': 'inventory_2_rounded', 'icon': Icons.inventory_2_rounded},
    {'name': 'category_rounded', 'icon': Icons.category_rounded},
    {'name': 'inventory_rounded', 'icon': Icons.inventory_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.menu?.label ?? '');
    _labelEnController = TextEditingController(text: widget.menu?.labelEn ?? '');
    _labelFrController = TextEditingController(text: widget.menu?.labelFr ?? '');
    _routeController = TextEditingController(text: widget.menu?.route ?? '');
    _sortOrderController = TextEditingController(text: widget.menu?.sortOrder.toString() ?? '0');
    _isActive = widget.menu?.isActive ?? true;
    _selectedParentId = widget.menu?.parentId;
    if (widget.menu != null && widget.menu!.icon.isNotEmpty) {
      _selectedIcon = widget.menu!.icon;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().loadMenus();
    });
  }

  @override
  void dispose() {
    _labelController.dispose();
    _labelEnController.dispose();
    _labelFrController.dispose();
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
          labelFr: _labelFrController.text.trim(),
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
          labelFr: _labelFrController.text.trim(),
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
    final menuProvider = context.watch<MenuProvider>();
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
          'Menús',
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
                // Title and Status switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Editar Menú' : 'Nuevo Menú',
                            style: GoogleFonts.outfit(
                              color: themeColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Configure las propiedades básicas de visibilidad y acceso para este menú.',
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
                        // Card Info Básica
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
                                'Información del Menú',
                                style: GoogleFonts.outfit(
                                  color: themeColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),

                              _buildLabel('Etiqueta (Español)'),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: _labelController,
                                hint: 'Ej: Artículos',
                                icon: Icons.label_outline_rounded,
                                validator: (v) => (v == null || v.isEmpty) ? 'La etiqueta en español es requerida' : null,
                              ),
                              const SizedBox(height: 20),

                              _buildLabel('Etiqueta (Inglés)'),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: _labelEnController,
                                hint: 'Ej: Items',
                                icon: Icons.language_rounded,
                                validator: (v) => (v == null || v.isEmpty) ? 'La etiqueta en inglés es requerida' : null,
                              ),
                              const SizedBox(height: 20),

                              _buildLabel('Etiqueta (Francés)'),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: _labelFrController,
                                hint: 'Ej: Articles',
                                icon: Icons.language_rounded,
                                validator: (v) => (v == null || v.isEmpty) ? 'La etiqueta en francés es requerida' : null,
                              ),
                              const SizedBox(height: 20),

                              _buildLabel('Ruta de Navegación'),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: _routeController,
                                hint: 'Ej: /items',
                                icon: Icons.route_outlined,
                                validator: (v) => (v == null || v.isEmpty) ? 'La ruta es requerida' : null,
                              ),
                              const SizedBox(height: 20),

                              _buildLabel('Orden de visualización'),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: _sortOrderController,
                                hint: 'Ej: 10',
                                icon: Icons.sort_rounded,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        InfoCard(
                          title: 'Uso de Rutas',
                          content: 'Las rutas enlazan directamente a componentes definidos en el enrutador de la aplicación cliente Flutter.',
                          icon: Icons.link_rounded,
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
                          Text(
                            'Propiedades de Jerarquía e Ícono',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildLabel('Menú Padre'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _selectedParentId,
                                hint: Text('Ninguno (Menú Raíz)', style: GoogleFonts.inter(color: Colors.white30, fontSize: 14)),
                                dropdownColor: const Color(0xFF1E1E2E),
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                                isExpanded: true,
                                onChanged: (val) {
                                  setState(() => _selectedParentId = val);
                                },
                                items: [
                                  const DropdownMenuItem<int>(
                                    value: null,
                                    child: Text('Ninguno (Menú Raíz)'),
                                  ),
                                  ...menuProvider.menus.where((m) => m.parentId == null && m.id != widget.menu?.id).map((m) {
                                    return DropdownMenuItem<int>(
                                      value: m.id,
                                      child: Text(m.label),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildLabel('Selecciona un Ícono'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _availableIcons.map((i) {
                              final isSelected = _selectedIcon == i['name'];
                              return GestureDetector(
                                onTap: () => setState(() => _selectedIcon = i['name']),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.2) : Colors.white.withOpacity(0.04),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF4ECDC4) : Colors.white.withOpacity(0.08),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    i['icon'] as IconData,
                                    color: isSelected ? const Color(0xFF4ECDC4) : Colors.white70,
                                    size: 24,
                                  ),
                                ),
                              );
                            }).toList(),
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

                // Action buttons
                Divider(color: Theme.of(context).extension<AppThemeColors>()?.borderColor ?? Colors.white.withOpacity(0.05)),
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
                      isLoading: menuProvider.isLoading,
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
