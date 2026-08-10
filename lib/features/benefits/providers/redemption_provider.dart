import 'package:flutter/material.dart';
import '../models/redemption_model.dart';
import '../services/redemption_service.dart';

class RedemptionProvider extends ChangeNotifier {
  List<BenefitRedemption> _myRedemptions = [];
  List<BenefitRedemption> _companyRedemptions = [];
  List<BenefitRedemption> _allRedemptions = [];

  bool _isLoading = false;
  bool _isValidating = false;
  String? _errorMessage;
  ValidateCodeResponse? _lastValidatedResponse;

  List<BenefitRedemption> get myRedemptions => _myRedemptions;
  List<BenefitRedemption> get companyRedemptions => _companyRedemptions;
  List<BenefitRedemption> get allRedemptions => _allRedemptions;

  bool get isLoading => _isLoading;
  bool get isValidating => _isValidating;
  String? get errorMessage => _errorMessage;
  ValidateCodeResponse? get lastValidatedResponse => _lastValidatedResponse;

  /// Helper to get existing redemption for a given benefit ID (if any).
  BenefitRedemption? getRedemptionForBenefit(int benefitId) {
    try {
      return _myRedemptions.firstWhere((r) => r.benefitId == benefitId);
    } catch (_) {
      return null;
    }
  }

  /// Load employee's redemptions.
  Future<void> loadMyRedemptions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myRedemptions = await RedemptionApiService.getMyRedemptions();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generate a new redemption code for an employee.
  Future<BenefitRedemption?> redeemBenefit(int benefitId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final redemption = await RedemptionApiService.redeem(benefitId);
      _myRedemptions.insert(0, redemption);
      _isLoading = false;
      notifyListeners();
      return redemption;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Validate a redemption code (business user).
  Future<bool> validateCode(String rawCode) async {
    _isValidating = true;
    _errorMessage = null;
    _lastValidatedResponse = null;
    notifyListeners();

    // Sanitization: remove spaces, dashes, convert to uppercase
    final cleanCode = rawCode
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .trim()
        .toUpperCase();

    if (cleanCode.isEmpty) {
      _errorMessage = 'Por favor ingresa un código válido';
      _isValidating = false;
      notifyListeners();
      return false;
    }

    try {
      final response = await RedemptionApiService.validateCode(cleanCode);
      _lastValidatedResponse = response;
      _isValidating = false;
      // Reload company redemptions after successful validation
      await loadCompanyRedemptions();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isValidating = false;
      notifyListeners();
      return false;
    }
  }

  /// Load business user's company redemptions.
  Future<void> loadCompanyRedemptions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _companyRedemptions = await RedemptionApiService.getCompanyRedemptions();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all redemptions for platform admin.
  Future<void> loadAllRedemptions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allRedemptions = await RedemptionApiService.getAllRedemptions();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }
}
