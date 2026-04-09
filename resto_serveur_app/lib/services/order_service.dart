import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/order.dart';
import '../models/invoice.dart';
import 'api_service.dart';

class OrderService {
  final ApiService _apiService = ApiService();

  /// Create a new order for a table
  Future<Map<String, dynamic>> createOrder({
    required int tableId,
    required List<Map<String, dynamic>> produits,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.orders,
        data: {'table_id': tableId, 'produits': produits},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        Map<String, dynamic> orderData;
        if (data is Map) {
          orderData = data.containsKey('data')
              ? data['data'] as Map<String, dynamic>
              : data as Map<String, dynamic>;
        } else {
          return {'success': false, 'message': 'Format de réponse invalide'};
        }
        return {'success': true, 'order': Order.fromJson(orderData)};
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Erreur lors de la création',
      };
    } on DioException catch (e) {
      String message = 'Erreur lors de la création de la commande';
      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'] as String;
        }
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          message = 'Non autorisé. Veuillez vous reconnecter.';
        }
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Impossible de se connecter au serveur.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Erreur inattendue: $e'};
    }
  }

  /// Add products to an existing order
  Future<Map<String, dynamic>> addProductsToOrder({
    required int orderId,
    required List<Map<String, dynamic>> produits,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.orderProducts(orderId),
        data: {'produits': produits},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        Map<String, dynamic> orderData;
        if (data is Map) {
          orderData = data.containsKey('data')
              ? data['data'] as Map<String, dynamic>
              : data as Map<String, dynamic>;
        } else {
          return {'success': false, 'message': 'Format invalide'};
        }
        return {'success': true, 'order': Order.fromJson(orderData)};
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Erreur',
      };
    } on DioException catch (e) {
      String message = "Erreur lors de l'ajout des produits";
      if (e.response?.data is Map) {
        message = (e.response?.data as Map)['message'] ?? message;
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Erreur inattendue: $e'};
    }
  }

  /// Get current (active) orders for a table
  Future<List<Order>> getOrdersForTable(int tableId) async {
    try {
      final response = await _apiService.get(
        ApiConfig.orders,
        queryParameters: {'table_id': tableId, 'filter': 'current'},
      );
      if (response.statusCode == 200) {
        final data = response.data;
        List ordersData;
        if (data is List) {
          ordersData = data;
        } else if (data is Map && data['data'] != null) {
          ordersData = data['data'] as List;
        } else {
          return [];
        }
        final List<Order> orders = [];
        for (var json in ordersData) {
          try {
            if (json is Map<String, dynamic>) {
              orders.add(Order.fromJson(json));
            }
          } catch (_) {}
        }
        return orders;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Get a single order by ID
  Future<Order?> getOrder(int id) async {
    try {
      final response = await _apiService.get('${ApiConfig.orders}/$id');
      if (response.statusCode == 200) {
        final data = response.data;
        Map<String, dynamic> orderData;
        if (data is Map) {
          if (data.containsKey('data')) {
            orderData = data['data'] as Map<String, dynamic>;
          } else {
            orderData = data as Map<String, dynamic>;
          }
        } else {
          return null;
        }
        return Order.fromJson(orderData);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get invoice for an order
  Future<Invoice?> getInvoice(int orderId) async {
    try {
      final response = await _apiService.get(ApiConfig.orderInvoice(orderId));
      if (response.statusCode == 200) {
        final data = response.data;
        Map<String, dynamic> invoiceData;
        if (data is Map) {
          invoiceData = data.containsKey('data')
              ? data['data'] as Map<String, dynamic>
              : data as Map<String, dynamic>;
        } else {
          return null;
        }
        return Invoice.fromJson(invoiceData);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Launch an order (validate draft items)
  Future<Map<String, dynamic>> launchOrder(int orderId) async {
    try {
      final response = await _apiService.post(ApiConfig.launchOrder(orderId));
      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': true,
          'message': data['message'] ?? 'Commande lancée',
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Erreur',
      };
    } on DioException catch (e) {
      String message = 'Erreur lors du lancement';
      if (e.response?.data is Map) {
        message = (e.response?.data as Map)['message'] ?? message;
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  /// Cancel an entire order
  Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    try {
      final response = await _apiService.patch(
        ApiConfig.orderStatus(orderId),
        data: {'statut': 'annulee'},
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Commande annulée avec succès'};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Erreur lors de l\'annulation'};
    } on DioException catch (e) {
      String message = 'Erreur réseau';
      if (e.response?.data is Map) {
        message = (e.response?.data as Map)['message'] ?? message;
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Erreur inattendue: $e'};
    }
  }

  /// Remove a product from an order
  Future<Map<String, dynamic>> removeProductFromOrder(int orderId, int productId) async {
    try {
      final response = await _apiService.delete(ApiConfig.removeProduit(orderId, productId));
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Produit supprimé avec succès'};
      }
      return {'success': false, 'message': response.data['message'] ?? 'Erreur lors de la suppression'};
    } on DioException catch (e) {
      String message = 'Erreur réseau';
      if (e.response?.data is Map) {
        message = (e.response?.data as Map)['message'] ?? message;
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Erreur inattendue: $e'};
    }
  }
}
