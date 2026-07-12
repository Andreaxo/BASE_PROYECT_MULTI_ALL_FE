/// API configuration constants.
class ApiConfig {
  // Current active locale for HTTP requests
  static String activeLocale = 'es';

  // Change this to your backend URL
  static const String baseUrl = 'http://localhost:8080/api';

  // Base server URL (without /api) to load uploaded images
  static String get serverUrl => baseUrl.replaceAll('/api', '');

  // Endpoints
  static const String loginEndpoint = '$baseUrl/auth/login';
  static const String usersEndpoint = '$baseUrl/users';
  static const String companiesEndpoint = '$baseUrl/companies';
  static const String rolesEndpoint = '$baseUrl/roles';
  static const String menusEndpoint = '$baseUrl/menus';
  static const String myMenusEndpoint = '$baseUrl/menus/my';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
}
