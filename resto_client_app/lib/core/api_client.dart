import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';

class ApiClient {
  ApiClient({Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              headers: {'Accept': 'application/json'},
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 600,
            ),
          ) {
    if (kDebugMode) {
      this.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('[API] ${options.method} ${options.uri}');
            handler.next(options);
          },
          onError: (e, handler) {
            debugPrint(
              '[API] ERROR ${e.requestOptions.method} ${e.requestOptions.uri} -> ${e.response?.statusCode}',
            );
            handler.next(e);
          },
        ),
      );
    }
  }

  final Dio dio;

  void setAuthToken(String? token) {
    if (token == null || token.isEmpty) {
      dio.options.headers.remove('Authorization');
      return;
    }
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  T extractData<T>(dynamic json, T Function(dynamic) mapper) {
    if (json is Map && json.containsKey('data')) {
      return mapper(json['data']);
    }
    return mapper(json);
  }

  String extractMessage(dynamic json) {
    if (json is Map && json['message'] is String) {
      return json['message'] as String;
    }
    return 'Erreur inconnue';
  }
}
