import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/serveur.dart';
import 'api_service.dart';

class ServeurService {
  final ApiService _apiService = ApiService();

  Future<List<Serveur>> getServeurs() async {
    try {
      final response = await _apiService.get('/serveurs');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> serveursJson = data['data'];
          return serveursJson.map((json) => Serveur.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la récupération des serveurs: $e');
      return [];
    }
  }
}
