import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/caisse_session.dart';
import 'api_service.dart';

class CaisseService {
  final ApiService _apiService = ApiService();

  // Récupérer la session actuelle
  Future<CaisseSession?> getCurrentSession() async {
    try {
      final response = await _apiService.get(ApiConfig.currentCaisseSession);
      if (response.statusCode == 200 && response.data['data'] != null) {
        return CaisseSession.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
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
        return {
          'success': true,
          'message': response.data['message'] ?? 'Session ouverte',
          'data': CaisseSession.fromJson(response.data['data']),
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
      final response = await _apiService.get(ApiConfig.bilanCaisseSession);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Erreur lors de la récupération du bilan',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur inattendue'};
    }
  }

  // Fermer la session
  Future<Map<String, dynamic>> closeSession(double soldeFermetureReel, {String? notes}) async {
    try {
      final response = await _apiService.post(
        ApiConfig.closeCaisseSession,
        data: {
          'solde_fermeture_reel': soldeFermetureReel,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Session fermée',
          'data': CaisseSession.fromJson(response.data['data']),
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
