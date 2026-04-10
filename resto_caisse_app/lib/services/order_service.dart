import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/order.dart';
import 'api_service.dart';

class OrderService {
  final ApiService _apiService = ApiService();

  // Créer une commande
  Future<Map<String, dynamic>> createOrder({
    required int tableId,
    required int serveurId, // Nouveau paramètre obligatoire
    required List<Map<String, dynamic>> produits,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.orders,
        data: {
          'table_id': tableId, 
          'serveur_id': serveurId,
          'produits': produits
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        // L'API peut retourner directement l'objet ou dans 'data'
        Map<String, dynamic> orderData;
        if (data is Map) {
          orderData = data.containsKey('data')
              ? data['data'] as Map<String, dynamic>
              : data as Map<String, dynamic>;
        } else {
          return {'success': false, 'message': 'Format de réponse invalide'};
        }
        return {'success': true, 'order': Order.fromJson(orderData)};
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors de la création',
        };
      }
    } on DioException catch (e) {
      String message = 'Erreur lors de la création de la commande';
      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'] as String;
        } else if (data is Map && data['errors'] != null) {
          final errors = data['errors'] as Map;
          if (errors.isNotEmpty) {
            message = (errors.values.first as List).first as String;
          }
        }
        if (e.response?.statusCode == 422) {
          message = message;
        } else if (e.response?.statusCode == 401) {
          message = 'Non autorisé. Veuillez vous reconnecter.';
        } else if (e.response?.statusCode == 403) {
          message = 'Non autorisé. Veuillez vous reconnecter.';
        } else if (e.response?.statusCode == 500) {
          message = 'Erreur serveur. Veuillez réessayer plus tard.';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message =
            'Délai d\'attente dépassé. Vérifiez votre connexion internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        message =
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
      };
    }
  }

  // Lancer une commande (valider les produits en brouillon)
  Future<Map<String, dynamic>> launchOrder(int orderId) async {
    try {
      final response = await _apiService.post(
        '${ApiConfig.orders}/$orderId/lancer',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': true,
          'message': data['message'] ?? 'Commande lancée',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors du lancement',
        };
      }
    } on DioException catch (e) {
      String message = 'Erreur lors du lancement de la commande';
      if (e.response != null && e.response?.data is Map) {
        final data = e.response?.data as Map;
        message = data['message'] ?? message;
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
      };
    }
  }

  // Récupérer toutes les commandes (compatibilité)
  Future<List<Order>> getOrders() async {
    return getHistoryOrders();
  }

  // Récupérer les commandes du jour non terminées (Mes commandes)
  Future<List<Order>> getCurrentOrders() async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.orders}?filter=current',
      );
      if (response.statusCode == 200) {
        final data = response.data;
        // L'API peut retourner directement une liste ou dans 'data'
        List ordersData;
        if (data is List) {
          ordersData = data;
        } else if (data is Map && data['data'] != null) {
          ordersData = data['data'] as List;
        } else {
          return [];
        }

        // Parsing sécurisé avec gestion des erreurs
        List<Order> orders = [];
        for (var json in ordersData) {
          try {
            if (json is Map<String, dynamic>) {
              final order = Order.fromJson(json);
              orders.add(order);
            }
          } catch (_) {
            // Continue avec les autres commandes même si une échoue
          }
        }
        return orders;
      }
      return [];
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  // Récupérer la commande active d'une table
  Future<Order?> getActiveOrderByTable(int tableId) async {
    try {
      final orders = await getCurrentOrders();
      final list = orders.where((o) => o.tableId == tableId && o.statut != OrderStatus.terminee && o.statut != OrderStatus.annulee).toList();
      return list.isNotEmpty ? list.first : null;
    } catch (_) {
      return null;
    }
  }

  /// Historique complet (personnel) : toutes dates / statuts, recherche et tri côté API.
  Future<List<Order>> getStaffOrderHistory({
    String search = '',
    bool newestFirst = true,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.orders,
        queryParameters: <String, dynamic>{
          'filter': 'staff_all',
          'sort': newestFirst ? 'desc' : 'asc',
          if (search.trim().isNotEmpty) 'search': search.trim(),
        },
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
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  // Récupérer les commandes terminées (Historique)
  Future<List<Order>> getHistoryOrders() async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.orders}?filter=history',
      );
      if (response.statusCode == 200) {
        final data = response.data;
        // L'API peut retourner directement une liste ou dans 'data'
        List ordersData;
        if (data is List) {
          ordersData = data;
        } else if (data is Map && data['data'] != null) {
          ordersData = data['data'] as List;
        } else {
          return [];
        }

        // Parsing sécurisé avec gestion des erreurs
        List<Order> orders = [];
        for (var json in ordersData) {
          try {
            if (json is Map<String, dynamic>) {
              final order = Order.fromJson(json);
              orders.add(order);
            }
          } catch (_) {
            // Continue avec les autres commandes même si une échoue
          }
        }
        return orders;
      }
      return [];
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  // Récupérer une commande par ID
  Future<Order?> getOrder(int id) async {
    try {
      final response = await _apiService.get('${ApiConfig.orders}/$id');
      if (response.statusCode == 200) {
        final data = response.data;
        // L'API peut retourner directement l'objet ou dans 'data'
        Map<String, dynamic> orderData;
        if (data is Map) {
          if (data.containsKey('success') &&
              data['success'] == true &&
              data.containsKey('data')) {
            // Format: {'success': true, 'data': {...}}
            orderData = data['data'] as Map<String, dynamic>;
          } else if (data.containsKey('data')) {
            // Format: {'data': {...}}
            orderData = data['data'] as Map<String, dynamic>;
          } else {
            // Format direct: {...}
            orderData = data as Map<String, dynamic>;
          }
        } else {
          return null;
        }

        try {
          return Order.fromJson(orderData);
        } catch (e) {
          return null;
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.response != null) {}
      return null;
    } catch (e) {
      return null;
    }
  }

  // Mettre à jour le statut d'une commande
  Future<bool> updateOrderStatus(int id, OrderStatus status) async {
    try {
      final response = await _apiService.patch(
        ApiConfig.orderStatus(id),
        data: {'statut': status.name},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Mettre à jour le statut d'une commande avec retour détaillé
  Future<Map<String, dynamic>> updateOrderStatusDetailed(
    int id,
    OrderStatus status,
  ) async {
    try {
      // Try specific status endpoint first
      try {
        final response = await _apiService.patch(
          ApiConfig.orderStatus(id),
          data: {'statut': status.name},
        );
        if (response.statusCode == 200) {
          return {'success': true};
        }
      } on DioException catch (e) {
        // If specific endpoint fails with 403/401, try the generic update endpoint
        if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
          final responseUpdate = await _apiService.patch(
            '${ApiConfig.orders}/$id',
            data: {'statut': status.name},
          );
          if (responseUpdate.statusCode == 200) {
            return {'success': true};
          } else {
            // Fallback to original error if generic update also fails (or use the new error)
            String message =
                responseUpdate.data['message'] ??
                'Erreur serveur (${responseUpdate.statusCode})';
            return {'success': false, 'message': message};
          }
        }
        rethrow; // Rethrow if it's not a permission error
      }
      return {
        'success': false,
        'message': 'Erreur inconnue',
      }; // Should not reach here if 200
    } on DioException catch (e) {
      String message = 'Erreur réseau';
      if (e.response?.data is Map) {
        message = (e.response?.data as Map)['message'] ?? message;
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Ajouter un produit à une commande existante
  Future<Map<String, dynamic>> addProductToOrder({
    required int orderId,
    required int produitId,
    required int quantite,
    String? notes,
  }) async {
    try {
      final response = await _apiService.post(
        '${ApiConfig.orders}/$orderId/produits',
        data: {
          'produit_id': produitId,
          'quantite': quantite,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
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
      } else {
        return {
          'success': false,
          'message':
              response.data['message'] ?? 'Erreur lors de l\'ajout du produit',
        };
      }
    } on DioException catch (e) {
      String message = 'Erreur lors de l\'ajout du produit';
      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'] as String;
        }
        if (e.response?.statusCode == 403) {
          message = 'Non autorisé. Veuillez vous reconnecter.';
        } else if (e.response?.statusCode == 400) {
          message =
              data['message'] ?? 'Cette commande ne peut plus être modifiée';
        }
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur inattendue: ${e.toString()}',
      };
    }
  }

  /// Marque comme servis tous les produits pas encore servis de la commande.
  /// Les nouveaux produits ajoutés ensuite par le client restent "non servis".
  Future<Map<String, dynamic>> marquerServi(int orderId) async {
    try {
      final response = await _apiService.post(
        ApiConfig.marquerServi(orderId),
      );
      final data = response.data;
      if (response.statusCode == 200) {
        Map<String, dynamic>? orderData;
        if (data is Map && data['data'] != null) {
          orderData = data['data'] as Map<String, dynamic>;
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Produits marqués comme servis',
          if (orderData != null) 'order': Order.fromJson(orderData),
        };
      }
      return {
        'success': false,
        'message': (data is Map ? data['message'] : null) ?? 'Erreur serveur',
      };
    } on DioException catch (e) {
      String message = 'Erreur réseau';
      if (e.response?.data is Map) {
        message = (e.response!.data as Map)['message'] ?? message;
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Supprimer un produit d'une commande
  Future<Map<String, dynamic>> removeProductFromOrder(
    int orderId,
    int productId,
  ) async {
    try {
      final response = await _apiService.delete(
        ApiConfig.removeProduct(orderId, productId),
      );
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Erreur serveur',
      };
    } on DioException catch (e) {
      String message = 'Erreur réseau';
      if (e.response?.data is Map) {
        message = (e.response!.data as Map)['message'] ?? message;
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
