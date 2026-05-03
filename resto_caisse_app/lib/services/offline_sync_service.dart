import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import 'api_service.dart';
import 'offline_queue_service.dart';

class OfflineSyncService {
  final ApiService _apiService = ApiService();
  final OfflineQueueService _queue = OfflineQueueService();

  Future<void> trySync() async {
    final items = await _queue.getAll();
    if (items.isEmpty) return;

    final online = await _isOnline();
    if (!online) return;

    for (final item in items) {
      final ok = await _process(item);
      if (ok) {
        await _queue.removeById(item.id);
      }
    }
  }

  Future<bool> _process(OfflineQueueItem item) async {
    if (item.type == 'create_order') {
      try {
        final payload = Map<String, dynamic>.from(item.payload);
        final shouldLaunch = payload.remove('_launch') == true;
        final response = await _apiService.post(ApiConfig.orders, data: payload);
        if (response.statusCode == 200 || response.statusCode == 201) {
          int? createdOrderId;
          final data = response.data;
          if (data is Map) {
            final content = data['data'];
            if (content is Map && content['id'] != null) {
              createdOrderId = int.tryParse('${content['id']}');
            } else if (data['id'] != null) {
              createdOrderId = int.tryParse('${data['id']}');
            }
          }

          if (shouldLaunch && createdOrderId != null) {
            try {
              await _apiService.post(ApiConfig.launchOrder(createdOrderId));
            } catch (e) {
              if (kDebugMode) debugPrint('Offline sync launchOrder failed: $e');
            }
          }
          return true;
        }
        return false;
      } on DioException {
        return false;
      } catch (_) {
        return false;
      }
    }

    return true;
  }

  Future<bool> _isOnline() async {
    try {
      final response = await _apiService.get(
        ApiConfig.categories,
        queryParameters: const {'_ping': 1},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return false;
      }
      return false;
    } catch (e) {
      debugPrint('OfflineSyncService _isOnline error: $e');
      return false;
    }
  }
}
