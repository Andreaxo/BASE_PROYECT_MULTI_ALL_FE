import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/outline_button.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/theme/app_theme.dart';
import '../models/article_model.dart';
import '../providers/article_provider.dart';
import '../providers/category_provider.dart';

class ArticleFormScreen extends StatefulWidget {
  final Article? article;

  const ArticleFormScreen({super.key, this.article});

  @override
  State<ArticleFormScreen> createState() => _ArticleFormScreenState();
}

class _ArticleFormScreenState extends State<ArticleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  int? _selectedCategoryId;

  bool get isEditing => widget.article != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.article?.name ?? '');
    _selectedCategoryId = widget.article?.categoryId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('please_select_category'), style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFFFF6B6B),
        ),
      );
      return;
    }

    final provider = context.read<ArticleProvider>();
    bool success;

    if (isEditing) {
      success = await provider.updateArticle(
        widget.article!.id,
        UpdateArticleRequest(
          categoryId: _selectedCategoryId,
          name: _nameController.text.trim(),
        ),
      );
    } else {
      success = await provider.createArticle(
        CreateArticleRequest(
          categoryId: _selectedCategoryId!,
          name: _nameController.text.trim(),
        ),
      );
    }

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      final error = provider.errorMessage ?? context.tr('error_occurred');
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
    final categoryProvider = context.watch<CategoryProvider>();
    final articleProvider = context.watch<ArticleProvider>();
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
          context.tr('article_list_title'),
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
                    // Title and Description
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? context.tr('edit_article') : context.tr('add_article'),
                          style: GoogleFonts.outfit(
                            color: themeColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Configure las propiedades, categoría vinculada e información general del artículo.',
                          style: GoogleFonts.inter(
                            color: themeColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Main Form Card
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
                              child: const Icon(
                                Icons.inventory_2_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildLabel(context.tr('article_name_label')),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _nameController,
                            hint: context.tr('article_name_hint'),
                            icon: Icons.label_important_outline_rounded,
                            validator: (v) => (v == null || v.isEmpty) ? context.tr('article_name_required') : null,
                          ),
                          const SizedBox(height: 20),

                          _buildLabel(context.tr('related_category_label')),
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
                                value: _selectedCategoryId,
                                hint: Text(context.tr('select_category_hint'), style: GoogleFonts.inter(color: Colors.white30, fontSize: 14)),
                                dropdownColor: const Color(0xFF1E1E2E),
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                                isExpanded: true,
                                onChanged: (val) {
                                  setState(() => _selectedCategoryId = val);
                                },
                                items: categoryProvider.categories.map((c) {
                                  return DropdownMenuItem<int>(
                                    value: c.id,
                                    child: Text(c.name),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Info Card Note
                    InfoCard(
                      title: 'Asociación del Producto',
                      content: 'Vincular el artículo a una categoría existente facilitará a los administradores la categorización y consulta de su catálogo de inventario.',
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
                          isLoading: articleProvider.isLoading,
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
