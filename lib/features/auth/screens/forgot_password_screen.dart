import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../services/auth_service.dart';

enum RecoveryStep {
  email,
  code,
  newPassword,
  success,
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  RecoveryStep _currentStep = RecoveryStep.email;

  // Step 1: Email Form
  final _emailFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  // Step 2: 6-Digit Code Form
  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeFocusNodes =
      List.generate(6, (_) => FocusNode());
  int _resendCooldown = 0;
  Timer? _resendTimer;
  String _resetToken = '';

  // Step 3: New Password Form
  final _passwordFormKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Global State
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onInputChanged);
    _passwordController.addListener(_onInputChanged);
    _confirmPasswordController.addListener(_onInputChanged);
    for (var c in _codeControllers) {
      c.addListener(_onInputChanged);
    }
  }

  void _onInputChanged() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    } else {
      setState(() {});
    }
  }

  String _formatErrorMessage(dynamic error) {
    if (error == null) {
      return 'Ha ocurrido un error inesperado. Por favor intenta de nuevo.';
    }
    var msg = error.toString().trim();
    if (msg.startsWith('Exception: ')) {
      msg = msg.substring('Exception: '.length).trim();
    }
    if (msg.isEmpty) {
      return 'Ha ocurrido un error inesperado. Por favor intenta de nuevo.';
    }

    final lower = msg.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable')) {
      return 'No fue posible conectar con el servidor. Por favor verifica tu conexión a internet.';
    }
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'La solicitud ha tardado demasiado tiempo. Por favor intenta de nuevo en unos momentos.';
    }
    if (lower.contains('user not found') ||
        lower.contains('no se encontró ningún usuario') ||
        lower.contains('usuario no encontrado')) {
      return 'No se encontró ningún usuario registrado con este correo electrónico.';
    }
    if (lower.contains('código inválido') ||
        lower.contains('codigo invalido') ||
        lower.contains('código incorrecto') ||
        lower.contains('codigo incorrecto') ||
        lower.contains('code_invalid') ||
        lower.contains('code_expired') ||
        lower.contains('invalid code')) {
      return 'El código ingresado es incorrecto o ha expirado. Por favor verifica e intenta de nuevo.';
    }
    if (lower.contains('expirado') || lower.contains('expired')) {
      return 'El código de seguridad ha expirado. Por favor solicita uno nuevo.';
    }
    if (lower.contains('demasiados intentos') ||
        lower.contains('too many attempts') ||
        lower.contains('bloqueado')) {
      return 'Has excedido el número máximo de intentos fallidos. Por favor solicita un nuevo código.';
    }
    if (lower.contains('token') || lower.contains('token inválido')) {
      return 'La sesión de recuperación ha expirado. Por favor solicita un nuevo código.';
    }

    // Capitalize first letter
    final firstChar = msg.substring(0, 1).toUpperCase();
    final remainder = msg.length > 1 ? msg.substring(1) : '';
    msg = '$firstChar$remainder';

    // Ensure ending punctuation
    if (!msg.endsWith('.') && !msg.endsWith('!') && !msg.endsWith('?')) {
      msg = '$msg.';
    }

    return msg;
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (var c in _codeControllers) {
      c.dispose();
    }
    for (var f in _codeFocusNodes) {
      f.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // --- Validation Helpers ---
  bool _isValidEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(trimmed);
  }

  String get _fullCode =>
      _codeControllers.map((c) => c.text.trim()).join();

  // Password criteria getters
  bool get _hasMinLength => _passwordController.text.length >= 10;
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasDigit => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _passwordsMatch =>
      _passwordController.text.isNotEmpty &&
      _passwordController.text == _confirmPasswordController.text;

  bool get _isPasswordValid =>
      _hasMinLength &&
      _hasUppercase &&
      _hasLowercase &&
      _hasDigit &&
      _passwordsMatch;

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
    if (_passwordController.text.isEmpty) return 'Seguridad';
    if (_passwordScore <= 1) return 'Muy débil';
    if (_passwordScore <= 3) return 'Media';
    if (_passwordScore == 4) return 'Buena';
    return 'Excelente';
  }

  void _startCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendCooldown = 45);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  // --- Actions ---

  // Action: Step 1 Submit Email
  Future<void> _submitEmail() async {
    if (!_isValidEmail(_emailController.text)) return;
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthApiService.olvidePassword(_emailController.text);
      if (mounted) {
        _startCooldown();
        for (var c in _codeControllers) {
          c.clear();
        }
        setState(() {
          _currentStep = RecoveryStep.code;
        });
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted && _codeFocusNodes.isNotEmpty) {
            _codeFocusNodes[0].requestFocus();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _formatErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Action: Resend Code
  Future<void> _resendCode() async {
    if (_resendCooldown > 0 || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthApiService.olvidePassword(_emailController.text);
      if (mounted) {
        _startCooldown();
        for (var c in _codeControllers) {
          c.clear();
        }
        if (_codeFocusNodes.isNotEmpty) {
          _codeFocusNodes[0].requestFocus();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Código reenviado con éxito a tu correo.'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _formatErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Action: Step 2 Verify Code
  Future<void> _verifyCode() async {
    final code = _fullCode;
    if (code.length != 6) {
      setState(
          () => _errorMessage = 'Por favor ingresa los 6 dígitos del código.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token =
          await AuthApiService.verificarCodigo(_emailController.text, code);
      if (mounted) {
        setState(() {
          _resetToken = token;
          _currentStep = RecoveryStep.newPassword;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _formatErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Action: Step 3 Submit New Password
  Future<void> _submitNewPassword() async {
    if (!_isPasswordValid) return;
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthApiService.resetPassword(
          _resetToken, _passwordController.text);
      if (mounted) {
        setState(() {
          _currentStep = RecoveryStep.success;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _formatErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF060913),
                        const Color(0xFF0F172A),
                        const Color(0xFF0B132B),
                      ]
                    : [
                        const Color(0xFFF1F5F9),
                        const Color(0xFFE2E8F0),
                        const Color(0xFFEDE9FE),
                      ],
              ),
            ),
          ),

          // Ambient Glow Orbs
          Positioned(
            top: -100,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary
                          .withValues(alpha: isDark ? 0.20 : 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent
                          .withValues(alpha: isDark ? 0.16 : 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand / Top Navigation
                    _buildTopHeader(context, isDark),
                    const SizedBox(height: 16),

                    // Main Glassmorphic Card
                    Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 34),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF131D33).withValues(alpha: 0.95)
                            : Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.45 : 0.08),
                            blurRadius: 32,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 3-Step Progress Indicator
                          _buildRecoveryStepper(isDark),

                          // Dynamic Step Form with smooth transition
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.04, 0),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  )),
                                  child: child,
                                ),
                              );
                            },
                            child: _buildCurrentStepView(isDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Security Footer
                    _buildSecurityFooter(isDark),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Top Navigation Header ---
  Widget _buildTopHeader(BuildContext context, bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              if (_currentStep == RecoveryStep.code) {
                for (var c in _codeControllers) {
                  c.clear();
                }
                FocusScope.of(context).unfocus();
                setState(() {
                  _errorMessage = null;
                  _resetToken = '';
                  _currentStep = RecoveryStep.email;
                });
                return;
              }
              if (_currentStep == RecoveryStep.newPassword) {
                _passwordController.clear();
                _confirmPasswordController.clear();
                FocusScope.of(context).unfocus();
                setState(() {
                  _errorMessage = null;
                  _currentStep = RecoveryStep.code;
                });
                return;
              }
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Volver',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Brand Logo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CONEXIATE',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(left: 3, top: 6),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Stepper Indicator ---
  Widget _buildRecoveryStepper(bool isDark) {
    if (_currentStep == RecoveryStep.success) {
      return const SizedBox.shrink();
    }

    int currentStepIndex = 1;
    if (_currentStep == RecoveryStep.email) currentStepIndex = 1;
    if (_currentStep == RecoveryStep.code) currentStepIndex = 2;
    if (_currentStep == RecoveryStep.newPassword) currentStepIndex = 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          _buildStepNode(
              1, 'Correo', currentStepIndex >= 1, currentStepIndex > 1, isDark),
          _buildStepDivider(currentStepIndex > 1, isDark),
          _buildStepNode(
              2, 'Código', currentStepIndex >= 2, currentStepIndex > 2, isDark),
          _buildStepDivider(currentStepIndex > 2, isDark),
          _buildStepNode(3, 'Nueva Clave', currentStepIndex >= 3,
              currentStepIndex > 3, isDark),
        ],
      ),
    );
  }

  Widget _buildStepNode(
      int step, String label, bool isActive, bool isCompleted, bool isDark) {
    final activeColor = AppColors.primary;
    final completedColor = const Color(0xFF16A34A);
    final inactiveColor =
        isDark ? Colors.white.withValues(alpha: 0.25) : const Color(0xFF94A3B8);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? completedColor
                : (isActive
                    ? activeColor
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0))),
            border: Border.all(
              color: isCompleted
                  ? completedColor
                  : (isActive ? activeColor : inactiveColor),
              width: 1.5,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : Text(
                    '$step',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : inactiveColor,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isCompleted
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : (isActive
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : inactiveColor),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(bool isCompleted, bool isDark) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isCompleted
              ? const Color(0xFF16A34A)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // --- Current Step Switcher ---
  Widget _buildCurrentStepView(bool isDark) {
    switch (_currentStep) {
      case RecoveryStep.email:
        return _buildEmailStep(isDark);
      case RecoveryStep.code:
        return _buildCodeStep(isDark);
      case RecoveryStep.newPassword:
        return _buildNewPasswordStep(isDark);
      case RecoveryStep.success:
        return _buildSuccessStep(isDark);
    }
  }

  // ── Step 1 View: Email ──
  Widget _buildEmailStep(bool isDark) {
    final isEmailValid = _isValidEmail(_emailController.text);
    final isBtnEnabled = !_isLoading && isEmailValid;

    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('step_email'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.16),
                    AppColors.accent.withValues(alpha: 0.10),
                  ],
                ),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '¿Olvidaste tu contraseña?',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa el correo electrónico asociado a tu cuenta y te enviaremos un código seguro de 6 dígitos para restablecerla.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          _buildErrorBanner(isDark),

          // Input
          Text(
            'Correo electrónico',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (isBtnEnabled) _submitEmail();
            },
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Por favor ingresa tu correo electrónico.';
              }
              if (!val.contains('@') || !val.contains('.')) {
                return 'Ingresa un correo electrónico válido (ej: usuario@correo.com).';
              }
              return null;
            },
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'ejemplo@correo.com',
              hintStyle: GoogleFonts.inter(
                fontSize: 13.5,
                color:
                    isDark ? Colors.white30 : const Color(0xFF94A3B8),
              ),
              prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
              filled: true,
              fillColor: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),

          // Submit Button (Reactive)
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isBtnEnabled ? _submitEmail : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
                disabledForegroundColor: isDark
                    ? Colors.white24
                    : const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Enviar Código de Seguridad',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed('/login'),
              child: Text(
                'Volver al inicio de sesión',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2 View: 6-Digit OTP Code ──
  Widget _buildCodeStep(bool isDark) {
    final isCodeComplete = _fullCode.length == 6;
    final isVerifyEnabled = !_isLoading && isCodeComplete;

    return Column(
      key: const ValueKey('step_code'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2563EB).withValues(alpha: 0.16),
                  AppColors.primary.withValues(alpha: 0.12),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF2563EB).withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 32,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Ingresa tu código',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hemos enviado un código numérico de 6 dígitos a:',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),

        // Email pill with edit action
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mail_outline_rounded,
                  size: 15,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  _emailController.text.trim(),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    for (var c in _codeControllers) {
                      c.clear();
                    }
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _errorMessage = null;
                      _resetToken = '';
                      _currentStep = RecoveryStep.email;
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'Cambiar',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildErrorBanner(isDark),

        // 6-digit input boxes
        _buildOtpInputBoxes(isDark),
        const SizedBox(height: 14),

        // Expiration badge
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7)
                  .withValues(alpha: isDark ? 0.12 : 0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined,
                    size: 14, color: Color(0xFFD97706)),
                const SizedBox(width: 6),
                Text(
                  'El código expira en 10 minutos',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),

        // Submit Button (Reactive)
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: isVerifyEnabled ? _verifyCode : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
              disabledForegroundColor: isDark
                  ? Colors.white24
                  : const Color(0xFF94A3B8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Verificar Código',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle_outline_rounded, size: 16),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Resend button
        Center(
          child: TextButton.icon(
            onPressed: (_resendCooldown > 0 || _isLoading) ? null : _resendCode,
            icon: Icon(
              Icons.refresh_rounded,
              size: 15,
              color: _resendCooldown > 0
                  ? (isDark ? Colors.white30 : const Color(0xFF94A3B8))
                  : AppColors.accent,
            ),
            label: Text(
              _resendCooldown > 0
                  ? 'Reenviar código en ${_resendCooldown}s'
                  : '¿No recibiste el código? Reenviar',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _resendCooldown > 0
                    ? (isDark ? Colors.white30 : const Color(0xFF94A3B8))
                    : AppColors.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInputBoxes(bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      final boxSize =
          ((constraints.maxWidth - (5 * 10)) / 6).clamp(38.0, 54.0);

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (index) {
          final isFilled = _codeControllers[index].text.isNotEmpty;

          return SizedBox(
            width: boxSize,
            height: boxSize * 1.15,
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.backspace) {
                  if (_codeControllers[index].text.isEmpty && index > 0) {
                    _codeFocusNodes[index - 1].requestFocus();
                    _codeControllers[index - 1].clear();
                  }
                }
              },
              child: TextFormField(
                controller: _codeControllers[index],
                focusNode: _codeFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: isDark
                      ? (isFilled
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.25))
                      : (isFilled
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : const Color(0xFFF8FAFC)),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isFilled
                          ? AppColors.primary
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFCBD5E1)),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isFilled
                          ? AppColors.primary
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
                onChanged: (val) {
                  setState(() {});
                  if (val.isNotEmpty) {
                    if (index < 5) {
                      _codeFocusNodes[index + 1].requestFocus();
                    } else {
                      _codeFocusNodes[index].unfocus();
                      if (_fullCode.length == 6) {
                        _verifyCode();
                      }
                    }
                  }
                },
              ),
            ),
          );
        }),
      );
    });
  }

  // ── Step 3 View: New Password ──
  Widget _buildNewPasswordStep(bool isDark) {
    final isSubmitEnabled = !_isLoading && _isPasswordValid;

    return Form(
      key: _passwordFormKey,
      child: Column(
        key: const ValueKey('step_new_password'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF16A34A).withValues(alpha: 0.18),
                    AppColors.accent.withValues(alpha: 0.12),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.lock_open_rounded,
                size: 32,
                color: Color(0xFF16A34A),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Crea tu nueva contraseña',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Código verificado con éxito. Define una contraseña segura que cumpla con los requisitos.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          _buildErrorBanner(isDark),

          // New password field
          Text(
            'Nueva contraseña',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Mínimo 10 caracteres',
              hintStyle: GoogleFonts.inter(
                fontSize: 13.5,
                color:
                    isDark ? Colors.white30 : const Color(0xFF94A3B8),
              ),
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Confirm password field
          Text(
            'Confirmar contraseña',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (isSubmitEnabled) _submitNewPassword();
            },
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Repite tu nueva contraseña',
              hintStyle: GoogleFonts.inter(
                fontSize: 13.5,
                color:
                    isDark ? Colors.white30 : const Color(0xFF94A3B8),
              ),
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Security checklist with strength bar
          _buildRequirementsCard(isDark),
          const SizedBox(height: 24),

          // Submit Button (Reactive)
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isSubmitEnabled ? _submitNewPassword : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
                disabledForegroundColor: isDark
                    ? Colors.white24
                    : const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Actualizar Contraseña',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_rounded, size: 16),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Strength meter bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _passwordStrengthValue,
                    minHeight: 4,
                    backgroundColor: isDark
                        ? Colors.white10
                        : const Color(0xFFE2E8F0),
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
          const SizedBox(height: 10),

          Text(
            'Requisitos de seguridad:',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          _buildCriterionRow('Mínimo 10 caracteres', _hasMinLength, isDark),
          _buildCriterionRow(
              'Al menos una letra mayúscula (A-Z)', _hasUppercase, isDark),
          _buildCriterionRow(
              'Al menos una letra minúscula (a-z)', _hasLowercase, isDark),
          _buildCriterionRow('Al menos un número (0-9)', _hasDigit, isDark),
          _buildCriterionRow(
              'Las contraseñas coinciden', _passwordsMatch, isDark),
        ],
      ),
    );
  }

  Widget _buildCriterionRow(String label, bool isValid, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Icon(
            isValid
                ? Icons.check_circle_rounded
                : Icons.circle_outlined,
            size: 15,
            color: isValid
                ? const Color(0xFF16A34A)
                : (isDark ? Colors.white30 : const Color(0xFF94A3B8)),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: isValid
                  ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
                  : (isDark ? Colors.white54 : const Color(0xFF64748B)),
              fontWeight: isValid ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 4 View: Success ──
  Widget _buildSuccessStep(bool isDark) {
    return Column(
      key: const ValueKey('step_success'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF16A34A).withValues(alpha: 0.15),
              border: Border.all(
                color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 46,
              color: Color(0xFF16A34A),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          '¡Contraseña actualizada!',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tu contraseña ha sido restablecida con éxito. Ya puedes iniciar sesión en Conexiate con tus nuevas credenciales.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed('/login'),
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
                  'Iniciar Sesión Ahora',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Error Banner ---
  Widget _buildErrorBanner(bool isDark) {
    if (_errorMessage == null) return const SizedBox.shrink();

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
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFFEF4444).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
              _errorMessage!,
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
            onTap: () => setState(() => _errorMessage = null),
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
  }

  Widget _buildSecurityFooter(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 13,
          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 6),
        Text(
          'Recuperación protegida y cifrada de extremo a extremo',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
