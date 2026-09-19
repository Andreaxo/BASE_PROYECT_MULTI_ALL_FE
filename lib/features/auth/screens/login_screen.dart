import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/custom_alert.dart';
import '../../referidos/providers/referido_provider.dart';
import '../../rifas/providers/rifa_provider.dart';
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
  final _passwordFocusNode = FocusNode();
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
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      context.read<ReferidoProvider>().resetSilent();
      context.read<RifaProvider>().resetSilent();
      final role = authProvider.roleCode;
      if (role == 'business_validator' || role == 'negocio') {
        Navigator.of(context).pushReplacementNamed('/business-home');
      } else if (role == 'user' || role == 'user_member') {
        Navigator.of(context).pushReplacementNamed('/referidos');
      } else {
        Navigator.of(context).pushReplacementNamed('/users');
      }
    }
  }

  Widget _buildLoginFormCard(
    BuildContext context,
    Size size,
    ThemeProvider themeProvider,
  ) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          width: size.width > 450 ? 420 : double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: themeProvider.isDarkMode
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: themeProvider.isDarkMode ? 0.3 : 0.1,
                ),
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
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
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
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('login_subtitle'),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: themeProvider.isDarkMode
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black54,
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
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
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
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_passwordFocusNode);
                  },
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
                  focusNode: _passwordFocusNode,
                  label: context.tr('password'),
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: themeProvider.isDarkMode
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.4),
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
                          disabledBackgroundColor: AppColors.primary.withValues(
                            alpha: 0.5,
                          ),
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
                const SizedBox(height: 20),

                // Register with referral code link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.tr('have_code'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: themeProvider.isDarkMode
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.black54,
                      ),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _showRegisterDialog,
                        child: Text(
                          context.tr('register_with_referral'),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRegisterDialog() {
    final formKey = GlobalKey<FormState>();
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final refCodeCtrl = TextEditingController();
    final companyCodeCtrl = TextEditingController();
    bool isLoading = false;
    String? dialogError;
    bool obscurePassword = true;
    String? validatedCompanyName;
    bool isValidatingCompany = false;
    String? companyValidationError;
    String referralType = 'none'; // 'friend', 'company', 'none'

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) {
        final themeProvider = ctx.watch<ThemeProvider>();
        final themeColors =
            Theme.of(ctx).extension<AppThemeColors>() ??
            AppTheme.darkThemeColors;
        final isDark = themeProvider.isDarkMode;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void onCompanyCodeChanged(String value) async {
              final code = value.trim();
              if (code.isEmpty) {
                setDialogState(() {
                  validatedCompanyName = null;
                  isValidatingCompany = false;
                  companyValidationError = null;
                });
                return;
              }

              setDialogState(() {
                isValidatingCompany = true;
                companyValidationError = null;
              });

              final res = await context
                  .read<AuthProvider>()
                  .validarCodigoEmpresa(code);

              setDialogState(() {
                isValidatingCompany = false;
                if (res != null && res['name'] != null) {
                  validatedCompanyName = res['name'];
                  companyValidationError = null;
                } else {
                  validatedCompanyName = null;
                  companyValidationError = 'Código de empresa no válido';
                }
              });
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Container(
                  decoration: BoxDecoration(
                    color: themeColors.cardBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 40,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Header con gradiente ──────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: const Icon(
                                Icons.person_add_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Crear Cuenta',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Únete y disfruta beneficios exclusivos',
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: isLoading
                                  ? null
                                  : () => Navigator.of(ctx).pop(),
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Body del formulario ────────────────────────────
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Error banner
                                if (dialogError != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.error.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline_rounded,
                                          color: AppColors.error,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            dialogError!,
                                            style: GoogleFonts.inter(
                                              color: AppColors.error,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Nombre y Apellido en fila
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        themeProvider: themeProvider,
                                        controller: firstNameCtrl,
                                        label: 'Nombre',
                                        icon: Icons.badge_outlined,
                                        validator: (v) =>
                                            v == null || v.trim().isEmpty
                                                ? 'Requerido'
                                                : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildTextField(
                                        themeProvider: themeProvider,
                                        controller: lastNameCtrl,
                                        label: 'Apellido',
                                        icon: Icons.badge_outlined,
                                        validator: (v) =>
                                            v == null || v.trim().isEmpty
                                                ? 'Requerido'
                                                : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Correo
                                _buildTextField(
                                  themeProvider: themeProvider,
                                  controller: emailCtrl,
                                  label: 'Correo electrónico',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return 'Ingresa tu correo';
                                    if (!v.contains('@'))
                                      return 'Correo no válido';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),

                                // Contraseña
                                _buildTextField(
                                  themeProvider: themeProvider,
                                  controller: passwordCtrl,
                                  label: 'Contraseña',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.4)
                                          : Colors.black38,
                                    ),
                                    onPressed: () => setDialogState(
                                      () => obscurePassword = !obscurePassword,
                                    ),
                                  ),
                                  validator: (v) => v == null || v.length < 6
                                      ? 'Mínimo 6 caracteres'
                                      : null,
                                ),
                                const SizedBox(height: 20),

                                const SizedBox(height: 20),

                                // ── Selector de Tipo de Invitación ──
                                Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.1)
                                            : Colors.black.withValues(alpha: 0.08),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        '¿Tienes un código de invitación? (Opcional)',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.1)
                                            : Colors.black.withValues(alpha: 0.08),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // 3 Opciones Segmentadas: Amigo / Empresa / Ninguno
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          setDialogState(() {
                                            referralType = 'friend';
                                            companyCodeCtrl.clear();
                                            validatedCompanyName = null;
                                            companyValidationError = null;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                          decoration: BoxDecoration(
                                            color: referralType == 'friend'
                                                ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15)
                                                : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: referralType == 'friend'
                                                  ? AppColors.accent
                                                  : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
                                              width: referralType == 'friend' ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.person_pin_rounded,
                                                size: 20,
                                                color: referralType == 'friend'
                                                    ? AppColors.accent
                                                    : (isDark ? Colors.white60 : Colors.black54),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Amigo Afiliado',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: referralType == 'friend' ? FontWeight.bold : FontWeight.w500,
                                                  color: referralType == 'friend'
                                                      ? (isDark ? Colors.white : AppColors.primary)
                                                      : (isDark ? Colors.white70 : Colors.black87),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          setDialogState(() {
                                            referralType = 'company';
                                            refCodeCtrl.clear();
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                          decoration: BoxDecoration(
                                            color: referralType == 'company'
                                                ? const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.25 : 0.15)
                                                : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: referralType == 'company'
                                                  ? const Color(0xFF06B6D4)
                                                  : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
                                              width: referralType == 'company' ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.business_rounded,
                                                size: 20,
                                                color: referralType == 'company'
                                                    ? const Color(0xFF06B6D4)
                                                    : (isDark ? Colors.white60 : Colors.black54),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Empresa Aliada',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: referralType == 'company' ? FontWeight.bold : FontWeight.w500,
                                                  color: referralType == 'company'
                                                      ? (isDark ? Colors.white : const Color(0xFF3B82F6))
                                                      : (isDark ? Colors.white70 : Colors.black87),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          setDialogState(() {
                                            referralType = 'none';
                                            refCodeCtrl.clear();
                                            companyCodeCtrl.clear();
                                            validatedCompanyName = null;
                                            companyValidationError = null;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                          decoration: BoxDecoration(
                                            color: referralType == 'none'
                                                ? Colors.grey.withValues(alpha: isDark ? 0.25 : 0.15)
                                                : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: referralType == 'none'
                                                  ? Colors.grey
                                                  : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
                                              width: referralType == 'none' ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.remove_circle_outline_rounded,
                                                size: 20,
                                                color: referralType == 'none'
                                                    ? Colors.grey
                                                    : (isDark ? Colors.white60 : Colors.black54),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Sin Código',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: referralType == 'none' ? FontWeight.bold : FontWeight.w500,
                                                  color: referralType == 'none'
                                                      ? (isDark ? Colors.white : Colors.black87)
                                                      : (isDark ? Colors.white70 : Colors.black87),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // ── Campo Dinámico Según Selección ──
                                if (referralType == 'friend') ...[
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
                                          AppColors.accent.withValues(alpha: isDark ? 0.08 : 0.04),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: _buildTextField(
                                      themeProvider: themeProvider,
                                      controller: refCodeCtrl,
                                      label: 'Código de Referido de tu Amigo (Ej: AFIL001)',
                                      icon: Icons.confirmation_number_outlined,
                                      textCapitalization: TextCapitalization.characters,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Text(
                                      'Tu amigo recibirá la comisión de referido al activar tu membresía.',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black54,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ] else if (referralType == 'company') ...[
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.12 : 0.06),
                                          const Color(0xFF06B6D4).withValues(alpha: isDark ? 0.08 : 0.04),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: validatedCompanyName != null
                                            ? AppColors.success
                                            : (companyValidationError != null
                                                ? AppColors.error
                                                : const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                                        width: validatedCompanyName != null ? 1.5 : 1,
                                      ),
                                    ),
                                    child: _buildTextField(
                                      themeProvider: themeProvider,
                                      controller: companyCodeCtrl,
                                      label: 'Código de Empresa Aliada',
                                      icon: Icons.business_rounded,
                                      textCapitalization: TextCapitalization.characters,
                                      onChanged: onCompanyCodeChanged,
                                      suffixIcon: isValidatingCompany
                                          ? const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            )
                                          : (validatedCompanyName != null
                                              ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22)
                                              : (companyValidationError != null
                                                  ? const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22)
                                                  : null)),
                                    ),
                                  ),
                                  if (validatedCompanyName != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.verified_rounded, color: AppColors.success, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Te vas a afiliar a: $validatedCompanyName ✅',
                                              style: GoogleFonts.inter(
                                                color: AppColors.success,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else if (companyValidationError != null) ...[
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Text(
                                        companyValidationError!,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],

                                const SizedBox(height: 24),

                                // Botón registrarse
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.accent,
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.35,
                                          ),
                                          blurRadius: 14,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: isLoading
                                          ? null
                                          : () async {
                                              if (!formKey.currentState!
                                                  .validate())
                                                return;
                                              setDialogState(() {
                                                isLoading = true;
                                                dialogError = null;
                                              });

                                              final authProvider = context
                                                  .read<AuthProvider>();
                                              final finalRefCode = referralType == 'friend' && refCodeCtrl.text.trim().isNotEmpty
                                                  ? refCodeCtrl.text.trim()
                                                  : null;
                                              final finalCompanyCode = referralType == 'company' && companyCodeCtrl.text.trim().isNotEmpty
                                                  ? companyCodeCtrl.text.trim()
                                                  : null;

                                              final success = await authProvider
                                                  .register(
                                                    email: emailCtrl.text.trim(),
                                                    password: passwordCtrl.text,
                                                    firstName: firstNameCtrl.text.trim(),
                                                    lastName: lastNameCtrl.text.trim(),
                                                    refCode: finalRefCode,
                                                    codigoEmpresa: finalCompanyCode,
                                                  );

                                              if (success) {
                                                if (ctx.mounted)
                                                  Navigator.of(ctx).pop();
                                                if (mounted) {
                                                  context
                                                      .read<ReferidoProvider>()
                                                      .resetSilent();
                                                  context
                                                      .read<RifaProvider>()
                                                      .resetSilent();
                                                  CustomAlert.show(
                                                    context,
                                                    message:
                                                        '¡Registro exitoso! Bienvenido a Conexiate.',
                                                    isSuccess: true,
                                                  );
                                                  final role =
                                                      authProvider.roleCode;
                                                  if (role == 'user' ||
                                                      role == 'user_member') {
                                                    Navigator.of(
                                                      context,
                                                    ).pushReplacementNamed(
                                                      '/referidos',
                                                    );
                                                  } else {
                                                    Navigator.of(
                                                      context,
                                                    ).pushReplacementNamed(
                                                      '/users',
                                                    );
                                                  }
                                                }
                                              } else {
                                                setDialogState(() {
                                                  isLoading = false;
                                                  dialogError =
                                                      authProvider.errorMessage ??
                                                      'Error al registrar usuario';
                                                });
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.person_add_rounded,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  'Crear mi cuenta',
                                                  style: GoogleFonts.inter(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: _buildLoginFormCard(
                                context,
                                size,
                                themeProvider,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              border: Border(
                                left: BorderSide(
                                  color: themeProvider.isDarkMode
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.05),
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
                                                AppColors.primary.withValues(
                                                  alpha: 0.8,
                                                ),
                                                const Color(0xFFCBD5E1),
                                              ],
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: themeProvider.isDarkMode
                                                ? Colors.white.withValues(
                                                    alpha: 0.05,
                                                  )
                                                : Colors.white.withValues(
                                                    alpha: 0.2,
                                                  ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: themeProvider.isDarkMode
                                                  ? Colors.white.withValues(
                                                      alpha: 0.1,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.05,
                                                    ),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.hub_rounded,
                                            color: themeProvider.isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                            size: 80,
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                        Text(
                                          context.tr('welcome_title'),
                                          style: GoogleFonts.outfit(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: themeProvider.isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 48.0,
                                          ),
                                          child: Text(
                                            context.tr('welcome_subtitle'),
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              color: themeProvider.isDarkMode
                                                  ? Colors.white.withValues(
                                                      alpha: 0.7,
                                                    )
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
                        child: _buildLoginFormCard(
                          context,
                          size,
                          themeProvider,
                        ),
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
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: themeProvider.isDarkMode
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.08),
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
                            color: themeProvider.isDarkMode
                                ? Colors.white70
                                : Colors.black87,
                            size: 18,
                          ),
                          style: GoogleFonts.inter(
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          onChanged: (lang) {
                            if (lang != null) {
                              languageProvider.setLanguage(lang);
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'es',
                              child: Text('  ES  '),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('  EN  '),
                            ),
                            DropdownMenuItem(
                              value: 'fr',
                              child: Text('  FR  '),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Theme toggle button
                    Container(
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: themeProvider.isDarkMode
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          themeProvider.isDarkMode
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: themeProvider.isDarkMode
                              ? Colors.yellow
                              : const Color.fromARGB(255, 78, 147, 212),
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
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final textColor = themeProvider.isDarkMode ? Colors.white : Colors.black87;
    final labelColor = themeProvider.isDarkMode
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black45;
    final fillColor = themeProvider.isDarkMode
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final borderColor = themeProvider.isDarkMode
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      style: GoogleFonts.inter(color: textColor, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: labelColor, fontSize: 14),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
