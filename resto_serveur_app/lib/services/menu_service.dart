import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/category.dart';
import '../models/product.dart';
import 'api_service.dart';

class MenuService {
  final ApiService _apiService = ApiService();

  Future<List<Category>> getCategories() async {
    try {
      final response = await _apiService.get(ApiConfig.categories);
      if (response.statusCode == 200) {
        final data = response.data;
        List categoriesData;
        if (data is List) {
          categoriesData = data;
        } else if (data is Map && data['data'] is List) {
          categoriesData = data['data'] as List;
        } else {
          return [];
        }
        return categoriesData
            .map((json) => Category.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException {
      rethrow;
    }
  }

  Future<List<Product>> getProducts({int? categoryId}) async {
    try {
      final response = await _apiService.get(
        ApiConfig.products,
        queryParameters: categoryId != null
            ? {'categorie_id': categoryId}
            : null,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        List productsData;
        if (data is List) {
          productsData = data;
        } else if (data is Map && data['data'] is List) {
          productsData = data['data'] as List;
        } else {
          return [];
        }
        return productsData
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException {
      rethrow;
    }
  }
}
