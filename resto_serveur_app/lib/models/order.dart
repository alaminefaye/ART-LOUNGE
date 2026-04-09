import 'table.dart';

enum OrderStatus {
  attente,
  preparation,
  servie,
  terminee,
  annulee;

  static OrderStatus fromString(String value) {
    switch (value) {
      case 'preparation':
        return OrderStatus.preparation;
      case 'servie':
        return OrderStatus.servie;
      case 'terminee':
        return OrderStatus.terminee;
      case 'annulee':
        return OrderStatus.annulee;
      default:
        return OrderStatus.attente;
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.attente:
        return 'En attente';
      case OrderStatus.preparation:
        return 'En préparation';
      case OrderStatus.servie:
        return 'Servie';
      case OrderStatus.terminee:
        return 'Terminée';
      case OrderStatus.annulee:
        return 'Annulée';
    }
  }
}

class OrderItem {
  final int produitId;
  final String produitNom;
  final double prix;
  final int quantite;
  final String? statut;
  final bool servi;

  OrderItem({
    required this.produitId,
    required this.produitNom,
    required this.prix,
    required this.quantite,
    this.statut,
    this.servi = false,
  });

  double get total => prix * quantite;
}

class Order {
  final int id;
  final int tableId;
  final double montantTotal;
  final OrderStatus statut;
  final DateTime createdAt;
  final List<OrderItem>? produits;
  final RestaurantTable? table;

  Order({
    required this.id,
    required this.tableId,
    required this.montantTotal,
    required this.statut,
    required this.createdAt,
    this.produits,
    this.table,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, [double def = 0.0]) {
      if (value == null) return def;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? def;
      return def;
    }

    int parseInt(dynamic value, [int def = 0]) {
      if (value == null) return def;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? def;
      return def;
    }

    List<OrderItem>? produits;
    if (json['produits'] != null && json['produits'] is List) {
      produits = (json['produits'] as List)
          .map((p) {
            if (p is! Map) return null;
            final pivot = p['pivot'] as Map<String, dynamic>?;

            double prix = 0.0;
            if (p['prix_unitaire'] != null) {
              prix = parseDouble(p['prix_unitaire']);
            } else if (pivot != null && pivot['prix_unitaire'] != null) {
              prix = parseDouble(pivot['prix_unitaire']);
            } else if (p['prix'] != null) {
              prix = parseDouble(p['prix']);
            }

            int quantite = 1;
            if (p['quantite'] != null) {
              quantite = parseInt(p['quantite'], 1);
            } else if (pivot != null && pivot['quantite'] != null) {
              quantite = parseInt(pivot['quantite'], 1);
            }

            final rawServi = p['servi'];
            final bool servi = (rawServi is bool)
                ? rawServi
                : (rawServi == true || rawServi == 1);

            return OrderItem(
              produitId: parseInt(p['id']),
              produitNom: p['nom'] as String? ?? 'Produit',
              prix: prix,
              quantite: quantite,
              statut: p['statut'] ?? 'envoye',
              servi: servi,
            );
          })
          .whereType<OrderItem>()
          .toList();
    }

    RestaurantTable? table;
    if (json['table'] != null && json['table'] is Map) {
      try {
        table = RestaurantTable.fromJson(json['table'] as Map<String, dynamic>);
      } catch (_) {}
    }

    return Order(
      id: parseInt(json['id']),
      tableId: parseInt(
        json['table_id'] ??
            ((json['table'] is Map) ? (json['table'] as Map)['id'] : null),
      ),
      montantTotal: parseDouble(json['montant_total']),
      statut: OrderStatus.fromString(json['statut'] as String? ?? 'attente'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      produits: produits,
      table: table,
    );
  }
}
