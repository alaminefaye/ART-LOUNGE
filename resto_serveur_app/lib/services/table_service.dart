import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/table.dart';
import 'api_service.dart';

class TableService {
  final ApiService _apiService = ApiService();

  Future<List<RestaurantTable>> getTables() async {
    try {
      final response = await _apiService.get(ApiConfig.tables);
      if (response.statusCode == 200) {
        final data = response.data;
        List tablesData;
        if (data is List) {
          tablesData = data;
        } else if (data is Map && data['data'] is List) {
          tablesData = data['data'] as List;
        } else {
          return [];
        }
        return tablesData
            .map(
              (json) => RestaurantTable.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('TableService.getTables error: $e');
      return [];
    }
  }

  Future<RestaurantTable?> getTable(int id) async {
    try {
      final response = await _apiService.get('${ApiConfig.tables}/$id');
      if (response.statusCode == 200) {
        final data = response.data;
        Map<String, dynamic> tableData;
        if (data is Map) {
          tableData = data.containsKey('data')
              ? data['data'] as Map<String, dynamic>
              : data as Map<String, dynamic>;
        } else {
          return null;
        }
        return RestaurantTable.fromJson(tableData);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
