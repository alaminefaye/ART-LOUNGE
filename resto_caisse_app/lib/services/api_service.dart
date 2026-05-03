import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ApiService {
  static ApiService? _instance;
  late Dio _dio;
  String? _token;
  
  // Singleton pattern
  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Interceptor pour ajouter le token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          options.headers['Content-Type'] = 'application/json';
          options.headers['Accept'] = 'application/json';
          return handler.next(options);
        },
        onError: (error, handler) {
          // Gestion des erreurs
          return handler.next(error);
        },
      ),
    );
  }
  
  factory ApiService() {
    _instance ??= ApiService._internal();
    return _instance!;
  }


  void setToken(String? token) {
    _token = token;
  }

  // GET request
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _executeWithFallback(
      () => _dio.get(endpoint, queryParameters: queryParameters),
    );
  }

  // POST request
  Future<Response> post(String endpoint, {dynamic data}) async {
    return _executeWithFallback(() => _dio.post(endpoint, data: data));
  }

  // PUT request
  Future<Response> put(String endpoint, {dynamic data}) async {
    return _executeWithFallback(() => _dio.put(endpoint, data: data));
  }

  // PATCH request
  Future<Response> patch(String endpoint, {dynamic data}) async {
    return _executeWithFallback(() => _dio.patch(endpoint, data: data));
  }

  // DELETE request
  Future<Response> delete(String endpoint) async {
    return _executeWithFallback(() => _dio.delete(endpoint));
  }

  Future<Response> _executeWithFallback(
    Future<Response> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (e) {
      // Fallback uniquement sur erreurs de connexion (DNS/réseau/certif)
      if (e.type != DioExceptionType.connectionError) rethrow;

      final originalBaseUrl = _dio.options.baseUrl;
      for (final candidate in ApiConfig.fallbackBaseUrls) {
        if (candidate == originalBaseUrl) continue;
        try {
          _dio.options.baseUrl = candidate;
          return await request();
        } on DioException catch (retryError) {
          if (retryError.type != DioExceptionType.connectionError) {
            rethrow;
          }
          // sinon on tente le prochain candidat
        }
      }

      // Restaurer avant de remonter l'erreur initiale.
      _dio.options.baseUrl = originalBaseUrl;
      rethrow;
    }
  }
}
