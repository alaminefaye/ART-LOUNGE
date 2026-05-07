import '../core/api_client.dart';
import '../models/category.dart';
import '../models/product.dart';

class MenuService {
  MenuService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Category>> fetchCategories() async {
    final res = await _apiClient.dio.get('/categories');
    final data = _apiClient.extractData(res.data, (d) => d);
    if (data is List) {
      return data.whereType<Map>().map((m) => Category.fromJson(Map<String, dynamic>.from(m))).toList();
    }
    return const [];
  }

  Future<List<Product>> fetchProducts({int? categorieId}) async {
    final res = await _apiClient.dio.get(
      '/produits',
      queryParameters: categorieId != null ? {'categorie_id': categorieId} : null,
    );
    final data = _apiClient.extractData(res.data, (d) => d);
    if (data is List) {
      return data.whereType<Map>().map((m) => Product.fromJson(Map<String, dynamic>.from(m))).toList();
    }
    return const [];
  }
}

