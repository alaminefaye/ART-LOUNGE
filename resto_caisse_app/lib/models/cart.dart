import 'package:flutter/foundation.dart';
import 'product.dart';
import 'order.dart';

class CartItem {
  final Product product;
  int quantite;
  bool isNew;

  CartItem({
    required this.product,
    this.quantite = 1,
    this.isNew = true,
  });

  double get total => product.prix * quantite;
}

class Cart extends ChangeNotifier {
  final List<CartItem> _items = [];
  int? _tableId;
  String? _tableNumero;
  Order? _activeOrder;

  List<CartItem> get items => List.unmodifiable(_items);
  int? get tableId => _tableId;
  String? get tableNumero => _tableNumero;
  Order? get activeOrder => _activeOrder;

  double get total {
    return _items.fold(0.0, (sum, item) => sum + item.total);
  }

  int get itemCount {
    return _items.fold(0, (sum, item) => sum + item.quantite);
  }

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  bool get hasNewItems => _items.any((item) => item.isNew);

  void setTable(int tableId, {String? tableNumero}) {
    _tableId = tableId;
    _tableNumero = tableNumero;
    notifyListeners();
  }

  void addProduct(Product product, {int quantite = 1}) {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantite += quantite;
    } else {
      _items.add(CartItem(product: product, quantite: quantite));
    }
    notifyListeners();
  }

  void removeProduct(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(int productId, int quantite) {
    if (quantite <= 0) {
      removeProduct(productId);
      return;
    }

    final item = _items.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => throw Exception('Produit non trouvé'),
    );
    item.quantite = quantite;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _tableId = null;
    _tableNumero = null;
    _activeOrder = null;
    notifyListeners();
  }

  void syncWithOrder(Order order) {
    _items.clear();
    _tableId = order.tableId;
    _tableNumero = order.table?.numero;
    _activeOrder = order;

    if (order.produits != null) {
      for (var p in order.produits!) {
        _items.add(CartItem(
          product: Product(
            id: p.produitId,
            nom: p.produitNom,
            prix: p.prix,
            categorieId: 0, // Not needed for cart display
            disponible: true,
          ),
          quantite: p.quantite,
          isNew: false,
        ));
      }
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> toJson() {
    return _items.map((item) => {
      'produit_id': item.product.id,
      'quantite': item.quantite,
    }).toList();
  }
}

