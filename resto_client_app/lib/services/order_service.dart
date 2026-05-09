import 'package:dio/dio.dart';

import '../core/api_client.dart';

class OrderService {
  OrderService(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> createEmporter({
    String? notes,
    required List<Map<String, dynamic>> produits,
    bool isPassager = false,
    int? trajetId,
    String? numeroSiege,
    String? heureDepart,
  }) async {
    try {
      final res = await _apiClient.dio.post(
        'commandes/emporter',
        data: {
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
          if (isPassager) 'is_passager': true,
          if (isPassager) 'trajet_id': trajetId,
          if (isPassager) 'numero_siege': numeroSiege,
          if (isPassager) 'heure_depart': heureDepart,
          'produits': produits,
        },
      );
      final data = res.data;
      if (data is Map && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      return {};
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message'] as String?)
          : null;
      throw Exception(message ?? 'Erreur création commande');
    }
  }

  Future<List<Map<String, dynamic>>> fetchTrajets() async {
    final res = await _apiClient.dio.get('trajets');
    final data = _apiClient.extractData(res.data, (d) => d);
    if (data is List) {
      return data
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> fetchMyOrders({
    required bool current,
  }) async {
    final res = await _apiClient.dio.get(
      'commandes',
      queryParameters: {
        'filter': current ? 'current' : 'history',
        'sort': 'desc',
        'limit': 200,
      },
    );
    final data = _apiClient.extractData(res.data, (d) => d);
    if (data is List) {
      return data
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return const [];
  }

  /// Détail complet d’une commande (produits, notes, lieu…).
  Future<Map<String, dynamic>> fetchOrderById(int id) async {
    try {
      final res = await _apiClient.dio.get('commandes/$id');
      final status = res.statusCode ?? 0;
      final body = res.data;

      if (status >= 400) {
        final msg = body is Map
            ? _apiClient.extractMessage(body)
            : 'Commande inaccessible';
        throw Exception(msg);
      }

      if (body is Map) {
        if (body['success'] == false) {
          throw Exception(_apiClient.extractMessage(body));
        }
        final inner = body['data'];
        if (inner is Map) {
          return Map<String, dynamic>.from(inner);
        }
      }
      throw Exception('Réponse invalide du serveur');
    } on DioException catch (e) {
      final data = e.response?.data;
      throw Exception(
        data is Map ? _apiClient.extractMessage(data) : 'Erreur réseau',
      );
    }
  }

  Future<Map<String, dynamic>> fetchFactureForOrder(int commandeId) async {
    try {
      final res = await _apiClient.dio.get('commandes/$commandeId/facture');
      final status = res.statusCode ?? 0;
      final body = res.data;

      if (status >= 400) {
        final msg = body is Map
            ? _apiClient.extractMessage(body)
            : 'Facture inaccessible';
        throw Exception(msg);
      }

      if (body is Map) {
        if (body['success'] == false) {
          throw Exception(_apiClient.extractMessage(body));
        }
        final inner = body['data'];
        if (inner is Map) {
          return Map<String, dynamic>.from(inner);
        }
      }
      throw Exception('Réponse invalide du serveur');
    } on DioException catch (e) {
      final data = e.response?.data;
      throw Exception(
        data is Map ? _apiClient.extractMessage(data) : 'Erreur réseau',
      );
    }
  }

  Future<Map<String, dynamic>> initPaiement({
    required int commandeId,
    required String moyenPaiement,
    int? pointsUtilises,
  }) async {
    try {
      final res = await _apiClient.dio.post(
        'paiements',
        data: {
          'commande_id': commandeId,
          'moyen_paiement': moyenPaiement,
          'points_utilises': ?pointsUtilises,
        },
      );
      final data = res.data;
      if (data is Map && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      return {};
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message'] as String?)
          : null;
      throw Exception(message ?? 'Erreur paiement');
    }
  }

  Future<void> confirmerPaiementWave({
    required int paiementId,
    required String transactionId,
  }) async {
    await _apiClient.dio.post(
      'paiements/$paiementId/confirmer',
      data: {'transaction_id': transactionId},
    );
  }

  Future<String> createWaveCheckoutSession({required int paiementId}) async {
    try {
      final res = await _apiClient.dio.post(
        'paiements/$paiementId/wave/checkout',
      );
      final data = res.data;
      if (data is Map && data['data'] is Map) {
        final d = Map<String, dynamic>.from(data['data'] as Map);
        final url = d['payment_url']?.toString();
        if (url != null && url.trim().isNotEmpty) return url;
      }
      throw Exception('URL Wave introuvable');
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message'] as String?)
          : null;
      throw Exception(message ?? 'Erreur Wave');
    }
  }
}
