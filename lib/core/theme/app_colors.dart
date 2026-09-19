import 'package:flutter/material.dart';

/// Centralized application color palette definitions.
/// Edit these values to rebrand the application for other clients.
class AppColors {
  // Brand Palette
  static const Color primary = Color.fromARGB(
    255,
    78,
    168,
    219,
  ); // Color inicial del lado derecho
  static const Color accent = Color(0xFF4ECDC4);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFFF6B6B);

  // Backgrounds & Surfaces
  static const Color bgGradStart = Color.fromARGB(
    255,
    83,
    136,
    136,
  ); //Colores del gradiente del lado izquierdo
  static const Color bgGradMid = Color.fromARGB(255, 10, 67, 141);
  static const Color bgGradEnd = Color.fromARGB(255, 142, 175, 197);

  // Mezcla de transición entre el fondo izquierdo (bgGradMid) y el azul derecho (primary)
  static const Color bgGradBlend = Color.fromARGB(255, 44, 117, 180);
  static const Color cardBg = Color.fromARGB(111, 4, 47, 71);
  static const Color dialogBg = Color.fromARGB(255, 2, 23, 70);
  static const Color tableHeaderBg = Color(0xFF181530);

  // Borders & Dividers
  static const Color border = Color(0xFF2B264B);
}
