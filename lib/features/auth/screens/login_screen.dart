import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../referidos/providers/referido_provider.dart';
import '../../rifas/providers/rifa_provider.dart';
import '../../menu/providers/menu_provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/legal/legal_constants.dart';
import '../../../core/legal/legal_modal.dart';
import '../../../core/legal/legal_footer.dart';
import '../../../core/legal/cookie_banner.dart';

enum AuthTab {
  login,
  register,
}

/// Modern authentication screen featuring seamless tabs for Login and Registration.
class LoginScreen extends StatefulWidget {
  final AuthTab initialTab;
  final String? initialRefCode;
  final String? initialCompanyCode;

  const LoginScreen({
    super.key,
    this.initialTab = AuthTab.login,
    this.initialRefCode,
    this.initialCompanyCode,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AuthTab _selectedTab;

  // Login Form State
  final _loginFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  // Register Form State (2-step Wizard)
  int _registerStep = 1; // 1 = Account credentials, 2 = Affiliation & Submit
  final _step1FormKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPasswordCtrl = TextEditingController();
  final _regConfirmPasswordCtrl = TextEditingController();
  final _refCodeCtrl = TextEditingController();
  final _companyCodeCtrl = TextEditingController();

  String _referralType = 'none'; // 'none', 'friend', 'company'
  bool _obscureRegPassword = true;
  bool _obscureRegConfirmPassword = true;
  bool _isValidatingCompany = false;
  String? _validatedCompanyName;
  String? _companyValidationError;
  Timer? _companyDebounceTimer;
  bool _termsAccepted = false; // Required by Ley 1581 de 2012 (Habeas Data)

  // Animations
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;

    if (widget.initialRefCode != null && widget.initialRefCode!.isNotEmpty) {
      _referralType = 'friend';
      _refCodeCtrl.text = widget.initialRefCode!;
    } else if (widget.initialCompanyCode != null &&
        widget.initialCompanyCode!.isNotEmpty) {
      _referralType = 'company';
      _companyCodeCtrl.text = widget.initialCompanyCode!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onCompanyCodeChanged(widget.initialCompanyCode!);
      });
    }

    _regPasswordCtrl.addListener(() => setState(() {}));
    _regConfirmPasswordCtrl.addListener(() => setState(() {}));
    _emailController.addListener(_clearAuthErrorOnType);
    _passwordController.addListener(_clearAuthErrorOnType);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  void _clearAuthErrorOnType() {
    final auth = context.read<AuthProvider>();
    if (auth.errorMessage != null) {
      auth.clearError();
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearAuthErrorOnType);
    _passwordController.removeListener(_clearAuthErrorOnType);
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPasswordCtrl.dispose();
    _regConfirmPasswordCtrl.dispose();
    _refCodeCtrl.dispose();
    _companyCodeCtrl.dispose();
    _companyDebounceTimer?.cancel();
    super.dispose();
  }

  // Password criteria getters
  bool get _hasMinLength => _regPasswordCtrl.text.length >= 10;
  bool get _hasUppercase => _regPasswordCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _regPasswordCtrl.text.contains(RegExp(r'[a-z]'));
  bool get _hasDigit => _regPasswordCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _passwordsMatch =>
      _regPasswordCtrl.text.isNotEmpty &&
      _regPasswordCtrl.text == _regConfirmPasswordCtrl.text;

  bool get _isRegPasswordValid =>
      _hasMinLength && _hasUppercase && _hasLowercase && _hasDigit && _passwordsMatch;

