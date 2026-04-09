class ApiConfig {
  static const String baseUrl =
      'https://restaurant.universaltechnologiesafrica.com/api';

  static String get serverBaseUrl => baseUrl.replaceAll('/api', '');

  // Auth
  static const String login = '/auth/login';
  static const String loginWithPin = '/auth/login-pin';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String setPin = '/auth/set-pin';
  static const String verifyPin = '/auth/verify-pin';
  static const String waiters = '/auth/waiters';

  // Tables
  static const String tables = '/tables';

  // Menu
  static const String categories = '/categories';
  static const String products = '/produits';

  // Orders
  static const String orders = '/commandes';
  static String orderProducts(int id) => '/commandes/$id/produits';
  static String orderStatus(int id) => '/commandes/$id/statut';
  static String removeProduit(int orderId, int productId) => '/commandes/$orderId/produits/$productId';
  static String orderInvoice(int id) => '/commandes/$id/facture';
  static String launchOrder(int id) => '/commandes/$id/lancer';

  // Headers
  static Map<String, String> getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
