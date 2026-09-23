/// API configuration constants.
class ApiConfig {
  // Current active locale for HTTP requests
  static String activeLocale = 'es';

  // Backend URL: defaults to local development, configurable for production via:
  // flutter build web --release --dart-define=API_URL=https://api.tudominio.com/api
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080/api',
  );

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
  static const String miMembresiaEndpoint = '$baseUrl/membresia/mi-membresia';
  static const String iniciarPagoMembresiaEndpoint = '$baseUrl/membresia/iniciar-pago';
  static const String simularPagoMembresiaEndpoint = '$baseUrl/membresia/simular-pago';
  static const String cancelarRenovacionMembresiaEndpoint = '$baseUrl/membresia/cancelar-renovacion';
  static const String adminMembresiasEndpoint = '$baseUrl/membresia/admin/todas';

  // Auth password recovery & assisted registration
  static const String olvidePasswordEndpoint = '$baseUrl/auth/olvide-password';
  static const String verificarCodigoEndpoint = '$baseUrl/auth/verificar-codigo';
  static const String resetPasswordEndpoint = '$baseUrl/auth/reset-password';
  static const String registroAsistidoEndpoint = '$baseUrl/auth/registro-asistido';

  // Notificaciones
  static const String notificacionesEndpoint = '$baseUrl/notificaciones';
  static const String notificacionesNoLeidasCountEndpoint = '$baseUrl/notificaciones/no-leidas/count';
  static const String notificacionesMarcarTodasLeidasEndpoint = '$baseUrl/notificaciones/leer-todas';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
}
