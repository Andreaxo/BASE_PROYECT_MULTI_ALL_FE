import 'package:shared_preferences/shared_preferences.dart';

/// Manages JWT token and user session persistence using SharedPreferences.
class AuthStorage {
  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userFirstNameKey = 'user_first_name';
  static const String _userLastNameKey = 'user_last_name';
  static const String _roleIdKey = 'role_id';
  static const String _roleCodeKey = 'role_code';
  static const String _activeCompanyIdKey = 'active_company_id';

  /// Save authentication data after login.
  static Future<void> saveAuthData({
    required String token,
    required int userId,
    required String email,
    required String firstName,
    required String lastName,
    int? roleId,
    required String roleCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId.toString());
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userFirstNameKey, firstName);
    await prefs.setString(_userLastNameKey, lastName);
    if (roleId != null) {
      await prefs.setString(_roleIdKey, roleId.toString());
    } else {
      await prefs.remove(_roleIdKey);
    }
    await prefs.setString(_roleCodeKey, roleCode);
  }

  /// Save the active company ID.
  static Future<void> saveActiveCompanyId(int companyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activeCompanyIdKey, companyId);
  }

  /// Get the active company ID.
  static Future<int?> getActiveCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_activeCompanyIdKey);
  }

  /// Get the stored JWT token.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Get stored user info.
  static Future<Map<String, String?>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString(_userIdKey),
      'email': prefs.getString(_userEmailKey),
      'firstName': prefs.getString(_userFirstNameKey),
      'lastName': prefs.getString(_userLastNameKey),
      'roleId': prefs.getString(_roleIdKey),
      'roleCode': prefs.getString(_roleCodeKey),
    };
  }

  /// Check if user is logged in (has a token).
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all stored auth data (logout).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userFirstNameKey);
    await prefs.remove(_userLastNameKey);
    await prefs.remove(_roleIdKey);
    await prefs.remove(_roleCodeKey);
    await prefs.remove(_activeCompanyIdKey);
  }

  static const String _localeKey = 'locale';
  static const String _themeModeKey = 'is_dark_theme';

  /// Save selected locale
  static Future<void> saveLocale(String localeCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, localeCode);
  }

  /// Get saved locale (defaults to Spanish 'es')
  static Future<String> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey) ?? 'es';
  }

  /// Save theme preference (true for dark, false for light)
  static Future<void> saveThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeModeKey, isDark);
  }

  /// Get saved theme preference (defaults to dark mode = true)
  static Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeModeKey) ?? true;
  }
}
