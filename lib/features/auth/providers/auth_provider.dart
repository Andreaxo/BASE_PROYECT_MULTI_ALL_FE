import 'package:flutter/material.dart';
import '../../../core/services/auth_storage.dart';
import '../../company/models/company_model.dart';
import '../../company/services/company_service.dart';
import '../../users/models/user_model.dart';
import '../models/login_model.dart';
import '../services/auth_service.dart';

/// Manages authentication state and active company context across the app.
class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;
  String _userName = '';
  String _roleCode = '';
  List<Company> _userCompanies = [];
  Company? _activeCompany;
  User? _currentUser;
  bool _isAccountLocked = false;
  int _lockMinutes = 15;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  String get userName => _userName;
  String get roleCode => _roleCode;
  bool get isAccountLocked => _isAccountLocked;
  int get lockMinutes => _lockMinutes;
  bool get isSuperAdmin =>
      _roleCode.toLowerCase().trim() == 'superadmin' ||
      _roleCode.toLowerCase().trim() == 'super_admin';
  bool get isAdminOrSuperAdmin =>
      isSuperAdmin || _roleCode.toLowerCase().trim() == 'admin';
  String get roleDisplayName {
    switch (_roleCode.toLowerCase().trim()) {
      case 'superadmin':
      case 'super_admin':
        return 'Super Administrador';
      case 'admin':
        return 'Administrador';
      case 'business_validator':
      case 'negocio':
        return 'Validador de Negocio';
      case 'user':
      case 'user_member':
        return 'Miembro Conexiate';
      case 'operador':
        return 'Operador';
      default:
        if (_roleCode.isEmpty) return 'Usuario';
        return _roleCode
            .replaceAll('_', ' ')
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
            .join(' ');
    }
  }
  List<Company> get userCompanies => _userCompanies;
  Company? get activeCompany => _activeCompany;
  User? get currentUser => _currentUser;

  /// Check if user has a stored session on app start.
  Future<void> checkAuthStatus() async {
    _isLoggedIn = await AuthStorage.isLoggedIn();
    if (_isLoggedIn) {
      final userInfo = await AuthStorage.getUserInfo();
      _userName = '${userInfo['firstName'] ?? ''} ${userInfo['lastName'] ?? ''}'
          .trim();
      _roleCode = userInfo['roleCode'] ?? '';

      try {
        final profile = await AuthApiService.getProfile();
        _currentUser = profile;
        _userName = '${profile.firstName} ${profile.lastName}'.trim();
        _roleCode = profile.roleCode;

        if (_roleCode == 'superadmin') {
          // SuperAdmin can manage/work on all companies in the system
          _userCompanies = await CompanyApiService.getAll();
        } else {
          // Regular users can only access their associated companies
          _userCompanies = profile.companies
              .map(
                (c) => Company(
                  id: c.id,
                  nit: c.nit,
                  name: c.name,
                  isActive: true,
                  photoUrl: c.photoUrl,
                  suscripcionEstado: c.suscripcionEstado,
                  razonSocial: c.razonSocial,
                  codigoEmpresa: c.codigoEmpresa,
                  fechaFinPrueba: c.fechaFinPrueba,
                ),
              )
              .toList();
        }

        final activeId = await AuthStorage.getActiveCompanyId();
        if (activeId != null && _userCompanies.any((c) => c.id == activeId)) {
          _activeCompany = _userCompanies.firstWhere((c) => c.id == activeId);
        } else if (_userCompanies.isNotEmpty) {
          _activeCompany = _userCompanies.first;
          await AuthStorage.saveActiveCompanyId(_activeCompany!.id);
        }
      } catch (e) {
        // Session expired or failed to load profile
        await logout();
      }
    }
    notifyListeners();
  }

  /// Perform login with email and password.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthStorage.clear();
      _activeCompany = null;
      _userCompanies = [];
      _currentUser = null;

      final response = await AuthApiService.login(
        LoginRequest(email: email, password: password),
      );

      // Save auth data
      await AuthStorage.saveAuthData(
        token: response.token,
        userId: response.user.id,
        email: response.user.email,
        firstName: response.user.firstName,
        lastName: response.user.lastName,
        roleId: response.user.roleId,
        roleCode: response.user.roleCode,
      );

      _isLoggedIn = true;
      _userName = '${response.user.firstName} ${response.user.lastName}'.trim();
      _roleCode = response.user.roleCode;

      // Fetch profile & setup active company
      final profile = await AuthApiService.getProfile();
      _currentUser = profile;
      if (_roleCode == 'superadmin') {
        _userCompanies = await CompanyApiService.getAll();
      } else {
        _userCompanies = profile.companies
            .map(
              (c) => Company(
                id: c.id,
                nit: c.nit,
                name: c.name,
                isActive: true,
                photoUrl: c.photoUrl,
                suscripcionEstado: c.suscripcionEstado,
                razonSocial: c.razonSocial,
                codigoEmpresa: c.codigoEmpresa,
                fechaFinPrueba: c.fechaFinPrueba,
              ),
            )
            .toList();
      }

      if (_userCompanies.isNotEmpty) {
        _activeCompany = _userCompanies.first;
        await AuthStorage.saveActiveCompanyId(_activeCompany!.id);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on AccountLockedException catch (e) {
      _isAccountLocked = true;
      _lockMinutes = e.minutes;
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isAccountLocked = false;
      _errorMessage = _mapAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clears active error message smoothly
  void clearError() {
    if (_errorMessage != null || _isAccountLocked) {
      _errorMessage = null;
      _isAccountLocked = false;
      notifyListeners();
    }
  }

  /// Maps raw technical errors or API responses into human-friendly, polite messages.
  String _mapAuthError(dynamic error) {
    final raw = error.toString().replaceAll('Exception: ', '').trim();
    final lower = raw.toLowerCase();

    // Credential errors
    if (lower.contains('credenciales inválidas') ||
        lower.contains('invalid credentials') ||
        lower.contains('credenciales invalidas') ||
        lower.contains('correo electrónico o la contraseña son incorrectos') ||
        lower.contains('correo o la contraseña son incorrectos')) {
      return 'El correo electrónico o la contraseña son incorrectos. Por favor, verifica tus datos e inténtalo de nuevo.';
    }

    // Inactive account errors
    if (lower.contains('inactiva') || lower.contains('inactive')) {
      return 'Tu cuenta se encuentra inactiva. Por favor, revisa tu correo para activarla o ponte en contacto con soporte.';
    }

    // User not found
    if (lower.contains('no encontrado') ||
        lower.contains('not found') ||
        lower.contains('no existe ningún usuario')) {
      return 'No encontramos una cuenta asociada a este correo electrónico.';
    }

    // Duplicate email
    if (lower.contains('ya se encuentra registrado') ||
        lower.contains('already registered') ||
        lower.contains('duplicate')) {
      return 'Este correo electrónico ya está registrado. Por favor inicia sesión o recupera tu contraseña.';
    }

    // Network & connection errors
    if (lower.contains('socketexception') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection timed out') ||
        lower.contains('clientexception')) {
      return 'No fue posible conectar con el servidor. Por favor, comprueba tu conexión a internet o intenta más tarde.';
    }

    // Timeout
    if (lower.contains('timeout')) {
      return 'El servidor tardó demasiado en responder. Por favor, intenta de nuevo en unos momentos.';
    }

    // Clean API message
    if (raw.isNotEmpty && !raw.contains('Instance of') && !raw.contains('Error:')) {
      return raw;
    }

    return 'Ocurrió un error al procesar tu solicitud. Por favor, intenta de nuevo.';
  }

  /// Perform registration with optional referral code and company code, plus auto-login.
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? refCode,
    String? codigoEmpresa,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthStorage.clear();
      _activeCompany = null;
      _userCompanies = [];
      _currentUser = null;

      final response = await AuthApiService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        refCode: refCode,
        codigoEmpresa: codigoEmpresa,
      );

      await AuthStorage.saveAuthData(
        token: response.token,
        userId: response.user.id,
        email: response.user.email,
        firstName: response.user.firstName,
        lastName: response.user.lastName,
        roleId: response.user.roleId,
        roleCode: response.user.roleCode,
      );

      _isLoggedIn = true;
      _userName = '${response.user.firstName} ${response.user.lastName}'.trim();
      _roleCode = response.user.roleCode;

      try {
        final profile = await AuthApiService.getProfile();
        _currentUser = profile;
        if (_roleCode == 'superadmin') {
          _userCompanies = await CompanyApiService.getAll();
        } else {
          _userCompanies = profile.companies
              .map(
                (c) => Company(
                  id: c.id,
                  nit: c.nit,
                  name: c.name,
                  isActive: true,
                  photoUrl: c.photoUrl,
                  suscripcionEstado: c.suscripcionEstado,
                  razonSocial: c.razonSocial,
                  codigoEmpresa: c.codigoEmpresa,
                  fechaFinPrueba: c.fechaFinPrueba,
                ),
              )
              .toList();
        }
        if (_userCompanies.isNotEmpty) {
          _activeCompany = _userCompanies.first;
          await AuthStorage.saveActiveCompanyId(_activeCompany!.id);
        }
      } catch (_) {}

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _mapAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Select a new active company context.
  Future<void> setActiveCompany(Company company) async {
    _activeCompany = company;
    await AuthStorage.saveActiveCompanyId(company.id);
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (_isLoggedIn) {
      try {
        final profile = await AuthApiService.getProfile();
        _currentUser = profile;
        _userName = '${profile.firstName} ${profile.lastName}'.trim();
        _roleCode = profile.roleCode;

        if (_roleCode == 'superadmin') {
          _userCompanies = await CompanyApiService.getAll();
        } else {
          _userCompanies = profile.companies
              .map(
                (c) => Company(
                  id: c.id,
                  nit: c.nit,
                  name: c.name,
                  isActive: true,
                  photoUrl: c.photoUrl,
                  suscripcionEstado: c.suscripcionEstado,
                  razonSocial: c.razonSocial,
                  codigoEmpresa: c.codigoEmpresa,
                  fechaFinPrueba: c.fechaFinPrueba,
                ),
              )
              .toList();
        }

        if (_activeCompany != null) {
          final matchingComp = _userCompanies.firstWhere(
            (c) => c.id == _activeCompany!.id,
            orElse: () => _activeCompany!,
          );
          _activeCompany = matchingComp;
        }

        // Save updated auth details locally
        final token = await AuthStorage.getToken();
        final userId = await AuthStorage.getUserId();
        if (token != null && userId != null) {
          await AuthStorage.saveAuthData(
            token: token,
            userId: userId,
            email: profile.email,
            firstName: profile.firstName,
            lastName: profile.lastName,
            roleId: profile.roleId,
            roleCode: profile.roleCode,
          );
        }

        notifyListeners();
      } catch (_) {}
    }
  }

  /// Validate a company code in real-time.
  Future<Map<String, dynamic>?> validarCodigoEmpresa(String codigo) async {
    try {
      return await AuthApiService.validarCodigoEmpresa(codigo);
    } catch (_) {
      return null;
    }
  }

  /// Logout and clear stored data both locally and on server.
  Future<void> logout() async {
    try {
      await AuthApiService.logout();
    } catch (_) {}
    await AuthStorage.clear();
    _isLoggedIn = false;
    _userName = '';
    _roleCode = '';
    _userCompanies = [];
    _activeCompany = null;
    _currentUser = null;
    _errorMessage = null;
    _isAccountLocked = false;
    notifyListeners();
  }
}
