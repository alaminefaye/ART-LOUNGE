import 'package:flutter/foundation.dart';
import '../models/serveur.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'local_cache.dart';

class ServeurService {
  final ApiService _apiService = ApiService();
  static const String _cacheServeursKey = 'cache_serveurs_v1';

  Future<List<Serveur>> getServeurs() async {
    try {
      final response = await _apiService.get(ApiConfig.serveurs);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> serveursJson = data['data'];
          final serveurs = serveursJson
              .map((json) => Serveur.fromJson(json as Map<String, dynamic>))
              .toList();
          try {
            await LocalCache.setJson(
              _cacheServeursKey,
              serveurs.map((s) => s.toJson()).toList(),
            );
          } catch (e) {
            if (kDebugMode) debugPrint('Cache serveurs write failed: $e');
          }
          return serveurs;
        }
      }
      final cached = await _loadServeursFromCache();
      return cached;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des serveurs: $e');
      final cached = await _loadServeursFromCache();
      return cached;
    }
  }

  Future<Serveur?> getServeurById(int id) async {
    final serveurs = await getServeurs();
    try {
      return serveurs.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Serveur>> _loadServeursFromCache() async {
    try {
      final raw = await LocalCache.getJson(_cacheServeursKey);
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => Serveur.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
