import 'package:flutter/material.dart';
import '../services/auth_storage.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isSidebarCollapsed = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isSidebarCollapsed => _isSidebarCollapsed;

  ThemeProvider() {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final isDark = await AuthStorage.isDarkMode();
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
      await AuthStorage.saveThemeMode(false);
    } else {
      _themeMode = ThemeMode.dark;
      await AuthStorage.saveThemeMode(true);
    }
    notifyListeners();
  }

  void toggleSidebar() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
    notifyListeners();
  }
}
