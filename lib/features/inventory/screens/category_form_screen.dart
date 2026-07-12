import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/outline_button.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/custom_alert.dart';
import '../../../core/theme/app_theme.dart';
import '../models/category_model.dart';
import '../providers/category_provider.dart';

class CategoryFormScreen extends StatefulWidget {
  final Category? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late bool _isActive;

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _isActive = widget.category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<CategoryProvider>();
    bool success;

    if (isEditing) {
      success = await provider.updateCategory(
        widget.category!.id,
        UpdateCategoryRequest(
          name: _nameController.text.trim(),
          isActive: _isActive,
        ),
      );
    } else {
      success = await provider.createCategory(
        CreateCategoryRequest(
          name: _nameController.text.trim(),
        ),
      );
    }

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      final error = provider.errorMessage ?? context.tr('error_occurred');
      CustomAlert.show(
        context,
        message: error,
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
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
          context.tr('category_list_title'),
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
                    // Title and status switcher
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing ? context.tr('edit_category') : context.tr('add_category'),
                                style: GoogleFonts.outfit(
                                  color: themeColors.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Defina el nombre y el estado para clasificar los artículos de inventario.',
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

                    // Main card container
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
                                isEditing ? Icons.edit_note_rounded : Icons.add_to_queue_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildLabel(context.tr('category_name_label')),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _nameController,
                            hint: context.tr('category_name_hint'),
                            icon: Icons.label_important_outline_rounded,
                            validator: (v) => (v == null || v.isEmpty) ? context.tr('category_name_required') : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Info note
                    InfoCard(
                      title: 'Organización de Inventario',
                      content: 'El nombre de la categoría debe ser descriptivo. Esto facilitará a los administradores y gestores agrupar y filtrar artículos correspondientes al inventario.',
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
                          isLoading: provider.isLoading,
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
