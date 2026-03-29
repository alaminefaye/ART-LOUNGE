import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/client_fid.dart';
import 'api_service.dart';

class ClientService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> searchByPhone(String phone) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.baseUrl}/clients/search',
        queryParameters: {'phone': phone},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'success': true,
          'client': ClientFid.fromJson(response.data['data']),
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Client non trouvé',
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'success': false, 'message': 'Client non trouvé'};
      }
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Erreur lors de la recherche',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
