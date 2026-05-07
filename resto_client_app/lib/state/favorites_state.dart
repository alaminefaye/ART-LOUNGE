import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesState extends ChangeNotifier {
  static const _storageKey = 'favorite_product_ids';

  final Set<int> _ids = {};

  Set<int> get ids => Set<int>.unmodifiable(_ids);

  bool isFavorite(int productId) => _ids.contains(productId);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const [];
    _ids
      ..clear()
      ..addAll(raw.map(int.tryParse).whereType<int>());
    notifyListeners();
  }

  Future<void> toggle(int productId) async {
    if (_ids.contains(productId)) {
      _ids.remove(productId);
    } else {
      _ids.add(productId);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      _ids.map((e) => e.toString()).toList(growable: false),
    );
  }

  Future<void> clear() async {
    _ids.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

