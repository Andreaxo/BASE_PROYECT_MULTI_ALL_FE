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
  static const String registerEndpoint = '$baseUrl/auth/register';
  static const String myCodeReferEndpoint = '$baseUrl/auth/mi-codigo-referido';
  static const String usersEndpoint = '$baseUrl/users';
  static const String companiesEndpoint = '$baseUrl/companies';
  static const String rolesEndpoint = '$baseUrl/roles';
  static const String menusEndpoint = '$baseUrl/menus';
  static const String myMenusEndpoint = '$baseUrl/menus/my';
  static const String benefitsEndpoint = '$baseUrl/benefit';
  static const String redeemBenefitEndpoint = '$baseUrl/benefits'; // /$id/redeem
  static const String myRedemptionsEndpoint = '$baseUrl/benefits/mis-redenciones';
  static const String validateRedemptionEndpoint = '$baseUrl/redemptions/validate';
  static const String companyRedemptionsEndpoint = '$baseUrl/redemptions';
  static const String adminRedemptionsEndpoint = '$baseUrl/admin/redemptions';
  static const String referidosEndpoint = '$baseUrl/referidos';
  static const String misReferidosEndpoint = '$baseUrl/referidos/mis-referidos';
  static const String rifasEndpoint = '$baseUrl/rifas';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
}
