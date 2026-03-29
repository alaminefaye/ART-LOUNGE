import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/category.dart';
import '../models/product.dart';
import 'api_service.dart';

class MenuService {
  final ApiService _apiService = ApiService();

  // Récupérer toutes les catégories
  Future<List<Category>> getCategories() async {
    try {
      final response = await _apiService.get(ApiConfig.categories);

      if (response.statusCode == 200) {
        final data = response.data;

        // L'API peut retourner directement une liste ou dans 'data'
        List categoriesData;
        if (data is List) {
          categoriesData = data;
        } else if (data is Map && data.containsKey('data')) {
          if (data['data'] is List) {
            categoriesData = data['data'] as List;
          } else {
            return [];
          }
        } else if (data is Map && data.containsKey('success')) {
          if (data['data'] != null && data['data'] is List) {
            categoriesData = data['data'] as List;
          } else {
            return [];
          }
        } else {
          return [];
        }

        final categories = categoriesData.map((json) {
          try {
            return Category.fromJson(json as Map<String, dynamic>);
          } catch (_) {
            rethrow;
          }
        }).toList();

        return categories;
      }
      return [];
    } on DioException {
      rethrow; // Relancer l'exception pour qu'elle soit visible
    } catch (_) {
      rethrow;
    }
  }

  // Récupérer tous les produits
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

        // L'API peut retourner directement une liste ou dans 'data'
        List productsData;
        if (data is List) {
          productsData = data;
        } else if (data is Map && data.containsKey('data')) {
          if (data['data'] is List) {
            productsData = data['data'] as List;
          } else {
            return [];
          }
        } else if (data is Map && data.containsKey('success')) {
          if (data['data'] != null && data['data'] is List) {
            productsData = data['data'] as List;
          } else {
            return [];
          }
        } else {
          return [];
        }

        final products = productsData.map((json) {
          try {
            return Product.fromJson(json as Map<String, dynamic>);
          } catch (_) {
            rethrow;
          }
        }).toList();

        return products;
      }
      return [];
    } on DioException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  // Récupérer un produit par ID
  Future<Product?> getProduct(int id) async {
    try {
      final response = await _apiService.get('${ApiConfig.products}/$id');
      if (response.statusCode == 200) {
        final data = response.data;
        // L'API peut retourner directement l'objet ou dans 'data'
        Map<String, dynamic> productData;
        if (data is Map) {
          productData = data.containsKey('data')
              ? data['data'] as Map<String, dynamic>
              : data as Map<String, dynamic>;
        } else {
          return null;
        }
        return Product.fromJson(productData);
      }
      return null;
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
