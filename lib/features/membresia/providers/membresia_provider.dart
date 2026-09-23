import 'package:flutter/material.dart';
import '../models/membresia_model.dart';
import '../services/membresia_service.dart';

class MembresiaProvider extends ChangeNotifier {
  MembresiaModel? _miMembresia;
  List<MembresiaModel> _allMembresias = [];
  bool _isLoading = false;
  bool _isPaying = false;
  String? _errorMessage;

  MembresiaModel? get miMembresia => _miMembresia;
  List<MembresiaModel> get allMembresias => _allMembresias;
  bool get isLoading => _isLoading;
  bool get isPaying => _isPaying;
  String? get errorMessage => _errorMessage;

  bool get hasActiveMembership => _miMembresia?.isActiva ?? false;

  Future<void> loadMiMembresia({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _miMembresia = await MembresiaApiService.getMiMembresia();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<IniciarPagoResponse?> iniciarPago({String? redirectUrl}) async {
    _isPaying = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = redirectUrl ?? '';
      final response = await MembresiaApiService.iniciarPago(url);
      _errorMessage = null;
      return response;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isPaying = false;
      notifyListeners();
    }
  }

  Future<bool> cancelarRenovacion() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _miMembresia = await MembresiaApiService.cancelarRenovacion();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllMembresias() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allMembresias = await MembresiaApiService.getAllMembresias();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> simularPago({String status = 'APPROVED'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _miMembresia = await MembresiaApiService.simularPago(status);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
