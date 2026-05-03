import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/caisse_session.dart';
import 'api_service.dart';
import 'local_cache.dart';

class CaisseService {
  final ApiService _apiService = ApiService();
  static const String _cacheSessionKey = 'cache_caisse_session_v1';

  // Récupérer la session actuelle
  Future<CaisseSession?> getCurrentSession() async {
    try {
      final response = await _apiService.get(ApiConfig.currentCaisseSession);
      if (response.statusCode == 200 && response.data['data'] != null) {
        final session = CaisseSession.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        try {
          await LocalCache.setJson(_cacheSessionKey, session.toJson());
        } catch (e) {
          if (kDebugMode) debugPrint('Cache session write failed: $e');
        }
        return session;
      }
      return null;
    } catch (e) {
      try {
        final raw = await LocalCache.getJson(_cacheSessionKey);
        if (raw is Map) {
          return CaisseSession.fromJson(Map<String, dynamic>.from(raw));
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Cache session read failed: $e');
      }
      return null;
    }
  }

  // Ouvrir une session
  Future<Map<String, dynamic>> openSession(double soldeOuverture) async {
    try {
      final response = await _apiService.post(
        ApiConfig.openCaisseSession,
        data: {'solde_ouverture': soldeOuverture},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final session = CaisseSession.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        try {
          await LocalCache.setJson(_cacheSessionKey, session.toJson());
        } catch (e) {
          if (kDebugMode) debugPrint('Cache session write failed: $e');
        }
        return {
          'success': true,
          'message': response.data['message'] ?? 'Session ouverte',
          'data': session,
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Erreur lors de l\'ouverture',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur de connexion',
      };
    }
  }

  // Obtenir le bilan
  Future<Map<String, dynamic>> getBilan() async {
    try {
      final response = await _apiService
          .get(ApiConfig.bilanCaisseSession)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data['data']};
      }
      return {
        'success': false,
        'message':
            response.data['message'] ??
            'Erreur lors de la récupération du bilan',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion ou timeout'};
    }
  }

  // Fermer la session
  Future<Map<String, dynamic>> closeSession(
    double soldeFermetureReel, {
    String? notes,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.closeCaisseSession,
        data: {'solde_fermeture_reel': soldeFermetureReel, 'notes': notes},
      );

      if (response.statusCode == 200) {
        final session = CaisseSession.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        try {
          await LocalCache.setJson(_cacheSessionKey, session.toJson());
        } catch (e) {
          if (kDebugMode) debugPrint('Cache session write failed: $e');
        }
        return {
          'success': true,
          'message': response.data['message'] ?? 'Session fermée',
          'data': session,
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Erreur lors de la fermeture',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Erreur de connexion',
      };
    }
  }
}
