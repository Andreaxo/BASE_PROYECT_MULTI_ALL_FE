import 'package:flutter/material.dart';
import '../../../core/services/auth_storage.dart';
import '../../company/models/company_model.dart';
import '../../company/services/company_service.dart';
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

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;
  String get userName => _userName;
  String get roleCode => _roleCode;
  List<Company> get userCompanies => _userCompanies;
  Company? get activeCompany => _activeCompany;

  /// Check if user has a stored session on app start.
  Future<void> checkAuthStatus() async {
    _isLoggedIn = await AuthStorage.isLoggedIn();
    if (_isLoggedIn) {
      final userInfo = await AuthStorage.getUserInfo();
      _userName =
          '${userInfo['firstName'] ?? ''} ${userInfo['lastName'] ?? ''}'.trim();
      _roleCode = userInfo['roleCode'] ?? '';

      try {
        final profile = await AuthApiService.getProfile();
        
        if (_roleCode == 'superadmin') {
          // SuperAdmin can manage/work on all companies in the system
          _userCompanies = await CompanyApiService.getAll();
        } else {
          // Regular users can only access their associated companies
          _userCompanies = profile.companies
              .map((c) => Company(
                    id: c.id,
                    name: c.name,
                    isActive: true,
                  ))
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
      if (_roleCode == 'superadmin') {
        _userCompanies = await CompanyApiService.getAll();
      } else {
        _userCompanies = profile.companies
            .map((c) => Company(
                  id: c.id,
                  name: c.name,
                  isActive: true,
                ))
            .toList();
      }

      if (_userCompanies.isNotEmpty) {
        _activeCompany = _userCompanies.first;
        await AuthStorage.saveActiveCompanyId(_activeCompany!.id);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
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

  /// Logout and clear stored data.
  Future<void> logout() async {
    await AuthStorage.clear();
    _isLoggedIn = false;
    _userName = '';
    _roleCode = '';
    _userCompanies = [];
    _activeCompany = null;
    _errorMessage = null;
    notifyListeners();
  }
}
