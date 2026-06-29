import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color cardBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final List<Color> gradientBg;
  final Color sidebarBg;

  AppThemeColors({
    required this.cardBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.gradientBg,
    required this.sidebarBg,
  });

  @override
  AppThemeColors copyWith({
    Color? cardBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? borderColor,
    List<Color>? gradientBg,
    Color? sidebarBg,
  }) {
    return AppThemeColors(
      cardBackground: cardBackground ?? this.cardBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      borderColor: borderColor ?? this.borderColor,
      gradientBg: gradientBg ?? this.gradientBg,
      sidebarBg: sidebarBg ?? this.sidebarBg,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      gradientBg: t < 0.5 ? gradientBg : other.gradientBg,
      sidebarBg: Color.lerp(sidebarBg, other.sidebarBg, t)!,
    );
  }
}

class AppTheme {
  static final darkThemeColors = AppThemeColors(
    cardBackground: const Color(0xFF131129),
    textPrimary: Colors.white,
    textSecondary: Colors.white54,
    borderColor: Colors.white.withOpacity(0.08),
    gradientBg: const [Color(0xFF0F0C29), Color(0xFF1A1A2E)],
    sidebarBg: const Color.fromARGB(111, 4, 47, 71), // AppColors.cardBg equivalent
  );

  static final lightThemeColors = AppThemeColors(
    cardBackground: Colors.white,
    textPrimary: const Color(0xFF1E1E2E),
    textSecondary: const Color(0xFF5A5A7A),
    borderColor: const Color(0xFFE2E8F0),
    gradientBg: const [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
    sidebarBg: const Color(0xFFF8FAFC),
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF6C63FF),
      scaffoldBackgroundColor: const Color(0xFF0F0C29),
      cardColor: const Color(0xFF131129),
      dividerColor: Colors.white.withOpacity(0.08),
      colorScheme: const ColorScheme.dark(
        primary: Color.fromARGB(255, 7, 3, 90),
        secondary: Color.fromARGB(134, 8, 153, 143),
        surface: Color(0xFF1E1E2E),
        background: Color(0xFF0F0C29),
        error: Color.fromARGB(255, 218, 97, 97),
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ),
      extensions: [darkThemeColors],
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFF6C63FF),
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE2E8F0),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6C63FF),
        secondary: Color(0xFF4ECDC4),
        surface: Colors.white,
        background: Color(0xFFF1F5F9),
        error: Color(0xFFFF6B6B),
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme,
      ),
      extensions: [lightThemeColors],
    );
  }
}
