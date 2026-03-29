import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/table.dart' as models;
import 'api_service.dart';

class TableService {
  final ApiService _apiService = ApiService();

  // Récupérer une table par numéro (peut être String comme "T1" ou int comme 1)
  Future<models.Table?> getTableByNumber(dynamic numero) async {
    try {
      // Récupérer toutes les tables et filtrer par numéro
      final tables = await getTables();
      final numeroStr = numero.toString();
      for (var table in tables) {
        if (table.numero.toString() == numeroStr) {
          return table;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Récupérer une table par ID
  Future<models.Table?> getTable(int id) async {
    try {
      final response = await _apiService.get('${ApiConfig.tables}/$id');
      if (response.statusCode == 200) {
        final data = response.data;
        // L'API peut retourner directement l'objet ou dans 'data'
        Map<String, dynamic> tableData;
        if (data is Map) {
          tableData = data.containsKey('data')
              ? data['data'] as Map<String, dynamic>
              : data as Map<String, dynamic>;
        } else {
          return null;
        }
        return models.Table.fromJson(tableData);
      }
      return null;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  // Récupérer une table via l'endpoint menu (pour le scan QR)
  Future<models.Table?> getTableFromMenuEndpoint(int id) async {
    try {
      final response = await _apiService.get('${ApiConfig.tables}/$id/menu');

      if (response.statusCode == 200) {
        final data = response.data;
        // L'API retourne les données dans 'data.table'
        Map<String, dynamic>? tableData;
        if (data is Map) {
          if (data.containsKey('data') && data['data'] is Map) {
            final dataMap = data['data'] as Map<String, dynamic>;
            if (dataMap.containsKey('table')) {
              tableData = dataMap['table'] as Map<String, dynamic>;
            } else {
              // Fallback: utiliser directement data['data'] si c'est déjà la table
              tableData = dataMap;
            }
          } else if (data.containsKey('table')) {
            tableData = data['table'] as Map<String, dynamic>;
          } else if (data.containsKey('success') && data['success'] == true) {
            // Si la réponse est directement la table
            tableData = data as Map<String, dynamic>;
          }
        }

        if (tableData != null) {
          try {
            final table = models.Table.fromJson(tableData);
            return table;
          } catch (e) {
            rethrow;
          }
        } else {}
      }
      return null;
    } on DioException catch (e) {
      if (e.response != null) {
        // Lancer une exception avec le message d'erreur de l'API
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw Exception(
        'Table introuvable (ID: $id). Vérifiez le QR code scanné.',
      );
    } catch (_) {
      rethrow;
    }
  }

  // Récupérer toutes les tables
  Future<List<models.Table>> getTables() async {
    try {
      final response = await _apiService.get(ApiConfig.tables);
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((json) => models.Table.fromJson(json)).toList();
      }
      debugPrint('Erreur getTables: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Exception getTables: $e');
      return [];
    }
  }
}
