import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double? width;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.height = 50,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final hasCallback = onPressed != null && !isLoading;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: hasCallback
            ? const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
              )
            : null,
        color: !hasCallback ? Colors.white.withOpacity(0.05) : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: hasCallback
            ? [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: hasCallback ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: hasCallback ? Colors.white : Colors.white24,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
