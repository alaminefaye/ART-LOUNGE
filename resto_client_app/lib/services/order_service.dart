import 'package:dio/dio.dart';

import '../core/api_client.dart';

class OrderService {
  OrderService(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> createEmporter({
    String? notes,
    required List<Map<String, dynamic>> produits,
  }) async {
    final res = await _apiClient.dio.post('/commandes/emporter', data: {
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      'produits': produits,
    });
    final data = res.data;
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    return {};
  }

  Future<List<Map<String, dynamic>>> fetchMyOrders({required bool current}) async {
    final res = await _apiClient.dio.get(
      '/commandes',
      queryParameters: {
        'filter': current ? 'current' : 'history',
        'sort': 'desc',
        'limit': 200,
      },
    );
    final data = _apiClient.extractData(res.data, (d) => d);
    if (data is List) {
      return data.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> initPaiement({
    required int commandeId,
    required String moyenPaiement,
    int? pointsUtilises,
  }) async {
    try {
      final res = await _apiClient.dio.post('/paiements', data: {
        'commande_id': commandeId,
        'moyen_paiement': moyenPaiement,
        if (pointsUtilises != null) 'points_utilises': pointsUtilises,
      });
      final data = res.data;
      if (data is Map && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      return {};
    } on DioException catch (e) {
      final message = e.response?.data is Map ? (e.response?.data['message'] as String?) : null;
      throw Exception(message ?? 'Erreur paiement');
    }
  }

  Future<void> confirmerPaiementWave({
    required int paiementId,
    required String transactionId,
  }) async {
    await _apiClient.dio.post(
      '/paiements/$paiementId/confirmer',
      data: {'transaction_id': transactionId},
    );
  }
}

