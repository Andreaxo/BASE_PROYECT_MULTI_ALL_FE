import 'package:flutter/material.dart';
import '../models/company_model.dart';
import '../services/company_service.dart';

class CompanyProvider extends ChangeNotifier {
  List<Company> _companies = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Company> get companies => _companies;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCompanies() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _companies = await CompanyApiService.getAll();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCompany(CreateCompanyRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newComp = await CompanyApiService.create(request);
      _companies.insert(0, newComp);
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

  Future<bool> updateCompany(int id, UpdateCompanyRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedComp = await CompanyApiService.update(id, request);
      final index = _companies.indexWhere((c) => c.id == id);
      if (index != -1) {
        _companies[index] = updatedComp;
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

  Future<bool> deleteCompany(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await CompanyApiService.delete(id);
      _companies.removeWhere((c) => c.id == id);
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
}
