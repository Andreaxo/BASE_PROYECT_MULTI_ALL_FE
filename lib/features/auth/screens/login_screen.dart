import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../providers/auth_provider.dart';

/// Modern login screen with gradient background and glassmorphism card.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/users');
    }
  }

  Widget _buildLoginFormCard(BuildContext context, Size size, ThemeProvider themeProvider) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          width: size.width > 450 ? 420 : double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: themeProvider.isDarkMode
                  ? Colors.white.withOpacity(0.15)
                  : Colors.black.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.accent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  context.tr('login_title'),
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('login_subtitle'),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: themeProvider.isDarkMode ? Colors.white.withOpacity(0.6) : Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),

                // Error message
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.errorMessage == null) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFFF6B6B),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              auth.errorMessage!,
                              style: GoogleFonts.inter(
                                color: const Color(0xFFFF6B6B),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Email field
                _buildTextField(
                  themeProvider: themeProvider,
                  controller: _emailController,
                  label: context.tr('email'),
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('email_required');
                    }
                    if (!value.contains('@')) {
                      return context.tr('invalid_email');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                _buildTextField(
                  themeProvider: themeProvider,
                  controller: _passwordController,
                  label: context.tr('password'),
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: themeProvider.isDarkMode
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black.withOpacity(0.4),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.tr('password_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Login button
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.primary.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                context.tr('login_button'),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: themeProvider.isDarkMode
                ? [
                    AppColors.bgGradStart,
                    AppColors.bgGradMid,
                    AppColors.bgGradEnd,
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFF1F5F9),
                    const Color(0xFFE2E8F0),
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              isDesktop
                  ? Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: _buildLoginFormCard(context, size, themeProvider),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              border: Border(
                                left: BorderSide(
                                  color: themeProvider.isDarkMode
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.05),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: ClipRRect(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topRight,
                                        end: Alignment.bottomLeft,
                                        colors: themeProvider.isDarkMode
                                            ? [
                                                AppColors.primary,
                                                const Color(0xFF0F172A),
                                              ]
                                            : [
                                                AppColors.primary.withOpacity(0.8),
                                                const Color(0xFFCBD5E1),
                                              ],
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: themeProvider.isDarkMode
                                                ? Colors.white.withOpacity(0.05)
                                                : Colors.white.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: themeProvider.isDarkMode
                                                  ? Colors.white.withOpacity(0.1)
                                                  : Colors.black.withOpacity(0.05),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.hub_rounded,
                                            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                                            size: 80,
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                        Text(
                                          'BASE MULTICLIENTE',
                                          style: GoogleFonts.outfit(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 48.0),
                                          child: Text(
                                            'Gestiona múltiples empresas, inventarios y catálogos de manera centralizada, segura y eficiente.',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              color: themeProvider.isDarkMode
                                                  ? Colors.white.withOpacity(0.7)
                                                  : Colors.black54,
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildLoginFormCard(context, size, themeProvider),
                      ),
                    ),
              
              // Top Right Switchers (Language and Theme)
              Positioned(
                top: 16,
                right: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Language Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: themeProvider.isDarkMode
                              ? Colors.white.withOpacity(0.15)
                              : Colors.black.withOpacity(0.08),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: languageProvider.currentLanguageCode,
                          dropdownColor: themeProvider.isDarkMode
                              ? const Color(0xFF1E1E2E)
                              : Colors.white,
                          icon: Icon(
                            Icons.language_rounded,
                            color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                            size: 18,
                          ),
                          style: GoogleFonts.inter(
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          onChanged: (lang) {
                            if (lang != null) {
                              languageProvider.setLanguage(lang);
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'es', child: Text('  ES  ')),
                            DropdownMenuItem(value: 'en', child: Text('  EN  ')),
                            DropdownMenuItem(value: 'fr', child: Text('  FR  ')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Theme toggle button
                    Container(
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: themeProvider.isDarkMode
                              ? Colors.white.withOpacity(0.15)
                              : Colors.black.withOpacity(0.08),
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          themeProvider.isDarkMode
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: themeProvider.isDarkMode ? Colors.yellow : Colors.indigo,
                          size: 20,
                        ),
                        onPressed: () => themeProvider.toggleTheme(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required ThemeProvider themeProvider,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final textColor = themeProvider.isDarkMode ? Colors.white : Colors.black87;
    final labelColor = themeProvider.isDarkMode ? Colors.white.withOpacity(0.5) : Colors.black45;
    final fillColor = themeProvider.isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04);
    final borderColor = themeProvider.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: GoogleFonts.inter(color: textColor, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: labelColor,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: labelColor, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: GoogleFonts.inter(color: AppColors.error),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
