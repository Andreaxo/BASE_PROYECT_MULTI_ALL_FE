import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class HeaderFilter extends StatefulWidget {
  final String title;
  final ValueChanged<String> onChanged;

  const HeaderFilter({
    super.key,
    required this.title,
    required this.onChanged,
  });

  @override
  State<HeaderFilter> createState() => _HeaderFilterState();
}

class _HeaderFilterState extends State<HeaderFilter> {
  bool _isSearchOpen = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppTheme.darkThemeColors;

    if (_isSearchOpen || _controller.text.isNotEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 140,
          height: 32,
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: GoogleFonts.inter(fontSize: 11, color: themeColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Filtrar...',
              hintStyle: TextStyle(
                color: themeColors.textSecondary.withValues(alpha: 0.5),
                fontSize: 11,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              filled: true,
              fillColor: themeColors.textPrimary.withValues(alpha: 0.05),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 12,
                  color: themeColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _controller.clear();
                    _isSearchOpen = false;
                  });
                  widget.onChanged('');
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: themeColors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            onChanged: widget.onChanged,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeColors.tableHeaderFg,
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          icon: Icon(
            Icons.search_rounded,
            size: 16,
            color: themeColors.textSecondary.withValues(alpha: 0.7),
          ),
          onPressed: () {
            setState(() {
              _isSearchOpen = true;
            });
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          hoverColor: themeColors.textPrimary.withValues(alpha: 0.06),
          splashRadius: 16,
        ),
      ],
    );
  }
}
