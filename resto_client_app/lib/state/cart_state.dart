import 'package:flutter/foundation.dart';

import '../models/product.dart';

class CartItem {
  CartItem({required this.product, required this.quantite});

  final Product product;
  int quantite;

  double get total => product.prix * quantite;
}

class CartState extends ChangeNotifier {
  final Map<int, CartItem> _itemsByProductId = {};

  List<CartItem> get items => _itemsByProductId.values.toList(growable: false);

  int get itemCount => _itemsByProductId.length;

  double get total => _itemsByProductId.values.fold(0, (sum, it) => sum + it.total);

  void add(Product product) {
    final existing = _itemsByProductId[product.id];
    if (existing != null) {
      existing.quantite += 1;
    } else {
      _itemsByProductId[product.id] = CartItem(product: product, quantite: 1);
    }
    notifyListeners();
  }

  void removeOne(int productId) {
    final existing = _itemsByProductId[productId];
    if (existing == null) return;
    if (existing.quantite <= 1) {
      _itemsByProductId.remove(productId);
    } else {
      existing.quantite -= 1;
    }
    notifyListeners();
  }

  void setQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      _itemsByProductId.remove(productId);
      notifyListeners();
      return;
    }
    final existing = _itemsByProductId[productId];
    if (existing == null) return;
    existing.quantite = quantity;
    notifyListeners();
  }

  void clear() {
    _itemsByProductId.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> toCommandeProduitsPayload() {
    return items
        .map(
          (it) => {
            'produit_id': it.product.id,
            'quantite': it.quantite,
          },
        )
        .toList(growable: false);
  }
}

