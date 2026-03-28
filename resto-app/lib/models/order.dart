import 'package:flutter/foundation.dart';
import 'table.dart' as models;

enum OrderStatus {
  attente,
  preparation,
  servie,
  terminee,
  annulee;

  static OrderStatus fromString(String value) {
    switch (value) {
      case 'attente':
        return OrderStatus.attente;
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

/// Client fidélité rattaché à la commande (optionnel).
class OrderClient {
  final int id;
  final String nomComplet;
  final String? telephone;

  OrderClient({
    required this.id,
    required this.nomComplet,
    this.telephone,
  });

  factory OrderClient.fromJson(Map<String, dynamic> json) {
    return OrderClient(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      nomComplet: (json['nom_complet'] as String?)?.trim() ?? '',
      telephone: (json['telephone'] as String?)?.trim(),
    );
  }
}

class OrderItem {
  final int produitId;
  final String produitNom;
  final double prix;
  final int quantite;
  final String? image;
  final String? statut; // brouillon, envoye
  /// true si le serveur a déjà marqué cette ligne comme servie
  final bool servi;

  OrderItem({
    required this.produitId,
    required this.produitNom,
    required this.prix,
    required this.quantite,
    this.image,
    this.statut,
    this.servi = false,
  });

  double get total => prix * quantite;

  Map<String, dynamic> toJson() {
    return {'produit_id': produitId, 'quantite': quantite};
  }
}

class Order {
  final int id;
  final int tableId;
  final int? userId;
  final double montantTotal;
  final OrderStatus statut;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<OrderItem>? produits;
  final models.Table? table;
  final OrderClient? client;

  Order({
    required this.id,
    required this.tableId,
    this.userId,
    required this.montantTotal,
    required this.statut,
    required this.createdAt,
    this.updatedAt,
    this.produits,
    this.table,
    this.client,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      // Parsing sécurisé des produits
      List<OrderItem>? produits;
      if (json['produits'] != null && json['produits'] is List) {
        try {
          produits = (json['produits'] as List)
              .map((p) {
                try {
                  if (p is! Map) return null;

                  final pivot = p['pivot'] as Map<String, dynamic>?;
                  final produitId = p['id'] as int? ?? 0;
                  final produitNom = p['nom'] as String? ?? 'Produit inconnu';

                  // Helper pour convertir en double de manière sécurisée
                  double parseDouble(
                    dynamic value, [
                    double defaultValue = 0.0,
                  ]) {
                    if (value == null) return defaultValue;
                    if (value is num) return value.toDouble();
                    if (value is String) {
                      return double.tryParse(value) ?? defaultValue;
                    }
                    return defaultValue;
                  }

                  // Helper pour convertir en int de manière sécurisée
                  int parseInt(dynamic value, [int defaultValue = 0]) {
                    if (value == null) return defaultValue;
                    if (value is num) return value.toInt();
                    if (value is String) {
                      return int.tryParse(value) ?? defaultValue;
                    }
                    return defaultValue;
                  }

                  // L'API formatCommande retourne prix_unitaire directement dans le produit
                  // Mais peut aussi être dans pivot selon le contexte
                  double prix = 0.0;
                  if (p['prix_unitaire'] != null) {
                    prix = parseDouble(p['prix_unitaire']);
                  } else if (pivot != null && pivot['prix_unitaire'] != null) {
                    prix = parseDouble(pivot['prix_unitaire']);
                  } else if (pivot != null && pivot['prix'] != null) {
                    prix = parseDouble(pivot['prix']);
                  } else if (p['prix'] != null) {
                    prix = parseDouble(p['prix']);
                  }

                  int quantite = 1;
                  if (p['quantite'] != null) {
                    quantite = parseInt(p['quantite'], 1);
                  } else if (pivot != null && pivot['quantite'] != null) {
                    quantite = parseInt(pivot['quantite'], 1);
                  }

                  // servi: éviter null (API peut ne pas renvoyer le champ ou renvoyer null)
                  final rawServi = p['servi'];
                  final bool servi = (rawServi is bool)
                      ? rawServi
                      : (rawServi == true || rawServi == 1);

                  return OrderItem(
                    produitId: produitId,
                    produitNom: produitNom,
                    prix: prix,
                    quantite: quantite,
                    image: p['image'] as String?,
                    statut: p['statut'] ?? 'envoye',
                    servi: servi,
                  );
                } catch (e) {
                  debugPrint('Erreur parsing produit: $e');
                  debugPrint('Produit JSON: $p');
                  return null;
                }
              })
              .whereType<OrderItem>()
              .toList();
        } catch (e) {
          debugPrint('Erreur parsing liste produits: $e');
          produits = null;
        }
      }

      // Parsing sécurisé de la table
      models.Table? table;
      if (json['table'] != null && json['table'] is Map) {
        try {
          table = models.Table.fromJson(json['table'] as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Erreur parsing table: $e');
          table = null;
        }
      }

      // Helper pour convertir en double de manière sécurisée
      double parseDouble(dynamic value, [double defaultValue = 0.0]) {
        if (value == null) return defaultValue;
        if (value is num) return value.toDouble();
        if (value is String) {
          return double.tryParse(value) ?? defaultValue;
        }
        return defaultValue;
      }

      // Helper pour convertir en int de manière sécurisée
      int parseInt(dynamic value, [int defaultValue = 0]) {
        if (value == null) return defaultValue;
        if (value is num) return value.toInt();
        if (value is String) {
          return int.tryParse(value) ?? defaultValue;
        }
        return defaultValue;
      }

      OrderClient? client;
      if (json['client'] != null && json['client'] is Map) {
        try {
          final c = OrderClient.fromJson(json['client'] as Map<String, dynamic>);
          final hasPhone = c.telephone != null && c.telephone!.isNotEmpty;
          client =
              c.nomComplet.isNotEmpty || hasPhone ? c : null;
        } catch (_) {
          client = null;
        }
      }

      return Order(
        id: parseInt(json['id'], 0),
        tableId: parseInt(json['table_id'], 0),
        userId: json['user_id'] != null ? parseInt(json['user_id']) : null,
        montantTotal: parseDouble(json['montant_total'], 0.0),
        statut: OrderStatus.fromString(json['statut'] as String? ?? 'attente'),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        produits: produits,
        table: table,
        client: client,
      );
    } catch (e) {
      debugPrint('Erreur parsing Order: $e');
      debugPrint('JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table_id': tableId,
      'user_id': userId,
      'montant_total': montantTotal,
      'statut': statut.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (client != null)
        'client': {
          'id': client!.id,
          'nom_complet': client!.nomComplet,
          if (client!.telephone != null) 'telephone': client!.telephone,
        },
    };
  }
}
