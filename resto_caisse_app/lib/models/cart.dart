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
  int? _serveurId;
  String? _serveurNom;
  Order? _activeOrder;

  List<CartItem> get items => List.unmodifiable(_items);
  int? get tableId => _tableId;
  String? get tableNumero => _tableNumero;
  int? get serveurId => _serveurId;
  String? get serveurNom => _serveurNom;
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

  void setTable(int tableId, {String? tableNumero, int? serveurId, String? serveurNom}) {
    if (_tableId != tableId) {
      _items.clear();
      _activeOrder = null;
    }
    _tableId = tableId;
    _tableNumero = tableNumero;
    _serveurId = serveurId;
    _serveurNom = serveurNom;
    notifyListeners();
  }

  void addProduct(Product product, {int quantite = 1}) {
    // On cherche d'abord s'il y a déjà cet article en mode "NOUVEAU" (pas encore envoyé)
    final existingNewIndex = _items.indexWhere(
      (item) => item.product.id == product.id && item.isNew,
    );

    if (existingNewIndex >= 0) {
      _items[existingNewIndex].quantite += quantite;
    } else {
      // Si on n'a pas trouvé d'article "NOUVEAU", on en crée un, même si l'article existe déjà en mode "DÉJÀ ENVOYÉ"
      _items.add(CartItem(product: product, quantite: quantite, isNew: true));
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
    _serveurId = null;
    _serveurNom = null;
    _activeOrder = null;
    notifyListeners();
  }

  void syncWithOrder(Order order) {
    _items.clear();
    _tableId = order.tableId;
    _tableNumero = order.table?.numero;
    _serveurId = order.serveur?.id;
    _serveurNom = order.serveur != null ? (order.serveur!.nom + (order.serveur!.prenom != null ? ' ${order.serveur!.prenom}' : '')) : null;
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