  int get _passwordScore {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasLowercase) score++;
    if (_hasDigit) score++;
    if (_passwordsMatch) score++;
    return score;
  }

  double get _passwordStrengthValue => _passwordScore / 5.0;

  Color get _passwordStrengthColor {
    if (_passwordScore <= 1) return const Color(0xFFEF4444);
    if (_passwordScore <= 3) return const Color(0xFFF59E0B);
    if (_passwordScore == 4) return const Color(0xFF3B82F6);
    return const Color(0xFF10B981);
  }

  String get _passwordStrengthLabel {
    if (_regPasswordCtrl.text.isEmpty) return 'Seguridad';
    if (_passwordScore <= 1) return 'Muy débil';
    if (_passwordScore <= 3) return 'Media';
    if (_passwordScore == 4) return 'Buena';
    return 'Excelente';
  }

  // Handle Company Code validation with debounce
  void _onCompanyCodeChanged(String value) {
    _companyDebounceTimer?.cancel();
    final code = value.trim();

    if (code.isEmpty) {
      setState(() {
        _validatedCompanyName = null;
        _isValidatingCompany = false;
        _companyValidationError = null;
      });
      return;
    }

    setState(() {
      _isValidatingCompany = true;
      _companyValidationError = null;
    });

    _companyDebounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final res = await context.read<AuthProvider>().validarCodigoEmpresa(code);
      if (!mounted) return;

      setState(() {
        _isValidatingCompany = false;
        if (res != null && res['name'] != null) {
          _validatedCompanyName = res['name'];
          _companyValidationError = null;
        } else {
          _validatedCompanyName = null;
          _companyValidationError = 'Código de empresa no válido';
        }
      });
    });
  }

  Future<void> _handleLogin() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoading) return;
    if (authProvider.isAccountLocked) {
      _showAccountLockedToast(context, authProvider.lockMinutes);
      return;
    }
    if (!_loginFormKey.currentState!.validate()) return;

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      context.read<MenuProvider>().clearMyMenus();
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
    } else if (!success && mounted) {
      if (authProvider.isAccountLocked) {
        _showAccountLockedModal(context, authProvider.lockMinutes);
        _showAccountLockedToast(context, authProvider.lockMinutes);
      }
    }
  }

  void _showAccountLockedToast(BuildContext context, int minutes) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acceso Bloqueado Temporalmente',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tu cuenta está bloqueada por $minutes minutos tras múltiples intentos fallidos.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Recuperar',
          textColor: Colors.white,
          onPressed: () => Navigator.of(context).pushNamed('/olvide-password'),
        ),
      ),
    );
  }

  void _showAccountLockedModal(BuildContext context, int minutes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 12,
        backgroundColor: Theme.of(dialogCtx).colorScheme.surface,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0x1FEF4444),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_clock_rounded,
                  size: 40,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Acceso Bloqueado',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(dialogCtx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: Theme.of(dialogCtx).colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                  children: [
                    const TextSpan(
                      text: 'Tu cuenta ha sido bloqueada temporalmente por ',
                    ),
                    TextSpan(
                      text: '$minutes minutos',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    const TextSpan(
                      text: ' debido a 5 intentos fallidos consecutivos de contraseña.\n\nPor seguridad, el acceso permanecerá suspendido durante este periodo.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        Navigator.of(context).pushNamed('/olvide-password');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(
                          color: Theme.of(dialogCtx).colorScheme.outline.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'Recuperar clave',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Entendido',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
    );
  }

  void _goToStep2() {
    if (!_step1FormKey.currentState!.validate()) return;
    if (!_isRegPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verifica que tu contraseña cumpla todos los requisitos de seguridad',
          ),
          backgroundColor: Color(0xFFDC2626),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    setState(() {
      _registerStep = 2;
    });
  }

  Future<void> _handleRegister() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoading) return;

    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty ||
        _regEmailCtrl.text.trim().isEmpty ||
        !_isRegPasswordValid) {
      setState(() => _registerStep = 1);
      return;
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Debes aceptar los Términos y la Política de Tratamiento de Datos Personales (Ley 1581) para registrarte.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_referralType == 'company' &&
        _companyCodeCtrl.text.trim().isNotEmpty &&
        _validatedCompanyName == null) {
      setState(() {
        _companyValidationError = 'Debes ingresar un código de empresa válido';
      });
      return;
    }

    final success = await authProvider.register(
      email: _regEmailCtrl.text.trim(),
      password: _regPasswordCtrl.text,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      refCode: _referralType == 'friend' && _refCodeCtrl.text.trim().isNotEmpty
          ? _refCodeCtrl.text.trim()
          : null,
      codigoEmpresa: _referralType == 'company' &&
              _companyCodeCtrl.text.trim().isNotEmpty
          ? _companyCodeCtrl.text.trim()
          : null,
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 920;
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
                                vertical: 28,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildAuthCard(
                                    context,
                                    size,
                                    themeProvider,
                                  ),
                                  const SizedBox(height: 16),
                                  const LegalFooter(compact: true),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: _buildBrandPanel(themeProvider),
                        ),
                      ],
                    )
                  : Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAuthCard(
                              context,
                              size,
                              themeProvider,
                            ),
                            const SizedBox(height: 16),
                            const LegalFooter(compact: true),
                          ],
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

              // Floating Cookie Consent Banner (SIC compliant)
              const CookieBanner(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthCard(
    BuildContext context,
    Size size,
    ThemeProvider themeProvider,
  ) {
    final isDark = themeProvider.isDarkMode;
    final cardWidth = size.width > 550
        ? (_selectedTab == AuthTab.register ? 470.0 : 430.0)
        : double.infinity;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: cardWidth,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 36,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Icon ──
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _selectedTab == AuthTab.login
                        ? Icons.lock_outline_rounded
                        : Icons.person_add_alt_1_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Tab Switcher ──
              _buildSegmentedTabBar(isDark),
              const SizedBox(height: 24),

              // ── Tab View Content ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: child,
                ),
                child: _selectedTab == AuthTab.login
                    ? _buildLoginForm(context, themeProvider)
                    : _buildRegisterForm(context, themeProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Segmented Tab Switcher ──
  Widget _buildSegmentedTabBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.35)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              tab: AuthTab.login,
              label: context.tr('login_title'),
              icon: Icons.login_rounded,
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              tab: AuthTab.register,
              label: context.tr('register_title'),
              icon: Icons.person_add_rounded,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required AuthTab tab,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedTab == tab;

    return GestureDetector(
      onTap: () {
        if (_selectedTab != tab) {
          context.read<AuthProvider>().clearError();
          setState(() {
            _selectedTab = tab;
            if (tab == AuthTab.register) {
              _registerStep = 1;
            }
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected
                  ? (isDark ? Colors.white : AppColors.primary)
                  : (isDark ? Colors.white54 : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.primary)
                      : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Formulario de Inicio de Sesión ──
  Widget _buildLoginForm(BuildContext context, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;

    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey('login_form_view'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('login_subtitle'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 22),

          // Error banner
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.errorMessage == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF450A0A).withValues(alpha: 0.7)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF991B1B)
                        : const Color(0xFFFCA5A5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: isDark
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFFDC2626),
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        auth.errorMessage!,
                        style: GoogleFonts.inter(
                          color: isDark
                              ? const Color(0xFFFECACA)
                              : const Color(0xFFB91C1C),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => auth.clearError(),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF991B1B),
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
            hintText: context.tr('email_hint'),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_passwordFocusNode);
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.tr('email_required');
              }
              if (!value.contains('@') || !value.contains('.')) {
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
            hintText: context.tr('password_hint'),
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: isDark ? Colors.white54 : Colors.black45,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.tr('password_required');
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/olvide-password'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Login Button
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: auth.isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              context.tr('login_loading'),
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.tr('login_button'),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Switch to register tab link
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '¿Aún no tienes una cuenta? ',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    context.read<AuthProvider>().clearError();
                    setState(() {
                      _selectedTab = AuthTab.register;
                      _registerStep = 1;
                    });
                  },
                  child: Text(
                    'Regístrate aquí',
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
    );
  }

  // ── Tab 2: Formulario Formal de Registro en 2 Pasos (Wizard) ──
  Widget _buildRegisterForm(BuildContext context, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;

    return Column(
      key: const ValueKey('register_wizard_container'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Stepper: [1. Tu Cuenta] ───── [2. Afiliación]
        _buildRegisterStepper(isDark),

        // Error banner if any
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.errorMessage == null) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFDC2626),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      auth.errorMessage!,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFB91C1C),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Animated Switcher between Step 1 and Step 2
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, anim) {
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: _registerStep == 2
                      ? const Offset(0.06, 0)
                      : const Offset(-0.06, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
            );
          },
          child: _registerStep == 1
              ? _buildStep1Account(context, themeProvider)
              : _buildStep2Affiliation(context, themeProvider),
        ),
      ],
    );
  }

  // ── Stepper Header ──
  Widget _buildRegisterStepper(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          // Step 1: Tu Cuenta
          _buildStepItem(
            stepNumber: 1,
            title: 'Tu Cuenta',
            isActive: _registerStep == 1,
            isCompleted: _registerStep > 1,
            isDark: isDark,
          ),
          // Connector Line
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _registerStep > 1
                    ? AppColors.primary
                    : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Step 2: Afiliación
          _buildStepItem(
            stepNumber: 2,
            title: 'Afiliación',
            isActive: _registerStep == 2,
            isCompleted: false,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int stepNumber,
    required String title,
    required bool isActive,
    required bool isCompleted,
    required bool isDark,
  }) {
    final activeColor = AppColors.primary;
    final inactiveColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? const Color(0xFF16A34A)
                : (isActive
                    ? activeColor
                    : (isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : Text(
                    '$stepNumber',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: (isActive || isCompleted)
                          ? Colors.white
                          : inactiveColor,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : inactiveColor,
          ),
        ),
      ],
    );
  }

  // ── Paso 1: Datos de Acceso y Credenciales ──
  Widget _buildStep1Account(BuildContext context, ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;

    return Form(
      key: _step1FormKey,
      child: Column(
        key: const ValueKey('step_1_account_view'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nombre y Apellido
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  themeProvider: themeProvider,
                  controller: _firstNameCtrl,
                  label: 'Nombre',
                  icon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa tu nombre'
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  themeProvider: themeProvider,
                  controller: _lastNameCtrl,
                  label: 'Apellido',
                  icon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa tu apellido'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Correo Electrónico
          _buildTextField(
            themeProvider: themeProvider,
            controller: _regEmailCtrl,
            label: context.tr('email'),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return context.tr('email_required');
              }
              if (!v.contains('@') || !v.contains('.')) {
                return context.tr('invalid_email');
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Contraseña
          _buildTextField(
            themeProvider: themeProvider,
            controller: _regPasswordCtrl,
            label: context.tr('password'),
            icon: Icons.lock_outline_rounded,
            obscure: _obscureRegPassword,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRegPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: isDark ? Colors.white54 : Colors.black45,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureRegPassword = !_obscureRegPassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return context.tr('password_required');
              if (v.length < 10) return 'Mínimo 10 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Confirmar Contraseña
          _buildTextField(
            themeProvider: themeProvider,
            controller: _regConfirmPasswordCtrl,
            label: 'Confirmar contraseña',
            icon: Icons.lock_outline_rounded,
            obscure: _obscureRegConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _goToStep2(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRegConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: isDark ? Colors.white54 : Colors.black45,
                size: 20,
              ),
              onPressed: () => setState(
                  () => _obscureRegConfirmPassword = !_obscureRegConfirmPassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirma tu contraseña';
              if (v != _regPasswordCtrl.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),

          // Criterios compactos de contraseña
          _buildCompactPasswordCriteria(isDark),
          const SizedBox(height: 18),

          // Botón Continuar
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _goToStep2,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continuar',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Switch back to login
          _buildBackToLoginLink(isDark),
        ],
      ),
    );
  }

  // ── Barra de Seguridad y Chips Compactos ──
  Widget _buildCompactPasswordCriteria(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _passwordStrengthValue,
                  minHeight: 4,
                  backgroundColor:
                      isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _passwordStrengthLabel,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _passwordStrengthColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Mini criteria chips
        Wrap(
          spacing: 6,
          runSpacing: 5,
          children: [
            _buildCriteriaChip('10+ caracteres', _hasMinLength, isDark),
            _buildCriteriaChip('Mayúscula (A-Z)', _hasUppercase, isDark),
            _buildCriteriaChip('Minúscula (a-z)', _hasLowercase, isDark),
            _buildCriteriaChip('Número (0-9)', _hasDigit, isDark),
            _buildCriteriaChip('Coinciden', _passwordsMatch, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildCriteriaChip(String label, bool satisfied, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: satisfied
            ? const Color(0xFF16A34A).withValues(alpha: 0.12)
            : (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: satisfied
              ? const Color(0xFF16A34A).withValues(alpha: 0.35)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            satisfied ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 11,
            color: satisfied
                ? const Color(0xFF16A34A)
                : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: satisfied ? FontWeight.w600 : FontWeight.w500,
              color: satisfied
                  ? const Color(0xFF16A34A)
                  : (isDark ? Colors.white54 : const Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Paso 2: Vinculación / Convenio (Opcional) y Confirmación ──
  Widget _buildStep2Affiliation(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    final isDark = themeProvider.isDarkMode;

    return Column(
      key: const ValueKey('step_2_affiliation_view'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Subtitle / explanation
        Text(
          '¿Tienes un código de vinculación?',
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Accede a beneficios exclusivos de convenio o invitación ingresando tu código (opcional).',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),

        // Referral selector & inputs
        _buildReferralSection(isDark, themeProvider),
        const SizedBox(height: 20),

        // Terms & Habeas Data consent checkbox (Ley 1581 de 2012)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _termsAccepted,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _termsAccepted = val ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      height: 1.45,
                      color: isDark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF334155),
                    ),
                    children: [
                      const TextSpan(text: 'He leído y acepto los '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: InkWell(
                          onTap: () => LegalModal.show(
                            context,
                            initialTab: LegalTab.terms,
                          ),
                          child: Text(
                            'Términos y Condiciones',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3B82F6),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ', la '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: InkWell(
                          onTap: () => LegalModal.show(
                            context,
                            initialTab: LegalTab.privacy,
                          ),
                          child: Text(
                            'Política de Privacidad',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3B82F6),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(
                        text:
                            ' y autorizo el tratamiento de mis datos personales a ',
                      ),
                      const TextSpan(
                        text: '${LegalConstants.companyName} (${LegalConstants.brandName})',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(
                        text: ' conforme a la Ley 1581 de 2012.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Action Buttons Row: [ Atrás ]  [ Crear mi Cuenta ]
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return Row(
              children: [
                // Back button
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: auth.isLoading
                        ? null
                        : () => setState(() => _registerStep = 1),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: Text(
                      'Atrás',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isDark ? Colors.white70 : const Color(0xFF334155),
                      side: BorderSide(
                        color:
                            isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Submit Button
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Crear mi Cuenta',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Switch back to login
        _buildBackToLoginLink(isDark),
      ],
    );
  }

  // ── Switch Back to Login Link ──
  Widget _buildBackToLoginLink(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes una cuenta? ',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedTab = AuthTab.login;
              _registerStep = 1;
            }),
            child: Text(
              'Inicia sesión aquí',
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
    );
  }

  // ── Sección de Código / Vinculación Opcional ──
  Widget _buildReferralSection(bool isDark, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.card_giftcard_rounded,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Text(
                '¿Tienes un código de vinculación? (Opcional)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chips de opciones
          Row(
            children: [
              _buildOptionChip(
                label: 'Sin código',
                value: 'none',
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildOptionChip(
                label: 'Amigo',
                value: 'friend',
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildOptionChip(
                label: 'Empresa',
                value: 'company',
                isDark: isDark,
              ),
            ],
          ),

          // Input condicional si selecciona "Amigo"
          if (_referralType == 'friend') ...[
            const SizedBox(height: 14),
            _buildTextField(
              themeProvider: themeProvider,
              controller: _refCodeCtrl,
              label: 'Código de referido',
              icon: Icons.tag_rounded,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 4),
            Text(
              'Ingresa el código que te compartió tu referente.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ],

          // Input condicional si selecciona "Empresa"
          if (_referralType == 'company') ...[
            const SizedBox(height: 14),
            _buildTextField(
              themeProvider: themeProvider,
              controller: _companyCodeCtrl,
              label: 'Código de empresa aliada',
              icon: Icons.business_rounded,
              textCapitalization: TextCapitalization.characters,
              onChanged: _onCompanyCodeChanged,
              suffixIcon: _isValidatingCompany
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : (_validatedCompanyName != null
                      ? const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF16A34A),
                          size: 20,
                        )
                      : null),
            ),
            if (_validatedCompanyName != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF16A34A),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Empresa confirmada: $_validatedCompanyName',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_companyValidationError != null) ...[
              const SizedBox(height: 6),
              Text(
                _companyValidationError!,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildOptionChip({
    required String label,
    required String value,
    required bool isDark,
  }) {
    final isSelected = _referralType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _referralType = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? Colors.white10 : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFCBD5E1)),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }

  // ── Brand Panel for Desktop Layout ──
  Widget _buildBrandPanel(ThemeProvider themeProvider) {
    return Container(
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
                          AppColors.primary.withValues(alpha: 0.8),
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
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeProvider.isDarkMode
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
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
                    padding: const EdgeInsets.symmetric(horizontal: 48.0),
                    child: Text(
                      context.tr('welcome_subtitle'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: themeProvider.isDarkMode
                            ? Colors.white.withValues(alpha: 0.7)
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
    );
  }

  Widget _buildTextField({
    required ThemeProvider themeProvider,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
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
      style: GoogleFonts.inter(color: textColor, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: labelColor, fontSize: 13),
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          color: themeProvider.isDarkMode
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.black38,
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: labelColor, size: 19),
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
        errorStyle: GoogleFonts.inter(color: AppColors.error, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}
