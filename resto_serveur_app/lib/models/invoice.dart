import 'order.dart';

class Invoice {
  final int id;
  final String numeroFacture;
  final int commandeId;
  final double montantTotal;
  final double montantTaxe;
  final DateTime createdAt;
  final Order? commande;

  Invoice({
    required this.id,
    required this.numeroFacture,
    required this.commandeId,
    required this.montantTotal,
    required this.montantTaxe,
    required this.createdAt,
    this.commande,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    return Invoice(
      id: parseInt(json['id']),
      numeroFacture: json['numero_facture'] as String? ?? '',
      commandeId: parseInt(json['commande_id']),
      montantTotal: parseDouble(json['montant_total']),
      montantTaxe: parseDouble(json['montant_taxe']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      commande: json['commande'] != null
          ? Order.fromJson(json['commande'] as Map<String, dynamic>)
          : null,
    );
  }
}
