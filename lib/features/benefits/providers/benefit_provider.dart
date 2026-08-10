import 'package:flutter/material.dart';
import '../models/benefit_model.dart';
import '../services/benefit_service.dart';

class BenefitProvider extends ChangeNotifier {
  List<Benefit> _benefits = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Benefit> get benefits => _benefits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadBenefits() async {
    _isLoading = true;
    _errorMessage = null;
    _benefits = [];
    notifyListeners();

    try {
      _benefits = await BenefitApiService.getAll();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyCompanyBenefits() async {
    _isLoading = true;
    _errorMessage = null;
    _benefits = [];
    notifyListeners();

    try {
      _benefits = await BenefitApiService.getMyCompanyBenefits();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBenefit(CreateBenefitRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newBenefit = await BenefitApiService.create(request);
      _benefits.insert(0, newBenefit);
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

  Future<bool> updateBenefit(int id, UpdateBenefitRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await BenefitApiService.update(id, request);
      final index = _benefits.indexWhere((b) => b.id == id);
      if (index != -1) {
        _benefits[index] = updated;
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

  Future<bool> deleteBenefit(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await BenefitApiService.delete(id);
      _benefits.removeWhere((b) => b.id == id);
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
