import 'package:flutter/material.dart';
import '../models/role_model.dart';
import '../services/role_service.dart';

class RoleProvider extends ChangeNotifier {
  List<Role> _roles = [];
  List<OptionModel> _options = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Role> get roles => _roles;
  List<OptionModel> get options => _options;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadRoles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _roles = await RoleApiService.getAll();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOptions() async {
    try {
      _options = await RoleApiService.getOptions();
      notifyListeners();
    } catch (e) {
      debugPrint("RoleProvider loadOptions Error: $e");
    }
  }

  Future<bool> createRole(CreateRoleRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newRole = await RoleApiService.create(request);
      _roles.add(newRole);
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

  Future<bool> updateRole(int id, UpdateRoleRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedRole = await RoleApiService.update(id, request);
      final index = _roles.indexWhere((r) => r.id == id);
      if (index != -1) {
        _roles[index] = updatedRole;
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

  Future<bool> deleteRole(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await RoleApiService.delete(id);
      _roles.removeWhere((r) => r.id == id);
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
