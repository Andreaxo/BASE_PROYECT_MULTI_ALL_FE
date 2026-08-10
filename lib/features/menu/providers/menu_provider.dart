import 'package:flutter/material.dart';
import '../models/menu_model.dart';
import '../services/menu_service.dart';

class MenuProvider extends ChangeNotifier {
  List<MenuModel> _menus = [];
  List<AllowedMenu> _myMenus = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MenuModel> get menus => _menus;
  List<AllowedMenu> get myMenus => _myMenus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMenus() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _menus = await MenuApiService.getAll();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyMenus() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myMenus = await MenuApiService.getMyMenus();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createMenu(CreateMenuRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newMenu = await MenuApiService.create(request);
      _menus.add(newMenu);
      await loadMyMenus();
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

  Future<bool> updateMenu(int id, UpdateMenuRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedMenu = await MenuApiService.update(id, request);
      final index = _menus.indexWhere((m) => m.id == id);
      if (index != -1) {
        _menus[index] = updatedMenu;
      }
      await loadMyMenus();
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

  Future<bool> deleteMenu(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await MenuApiService.delete(id);
      _menus.removeWhere((m) => m.id == id);
      await loadMyMenus();
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

  void clearMyMenus() {
    _myMenus = [];
    notifyListeners();
  }

  /// Find allowed menu by route in the menu tree recursively.
  AllowedMenu? findAllowedMenu(String route) {
    return _findRecursive(_myMenus, route);
  }

  AllowedMenu? _findRecursive(List<AllowedMenu> list, String route) {
    for (final m in list) {
      if (m.route == route) return m;
      final found = _findRecursive(m.submenus, route);
      if (found != null) return found;
    }
    return null;
  }
}
