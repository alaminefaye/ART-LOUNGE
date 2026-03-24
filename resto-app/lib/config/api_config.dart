import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // En web : utilise le même domaine que la page (ex: https://mondomaine.com/client → API https://mondomaine.com/api)
  // En mobile : utilise l'URL de production
  static String get baseUrl {
    if (kIsWeb) {
      return '${Uri.base.origin}/api';
    }
    return 'https://restaurant.universaltechnologiesafrica.com/api';
  }

  // URL de base du serveur (sans /api)
  static String get serverBaseUrl {
    return baseUrl.replaceAll('/api', '');
  }

  // Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String deleteAccount = '/auth/delete-account';
  static const String me = '/auth/me';
  static const String updateFcmToken = '/auth/fcm-token';

  // Tables
  static const String tables = '/tables';

  // Menus
  static const String categories = '/categories';
  static const String products = '/produits';

  // Orders
  static const String orders = '/commandes';
  static String orderStatus(int id) => '/commandes/$id/statut';
  static String launchOrder(int id) => '/commandes/$id/lancer';
  static String marquerServi(int id) => '/commandes/$id/marquer-servi';
  static String orderInvoice(int id) => '/commandes/$id/facture';

  // Payments
  static const String payments = '/paiements';
  static String confirmPayment(int id) => '/paiements/$id/confirmer';
  static String validatePayment(int id) => '/paiements/$id/valider';
  static const String payCash = '/paiements/especes';

  // Avis
  static const String avis = '/avis';
  static String avisForOrder(int commandeId) => '/avis/commande/$commandeId';

  // Reservations
  static const String reservations = '/reservations';
  static const String checkAvailability =
      '/reservations/verifier-disponibilite';
  static String confirmReservation(int id) => '/reservations/$id/confirmer';
  static String cancelReservation(int id) => '/reservations/$id/annuler';

  // Notifications
  static const String notifications = '/notifications';
  static String notificationMarkRead(int id) => '/notifications/$id/read';
  static const String notificationsMarkAllRead = '/notifications/mark-all-read';
  static const String notificationsUnreadCount = '/notifications/unread-count';

  // Headers
  static Map<String, String> getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
