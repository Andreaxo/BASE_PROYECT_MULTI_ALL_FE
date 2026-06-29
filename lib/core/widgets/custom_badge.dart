import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const CustomBadge({
    super.key,
    required this.label,
    this.backgroundColor = const Color(0xFF2A245C),
    this.textColor = const Color(0xFFB5A6FF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
