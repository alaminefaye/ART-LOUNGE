import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/category.dart';
import '../models/product.dart';
import 'api_service.dart';
import 'local_cache.dart';

class MenuService {
  final ApiService _apiService = ApiService();
  static const String _cacheCategoriesKey = 'cache_categories_v1';
  static const String _cacheProductsKey = 'cache_products_v1';

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

        final List<Category> categories = categoriesData
            .map((json) => Category.fromJson(json as Map<String, dynamic>))
            .toList();

        try {
          await LocalCache.setJson(
            _cacheCategoriesKey,
            categories.map((c) => c.toJson()).toList(),
          );
        } catch (e) {
          final _ = e;
        }

        return categories;
      }
      return [];
    } on DioException {
      final cached = await _loadCategoriesFromCache();
      if (cached.isNotEmpty) return cached;
      return [];
    } catch (e) {
      final cached = await _loadCategoriesFromCache();
      if (cached.isNotEmpty) return cached;
      return [];
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

        final List<Product> products = productsData
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();

        if (categoryId == null) {
          try {
            await LocalCache.setJson(
              _cacheProductsKey,
              products.map((p) => p.toJson()).toList(),
            );
          } catch (e) {
            final _ = e;
          }
        }

        return products;
      }
      return [];
    } on DioException {
      final cached = await _loadProductsFromCache();
      if (cached.isEmpty) return [];
      if (categoryId == null) return cached;
      return cached.where((p) => p.categorieId == categoryId).toList();
    } catch (e) {
      final cached = await _loadProductsFromCache();
      if (cached.isEmpty) return [];
      if (categoryId == null) return cached;
      return cached.where((p) => p.categorieId == categoryId).toList();
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
      final cached = await _loadProductsFromCache();
      try {
        return cached.firstWhere((p) => p.id == id);
      } catch (_) {
        return null;
      }
    } catch (e) {
      final cached = await _loadProductsFromCache();
      try {
        return cached.firstWhere((p) => p.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  Future<List<Category>> _loadCategoriesFromCache() async {
    try {
      final raw = await LocalCache.getJson(_cacheCategoriesKey);
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Product>> _loadProductsFromCache() async {
    try {
      final raw = await LocalCache.getJson(_cacheProductsKey);
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
