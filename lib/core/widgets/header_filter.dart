import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

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
    if (_isSearchOpen || _controller.text.isNotEmpty) {
      return Container(
        width: 140,
        height: 32,
        child: TextField(
          controller: _controller,
          autofocus: true,
          style: GoogleFonts.inter(fontSize: 11, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Filtrar...',
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            filled: true,
            fillColor: Colors.white.withOpacity(0.04),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close_rounded, size: 12, color: Colors.white54),
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
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
          onChanged: widget.onChanged,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 6),
        IconButton(
          icon: Icon(
            Icons.search_rounded,
            size: 16,
            color: Colors.white.withOpacity(0.4),
          ),
          onPressed: () {
            setState(() {
              _isSearchOpen = true;
            });
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          hoverColor: Colors.white10,
          splashRadius: 16,
        ),
      ],
    );
  }
}
